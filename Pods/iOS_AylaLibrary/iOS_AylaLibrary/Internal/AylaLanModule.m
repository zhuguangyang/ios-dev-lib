//
//  AylaLanModule.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 3/6/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaDeviceSupport.h"
#import "AylaLanModule.h"
#import "AylaSystemUtils.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaApiClient.h"
#import "AylaDevice.h"
#import "AylaTimer.h"
#import "AylaLanCommandEntity.h"
#import "AylaLanModeSupport.h"
#import "AylaSystemUtils.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaNotify.h"
#import "AylaSecurity.h"
#import "AylaSecuritySupport.h"
#import "AylaReachability.h"
#import "AylaReachabilitySupport.h"
#import "AylaCache.h"
#import "AylaCacheSupport.h"
#import "AylaEncryption.h"
#import "AylaErrorSupport.h"
#import "NSObject+AylaNetworks.h"
#import "AylaArrayQueue.h"
#import "AylaLanOperation.h"
#import "AylaConnectionOperationSupport.h"
#import "NSObject+AylaNetworks.h"
#import "AylaDeviceManager.h"
@interface AylaLanModule ()

@property (strong, nonatomic) NSMutableArray *commandsQueue;
@property (strong, nonatomic) NSMutableDictionary *commandsOutstanding;

@property (strong, nonatomic) AylaApiClient *clientInstance;
@property (assign, nonatomic) int sequenceNum;

@end

@implementation AylaLanModule

- (instancetype)initWithDevice:(AylaDevice *)device;
{
    self = [super init];
    if(!self) return nil;
    
    _device = device;
    
    return self;
}

//- (void)setSessionState:(enum lanModeSession)sessionState withCode:(AylaLanModeDeviceErrorCode)code
//{
//    self.lastestErrorCode = code;
//    [self setSessionState:sessionState];
//}
//- (void)setSessionState:(enum lanModeSession)sessionState
//{
//    _sessionState = sessionState;
//    if(sessionState == DOWN ||
//       sessionState == ERROR) {
//        [self lanModeSessionFailed];
//    }
//}

- (NSString *)lanIp
{
    return self.device.lanIp;
}

- (void)setLanIp:(NSString *)lanIp
{
    if(![lanIp isEqualToString:self.device.lanIp]) {
        self.device.lanIp = lanIp;
        [self lanIpChanged];
    }
    else {
        self.device.lanIp = lanIp;
    }
}

- (void)lanIpChanged
{
    [self.session didUpdateLanIp];
    [[AylaDeviceManager sharedManager] updateLanIp:self.lanIp ForDevice:self.dsn];
}

- (void)deliverLanError:(AylaLanModeErrorCode)errorCode httpStatusCode:(NSInteger)httpStatusCode
{
    NSString *notifyType = AML_NOTIFY_TYPE_SESSION;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *notify = [AylaNotify initNotifyDictionaryWithType:notifyType dsn:self.dsn status:httpStatusCode code:errorCode description:nil key:nil values:nil];
        [AylaNotify returnNotify:notify];
    });
}

- (void)deliverLanMessageWithType:(NSString *)type httpStatusCode:(NSInteger)httpStatusCode key:(NSString *)key values:(NSArray *)values
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *notify = [AylaNotify initNotifyDictionaryWithType:type dsn:self.dsn status:httpStatusCode code:0 description:nil key:key values:values];
        [AylaNotify returnNotify:notify];
    });
}

- (BOOL)isLanModeEnabled
{
    return YES;
}

- (NSString *)dsn
{
    return self.device.dsn;
}

#pragma mark -
- (void)lanModeEnable
{
    [self lanModeEnableWithType:AylaLanModeSessionTypeNormal];
}

- (void)lanModeEnableWithType:(AylaLanModeSessionType)sessionType
{
    if(!self.session) {
        self.session = [[AylaLanSession alloc] initWithLanModule:self];
    }
    
    self.session.type = sessionType;
    
    saveToLog(@"%@, %@, %@, %@, %@", @"I", @"AylaLanModule", @"dsn", self.device.dsn, @"lanModeEnable");
    
    [self.session eastablish];
    [self.device didEnableLanMode];
}

- (void)lanModeDisable
{
    [self.session close];
    self.session = nil;
    [self.device didDisableLanMode];
}

#pragma mark -
- (void)startTimer
{
    [self.session startTimer];
}

- (void)stopTimer
{
    [self.session stopTimer];
}

#pragma mark -
- (BOOL)isCurrentLanConfigValid
{
    if(!_lanConfig) {
        [self readLanModeConfigFromCache];
    }

    if(_lanConfig && _lanConfig.lanipKey > 0 && _lanConfig.lanipKeyId > 0) {
        return YES;
    }

    return NO;
}

- (BOOL)readLanModeConfigFromCache
{
    NSMutableArray *singleConfig = [AylaCache get:AML_CACHE_LAN_CONFIG withIdentifier:self.dsn];
    AylaLanModeConfig *config = singleConfig? [singleConfig objectAtIndex:0]: nil;
    self.lanConfig = config;
    return config? YES: NO;
}

- (void)getLanModeConfigWithCompletionBlock:(void (^)(AylaLanModeConfig *config, AylaLanModeErrorCode errorCode, NSError *error))completionBlock cacheOnly:(BOOL)cacheOnly
{
    saveToLog(@"%@, %@, %@, %@", @"I", @"AylaLanModule", @"entry", @"getLanModeConfig");
    
    if(![_lanConfig isValid]) {
        //invalid config found
        _lanConfig = nil;
    }
    else {
        //Use found lanConfig file with a higher priority
        completionBlock(_lanConfig, AylaLanModeErrorCodeNoErr, nil);
        return;
    }
    
    //Secure wifi setup - return if in wifi
    if(cacheOnly) {
        completionBlock(nil, AylaLanModeErrorCodeNoErr, nil);
        return;
    }
    
    if(!self.device.key) {
        saveToLog(@"%@, %@, %@, %@", @"E", @"AylaLanModule", @"no valid device key", @"getLanModeConfig");
        if(completionBlock)
            completionBlock(nil, AylaLanModeErrorCodeLibraryNilDevice, nil);
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"devices/", self.device.key, @"/lan.json"];
    NSMutableURLRequest *request = [[AylaApiClient sharedDeviceServiceInstance] requestWithMethod:@"GET" path:path parameters:nil];
    [request setTimeoutInterval:10];
    
    AylaHTTPOperation *operation = [[AylaApiClient sharedDeviceServiceInstance] operationWithRequest:request success:^(AylaHTTPOperation *operation, id responseObject) {
        NSDictionary *lanInfo = [responseObject valueForKeyPath:@"lanip"];
        
        //Check empty data from server
        if(!lanInfo) {
            //[[AylaLanMode device] setLanModeConfig:nil];
            //[AylaDevice lanModeSessionFailed:AML_REACHABILITY_UNREACHABLE];
            
            saveToLog(@"%@, %@, %@:%@, %@", @"W", @"LanModule", @"config", @"emptyOnCloud", @"getLanModeConfig");
            _lanConfig = nil;
            
            if(completionBlock)
                completionBlock(nil, AylaLanModeErrorCodeLanConfigEmptyOnCloud, nil);
            
            return;
        }
        
        saveToLog(@"%@, %@, %@:%@, %@", @"I", @"LanModule", @"config", @"get", @"getLanModeConfig");
        
        self.lanConfig = [[AylaLanModeConfig alloc] initAylaLanModeConfigWithDictionary:lanInfo];
        //save to cache
        NSMutableArray *arr = [NSMutableArray array];
        [arr addObject:self.lanConfig];
        [AylaCache save:AML_CACHE_LAN_CONFIG withIdentifier:[[AylaLanMode device] dsn] andObject:arr];
        [self.session didUpdateLanModeConfig:self.self.lanConfig];
        
        if(![_lanConfig isEnabled]) {
            saveToLog(@"%@, %@, %@:%@, %@", @"W", @"LanModule", @"config", @"isNotEnabled", @"getLanModeConfig");
            completionBlock(_lanConfig, AylaLanModeErrorCodeLanConfigNotEnabled, nil);
            return;
        }
        if(completionBlock)
            completionBlock(self.lanConfig, AylaLanModeErrorCodeNoErr, nil);
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        saveToLog(@"%@, %@, %@, %@", @"E", @"Devices", error.logDescription, @"getLanModeConfig");
        //Not a valid http error status code,
        if(operation.response.httpStatusCode > 300  &&
           operation.response.httpStatusCode < 499) {
            _lanConfig = nil;
        }
        if(completionBlock)
            completionBlock(self.lanConfig, AylaLanModeErrorCodeCloudInvalidResp, error.nativeErrorInfo);

    }];
    [operation start];
}

@end


#pragma mark - Ayla Lan Session
@interface AylaLanSession () {
    
    BOOL _updateClientInstance;
    
}

@property (strong, nonatomic) AylaArrayQueue *commandsQueue;
@property (strong, nonatomic) AylaArrayQueue *operations;

@property (strong, nonatomic) NSMapTable *commandsOutstanding;

@property (strong, nonatomic) AylaApiClient *clientInstance;
@property (assign, nonatomic) int sequenceNum;

@end


@implementation AylaLanSession

- (instancetype)initWithLanModule:(AylaLanModule *)module
{
    self = [super init];
    if(!self) return nil;
    
    _module = module;
    _operations = [AylaArrayQueue queue];
    _commandsQueue = [AylaArrayQueue queue];
    _commandsOutstanding = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:50];
    
    [self resetSessionTimer];
    
    //One time update for the interval
    [self didUpdateLanModeConfig:module.lanConfig];

    _sessionEncryption = [[AylaEncryption alloc] init];
    _sessionEncryption.lanModule = module;
    
    return self;
}

- (void)lanSessionTimerFired
{
    //a new ka msg needs to be sent
    if(self.module.device == nil){ //stop
        [self stopTimer];
        return;
    }

    void (^extendSessionBlock)() = ^{
        BOOL haveDataToSend = [self.commandsQueue countOfObjects]!=0? true: false;
        [self extendLanModeSession:PUT_LOCAL_REGISTRATION haveDataToSend:haveDataToSend];
        saveToLog(@"%@, %@, %@, %@:%d, %@", @"I", @"AylaLanMode", self.module.dsn, @"more command?", haveDataToSend, @"sessionTimer");
    };
    
    if(self.sessionState == UP) {
        extendSessionBlock();
    }
    else {
        // If session is not UP, refresh module's ip address before sending extension request
        [AylaReachability getDeviceIpAddressWithHostName:self.module.dsn resultBlock:^(NSString *devIp, NSString *devHost) {
            if([devHost isEqualToString:self.module.dsn] && devIp) {
                [self.module setLanIp:devIp];
            }
            extendSessionBlock();
        }];
    }
}


- (void)resetSessionTimer
{
    if(self.sessionTimer) {
        [self.sessionTimer stop];
    }
    
    self.sessionTimer = [[AylaTimer alloc] initWithIntervalAndHandle:AML_DEFAULT_SESSION_INTERVAL tickHandle:^(NSTimer *timer) {
        [self lanSessionTimerFired];
    }];
    
}


#pragma mark - lan session

- (void)eastablish
{
    if(self.sessionState == DOWN ||
       self.sessionState == ERROR) {
        
        //restart lan session
        //initialize LanMode
        if(!self.sessionTimer) {
            [self resetSessionTimer];
        }
        
        if(self.type == AylaLanModeSessionTypeSetup) {
            //update lan ip in beginning
            [self.module setLanIp:AML_SETUP_DEFAULT_NEW_DEVICE_LAN_IP];
        }
        
        NSString *dsn = self.module.dsn;
        [AylaReachability getDeviceIpAddressWithHostName:dsn resultBlock:^(NSString *devIp, NSString *devHost) {
            
            if([devHost isEqualToString:dsn] && devIp) {
                [self.module setLanIp:devIp];
            }
            
            else if([self inSetupMode]) {
                [self.module setLanIp:AML_SETUP_DEFAULT_NEW_DEVICE_LAN_IP];
            }
            
            else {
                saveToLog(@"%@, %@, %@, %@, %@, %@", @"I", @"LanSession", @"discoveryFailed", dsn, devHost , @"establish");
            }
            
            //[AylaReachability setDeviceReachability:AML_REACHABILITY_UNKNOWN];
            saveToLog(@"%@, %@, %@, %@, %@", @"I", @"AylaDevice", @"discoveredLanIp", devIp , @"lanModeEnable");
            
            [self.module getLanModeConfigWithCompletionBlock:^(AylaLanModeConfig *config, AylaLanModeErrorCode errorCode, NSError *error) {
                
                if(errorCode == AylaLanModeErrorCodeNoErr) {
                    
                    if([self inSetupMode] && !config) {
                        [self.sessionTimer setInterval:AML_DEFAULT_SESSION_INTERVAL];
                    }
                    
                    [self startLanModeSession:POST_LOCAL_REGISTRATION haveDataToSend:YES];
                }
                else {
                    [self updateSessionState:ERROR withCode:errorCode httpStatusCode:412 sendNotify:YES];
                    saveToLog(@"%@, %@, %@, %d, %@", @"E", @"LanSession", @"getLanConfig", errorCode , @"eastablish");
                }
            } cacheOnly:[self inSetupMode]? YES: NO];
        }];
    }
    else {
        saveToLog(@"%@, %@, %@, %d, %@", @"I", @"LanSession", @"lanModeStatus", self.sessionState , @"eastablish");
    }
}

- (void)close
{
    //kill current session
    [self.sessionEncryption cleanEncrypSession];
    [self.sessionTimer stop];
    self.sessionTimer = nil;
    [self cleanPendingOperations];
    [self setSessionState:DOWN]; //disable
}

- (BOOL)isTimerOn
{
    return [self.sessionTimer isTicking];
}

- (BOOL)isEnabled
{
    return [self isTimerOn];
}

- (void)extendLanModeSession:(int)method haveDataToSend:(BOOL)haveDataToSend
{
    [self startLanModeSession:method haveDataToSend:haveDataToSend];
}

- (void)startLanModeSession:(int)method haveDataToSend:(BOOL)haveDataToSend
{
    [self stopTimer];
    
    if(![AylaLanMode isEnabled]){
         saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaDevice", @"currentState", @"!RUNNING", @"startLanModeSession");
         [AylaLanMode setSessionState:DOWN];
         dispatch_async(dispatch_get_main_queue(), ^{
             NSDictionary *returnNotify = [AylaNotify initNotifyDictionaryWithType:AML_NOTIFY_TYPE_SESSION dsn:self.module.dsn status:412 description:nil values:nil];
             [AylaNotify returnNotify:returnNotify];
         });
         return;
     }
    
    if(![self isLanModeEnabled]) {

        [self updateSessionState:ERROR withCode:AylaLanModeErrorCodeLanNotEnabled httpStatusCode:412 sendNotify:YES];
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaLanModule", @"isLanModeEnabled", @"NO", @"startLanModeSession");
        return;
    }
    
    //NSString *path = [NSString stringWithFormat:@"local_reg.json"];
    //{"local_reg":{"ip":"192.168.0.2","port":10275,"uri":"local_reg","notify":1}}'
    NSString *ip = [AylaSystemUtils getIPAddress];
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            ip,@"ip",
                            [AylaSystemUtils serverPortNumber],@"port",
                            @"/local_lan",@"uri",
                            [NSNumber numberWithInt:haveDataToSend], @"notify", nil];
    NSDictionary *send = [[NSDictionary alloc] initWithObjectsAndKeys:params, @"local_reg",nil];

    [self sendExtensionMessage:method params:send withTimeout:DEFAULT_LOCAL_WIFI_HTTP_TIMEOUT
    success:^(AylaHTTPOperation *operation, id responseObject) {
        if(operation.response.httpStatusCode == 202){
            saveToLog(@"%@, %@, %@, %@", @"I", @"AylaDevice", @"success", @"local_reg");
            if(![self inSetupMode] && ![self.module.lanConfig isValid]){
                //lan config file is missing
                saveToLog(@"%@, %@, %@:%@, %@", @"W", @"LanSession", @"config", @"isInvalid.TryFetch.", @"local_reg");
                //try to do a quick lan config
                [self.module getLanModeConfigWithCompletionBlock:^(AylaLanModeConfig *config, AylaLanModeErrorCode errorCode, NSError *error) {
                    [self startTimer];
                } cacheOnly:NO];
            }
            else {
                [self startTimer];
            }
        }
        else {
            [self updateSessionState:ERROR withCode:AylaLanModeErrorCodeDeviceNotSupport httpStatusCode:operation.response.httpStatusCode sendNotify:YES];
            [self startTimer];
            saveToLog(@"%@, %@, %@:%d, %@:%ld, %@", @"W", @"->AylaDevice", @"errCode", 0, @"httpCode", (long)operation.response.httpStatusCode,  @"local_reg");
        }
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        // check delay issues
        self.lastestErrorCode = AylaLanModeErrorCodeMobileSessionMsgTimeOut;
        switch (operation.response.httpStatusCode) {
            case 400: //400: Forbidden - Bad Request (JSON parse failed)
                //[AylaReachability setDeviceReachability:AML_REACHABILITY_REACHABLE];
                [self setSessionState:ERROR];
                break;
            case 403: //403: Forbidden - lan_ip on a different network
                //[AylaReachability setDeviceReachability:AML_REACHABILITY_UNREACHABLE];
                [self updateSessionState:ERROR withCode:AylaLanModeErrorCodeDeviceDifferentLan httpStatusCode:operation.response.httpStatusCode sendNotify:YES];
                break;
            case 404: //404: Not Found - Lan Mode is not supported by this module
                //[AylaReachability setDeviceReachability:AML_REACHABILITY_UNREACHABLE];
                [self updateSessionState:ERROR withCode:AylaLanModeErrorCodeDeviceNotSupport httpStatusCode:operation.response.httpStatusCode sendNotify:YES];
                break;
            case 412:
                if([self inSetupMode]) {
                    //WiFi setup jump out
                    [AylaSecurity startKeyExchange:self returnBlock:NULL];
                }
                else {
                    //[AylaReachability setDeviceReachability:AML_REACHABILITY_UNREACHABLE];
                    [self updateSessionState:ERROR withCode:AylaLanModeErrorCodeDeviceResponseError httpStatusCode:operation.response.httpStatusCode sendNotify:YES];
                }
                break;
            case 503: //503: Service Unavailable - Insufficient resources or maximum number of sessions exceeded
                //[AylaReachability setDeviceReachability:AML_REACHABILITY_UNREACHABLE];
                [self updateSessionState:ERROR withCode:AylaLanModeErrorCodeDeviceResponseError httpStatusCode:operation.response.httpStatusCode sendNotify:YES];
                break;
            default:
            {
                //[AylaReachability setDeviceReachability:AML_REACHABILITY_UNREACHABLE];
                NSInteger statusCode = (operation.response.httpStatusCode ==0)? 404: operation.response.httpStatusCode;
                [self updateSessionState:DOWN withCode:AylaLanModeErrorCodeMobileSessionMsgTimeOut httpStatusCode:statusCode sendNotify:YES];
                break;
            }
        }
        
        if (error.nativeErrorInfo.code ==  NSURLErrorNotConnectedToInternet) {
            //[AylaReachability setConnectivity:AML_REACHABILITY_UNREACHABLE];
        }
        
        [self startTimer];
        //new properties update is required
        //[AylaReachability setIsDeviceReachabilityExpired:true];
        saveToLog(@"%@, %@, %@:%d, %@:%ld, %@", @"W", @"->AylaDevice", @"errCode", 0, @"httpCode", (long)operation.response.httpStatusCode,  @"local_reg");
    }];
}

- (void)stopLanModeSession
{
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"AylaLanModule", @"device", self.module.dsn, @"deleteLanModeSession");

    int cmdId = [self nextCommandOutstandingId];
    NSString *source = @"local_reg.json";
    NSString *cmd = [AylaLanMode buildToDeviceCommand:@"DELETE" cmdId:cmdId resourse:source data:nil uri:@"/local_lan"];

    AylaLanCommandEntity *command =
    [[AylaLanCommandEntity alloc] initWithParams:cmdId jsonString:cmd type:AYLA_LAN_COMMAND];
    
    AylaLanOperation *operation = [[AylaLanOperation alloc] initWithCallback:nil timeoutInterval:0];
    [operation setCommands:@[command]];
    [operation setTimeoutInterval:[operation suggestedTimeoutInterval]];
    [self pushOperation:operation];
}

- (NSOperation *)sendExtensionMessage:(int)method params:(NSDictionary *)msgParams withTimeout:(int)timeout
                     success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                     failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock
{
    NSMutableURLRequest *request;
    NSString * const path = [NSString stringWithFormat:@"local_reg.json"];
    
    NSString *methodStr = method == POST_LOCAL_REGISTRATION? @"POST": @"PUT";
    request = [[self connectedDeviceInstance] requestWithMethod:methodStr path:path parameters:msgParams];
    
    [request setTimeoutInterval: timeout>1? timeout: DEFAULT_LOCAL_WIFI_HTTP_TIMEOUT];
    AylaHTTPOperation *operation = [[self connectedDeviceInstance] operationWithRequest:request success:^(AylaHTTPOperation *operation, id responseObject) {
        successBlock(operation, responseObject);
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        failureBlock(operation, error);
    }];

    [operation start];
    return operation;
}

- (BOOL)isLanModeEnabled
{
    return YES;
}

#pragma mark - lan mode config
static uint32_t const lan_keep_alive_adjustment = 4;
- (void)didUpdateLanModeConfig:(AylaLanModeConfig *)config
{
    if(config) {
    
        int ka = [config.keepAlive intValue] - lan_keep_alive_adjustment;
        if(ka <= AML_LAN_MODE_TIMEOUT_SAFETY){
            ka += lan_keep_alive_adjustment + AML_LAN_MODE_TIMEOUT_SAFETY;
        }
        [self.sessionTimer setInterval:ka];
    }
}

- (void)didUpdateLanIp
{
    _updateClientInstance = YES;
}

#pragma mark - session operations
- (void)pushOperation:(AylaLanOperation *)operation
{
    NSArray *operationCommands = [operation commands];
    
    AylaArrayQueue *queue = _operations;
    [queue enQueue:operation];
    
    //add all commands to commands queue
    if(operationCommands) {
        
        AylaArrayQueue *commands = _commandsQueue;
        NSInteger commandsInQueue = [commands countOfObjects];
        
        for(AylaLanCommandEntity *command in operationCommands) {
            [self putOutstandingCommand:command];
        }
        
        [commands enQueueFromArray:operation.commands];
        
        if(commandsInQueue == 0) {
            [self extendLanModeSession:PUT_LOCAL_REGISTRATION haveDataToSend:YES];
        }
        [operation addStatusObserver:self];
    }
    
    [operation start];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[AylaLanOperation class]]) {
        AylaLanOperation *operation = (AylaLanOperation *)object;
        if(operation.isFinished) {
            [self.operations removeObject:operation];
            [operation removeStatusObserver:self];
        }
    }
}

#pragma mark -
// Local module connection
- (id)connectedDeviceInstance
{
    if(_updateClientInstance || !self.clientInstance) {
        
        self.clientInstance = nil;
        NSString *basePath = [NSString stringWithFormat:@"%@%@%@", @"http://", self.module.lanIp, @"/"];
        saveToLog(@"%@, %@, %@:%@, %@", @"I", @"LanModuleApiClient", @"basePath", basePath, @"sharedConnectedDeviceInstance");
        self.clientInstance = [[AylaApiClient alloc] initWithBaseURL:[NSURL URLWithString:basePath]];
        _updateClientInstance = NO;
    }
    return self.clientInstance;
}

#pragma mark - session state

- (void)setSessionState:(enum lanModeSession)sessionState
{
    _sessionState = sessionState;
}

- (void)updateSessionState:(enum lanModeSession)sessionState withCode:(AylaLanModeErrorCode)code httpStatusCode:(NSUInteger)httpStatusCode sendNotify:(BOOL)sendNotify
{
    self.lastestErrorCode = code;
    [self setSessionState:sessionState];
    
    if(sendNotify) {
        if(sessionState == ERROR ||
           sessionState == DOWN)
            [self.module deliverLanError:code httpStatusCode:httpStatusCode];
        else
            [self.module deliverLanMessageWithType:AML_NOTIFY_TYPE_SESSION httpStatusCode:httpStatusCode key:nil values:nil];
    }
}

#pragma mark -
- (void)startTimer
{
    [self.sessionTimer start];
}

- (void)stopTimer
{
    [self.sessionTimer stop];
}

#pragma mark -
- (BOOL)inSetupMode
{
    return self.type == AylaLanModeSessionTypeSetup;
}

#pragma mark -
// Commands queue handlers
- (void)enQueue:(int)cmdId baseType:(int)baseType jsonString:(NSString *)jsonString
{
    AylaLanCommandEntity *command = [[AylaLanCommandEntity alloc] initWithParams:cmdId jsonString:jsonString type:baseType];
    [self enQueue:command];
}

- (void)enQueue:(AylaLanCommandEntity *)command
{
    [self.commandsQueue enQueue:command];
}

- (AylaLanCommandEntity *)nextInQueue
{
    return [self.commandsQueue nextInQueue];
}

- (AylaLanCommandEntity *)deQueue
{
    return [self.commandsQueue deQueue];
}

- (AylaLanCommandEntity *)deQueueTillNextValidCommand
{
    AylaLanCommandEntity * command;
    do {
        command = [self deQueue];
    } while (command && [command isCancelled]);
    return command;
}

- (void)clearQueue
{
    [self.commandsQueue cleanAll];
}

- (int)commandsQueueCount
{
    return (int)[self.commandsQueue countOfObjects];
}

#pragma mark -

- (int)nextCommandOutstandingId
{
    return [self nextSequenceNum];
}

const static int MAX_U16 = 65535;
- (int)nextSequenceNum
{
    if(++_sequenceNum > MAX_U16){
        _sequenceNum = 0;
    }
    return _sequenceNum;
}

- (void)resetSequenceNum
{
    _sequenceNum = 0;
}

- (AylaLanCommandEntity *)getOutstandingCommand:(NSString *)cmdId
{
    return [[self.commandsOutstanding objectForKey:cmdId] nilIfNull];
}

- (void)putOutstandingCommand:(AylaLanCommandEntity *)command
{
    [_commandsOutstanding setObject:command forKey:[@(command.cmdId) stringValue]];
}

- (void)removeOutstandingCommand:(NSString *)cmdId
{
    [_commandsOutstanding removeObjectForKey:cmdId];
}

- (void)cleanPendingOperations
{
    NSArray *operations = [_operations allObjects];
    [_operations cleanAll];
    [_commandsQueue cleanAll];
    for(AylaLanOperation *operation in operations) {
        [operation removeStatusObserver:self];
        [operation cancel];
    }
}

#pragma mark -
- (void)dealloc
{
    [self cleanPendingOperations];
}

@end
