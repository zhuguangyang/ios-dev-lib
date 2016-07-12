//
//  AylaLanMode.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/8/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaLanMode.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaHttpServer.h"
#import "AylaLanCommandEntity.h"
#import "AylaNotify.h"
#import "AylaTimer.h"
#import "AylaEncryption.h"
#import "AylaReachabilitySupport.h"
#import "AylaDeviceSupport.h"
#import "AylaDiscovery.h"
#import "AylaLanModule.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceNode.h"
#import "AylaCache.h"
#import "AylaCacheSupport.h"
#import "AylaDeviceManager.h"
@implementation AylaLanMode

//static NSString *serverIpAddress = nil;
//static File serverRootDir = nil;
static AylaHttpServer *httpServer = nil;

static AylaDevice *device = nil; 	// currently selected lan mode device
static NSMutableDictionary *devices = nil; // lan mode devices registered to this user

static enum lanModeSession sessionState = DOWN;

static BOOL __unused inSetupMode = NO;

+ (NSArray *)bufferedDeviceList
{
    return [[AylaDeviceManager sharedManager] bufferedDeviceList];
}

+ (NSArray *)activeDeviceList
{
    return
    [AylaLanMode filterDevicesWithBlock:^BOOL(AylaDevice *device) {
        return [device isLanModeActive];
    }];
}

+ (NSArray *)enabledDeviceList
{
    return
    [AylaLanMode filterDevicesWithBlock:^BOOL(AylaDevice *device) {
        return [device.lanModule.session isEnabled];
    }];
}

+ (NSArray *)filterDevicesWithBlock:(BOOL (^)(AylaDevice *device))filterBlock
{
    NSMutableArray *filteredDevices = [NSMutableArray new];
    NSArray *devices = [[AylaDeviceManager sharedManager] devices].allValues;
    for(AylaDevice *device in devices) {
        if(filterBlock && filterBlock(device)) {
            [filteredDevices addObject:device];
        }
    }
    return filteredDevices;
}

+ (AylaDevice *)device
{
    return device;
}
+ (void)setDevice:(AylaDevice *)_device
{
    _device? [_device didEnableLanMode]: [device didDisableLanMode];
    device = _device;
}
+ (int)sessionState{
    return (int)sessionState;
}
+ (void)setSessionState:(enum lanModeSession)_sessionState
{
    sessionState = _sessionState;
}

const static int MAX_U16 = 65535;
+ (int)nextSequenceNumber:(int)cur
{
    if(++cur > MAX_U16){
        cur = 0;
    }
    return cur;
}

// --------------------------------------- begin LAN MODE enablement & disablement ------------------------
+ (int)enableWithNotifyHandle:
    /* notifyHandle*/ (void(^)(NSDictionary*)) notifyHandle
    ReachabilityHandle: (void(^)(NSDictionary*)) reachabilityHandle
{
    [super lanModeState:ENABLED];
    
    saveToLog(@"%@, %@, %@:%d, %@", @"I", @"AylaLanMode", @"currentState", [self lanModeState], @"enable");
 
    [AylaNotify register:notifyHandle];
    //--------------
    [AylaReachability register:reachabilityHandle];
    return [self resumeWithParams:nil];
}

+ (int)enable
{
    [super lanModeState:ENABLED];    
    saveToLog(@"%@, %@, %@:%d, %@", @"I", @"AylaLanMode", @"currentState", [self lanModeState], @"enable");
    
    return [self resumeWithParams:nil];
}


+ (int)resume
{
    NSLog(@"Warning: %@.%@ - Deprecated api.", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return AML_ERROR_OK;
}

+ (int)resumeWithParams:(NSDictionary *)params
{
    //Refresh user access token if necessary
    [AylaUser refreshAccessTokenOnExpiry];
    
    if([super lanModeState] == DISABLED){
         saveToLog(@"%@, %@, %@:%d, %@", @"E", @"AylaLanMode", @"currentState", [super lanModeState], @"resume");
        return AML_ERROR_FAIL;
    }
    
    //start HTTP_SERVER
    //[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	// Create server using AylaHTTPServer class
    if(httpServer == nil)
        httpServer = [[AylaHttpServer alloc] initWithPort:[[self serverPortNumber] unsignedIntValue]];
    
	// Serve files from embedded Web folder
	NSString *webPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"local_lan"];
	[httpServer setDocumentRoot:webPath];	
	// Start the server (and check for problems)
	NSError *error;
	
    if([httpServer isRunning]) {
        [self lanModeState:RUNNING];
    }
    else {
        httpServer.port = [[self serverPortNumber] unsignedIntValue];
        if([httpServer start:&error]){
            saveToLog(@"%@, %@, Started HTTPServer, port %hu", @"I", @"AylaLanMode", [httpServer listeningPort]);
            [self lanModeState:RUNNING];
        }
        else {
            // Most errors come from port conflicts
            // Let server assign next available port number and make one more attempt
            httpServer.port = 0;
            if([httpServer start:&error]) {
                saveToLog(@"%@, %@, Started HTTPServer, port %hu", @"I", @"AylaLanMode", [httpServer listeningPort]);
                [self serverPortNumber:[httpServer listeningPort]];
                [self lanModeState:RUNNING];
            }
            else {
                saveToLog(@"%@, %@, Error starting HTTP Server: %@", @"E", @"AylaLanMode", error.localizedDescription);
                [self lanModeState:FAILED];
                return AML_ERROR_FAIL;
            }
        }
    }
    
    if([self lanModeState] == RUNNING){
        [AylaReachability determineReachability];
        saveToLog(@"%@, %@, %@:%d, %@", @"I", @"AylaLanMode", @"currentState", [self lanModeState], @"resume");
    }
    else{
        return AML_ERROR_FAIL;
    }
    return AML_ERROR_OK;
}


+ (int)disable
{
    if([AylaSystemUtils lanModeState] == RUNNING){
        [AylaLanMode pauseWithParams:nil];
        [AylaLanMode setDevice:nil];
    }
    [AylaSystemUtils lanModeState:DISABLED];
    saveToLog(@"%@, %@, %@:%d, %@", @"I", @"AylaLanMode", @"currentState", [AylaSystemUtils lanModeState], @"disable");
    return AML_ERROR_OK;
}

+ (int)pause
{
    NSLog(@"Warning: %@.%@ - Deprecated api.", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return AML_ERROR_OK;
}

+ (int)pauseWithParams:(NSDictionary *)params
{    
    if([AylaSystemUtils lanModeState] == DISABLED)
        return AML_ERROR_OK;
    
    if(httpServer!=nil){
        [httpServer stop];
        httpServer = nil;
    }
    [AylaDiscovery cancelDiscovery];
    [AylaSystemUtils lanModeState:STOPPED];
    
    NSArray *devices = [[[AylaDeviceManager sharedManager] devices] allValues];
    for(AylaDevice *lanDevice in devices) {
        [lanDevice lanModeDisable];
    }

    saveToLog(@"%@, %@, %@:%d, %@", @"I", @"AylaLanMode", @"currentState", [AylaSystemUtils lanModeState], @"pause");
    return AML_ERROR_OK;
}

+ (BOOL) isEnabled
{
    return [AylaLanMode lanModeState] != DISABLED;
}

+ (void)notifyAcknowledge
{
    saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaLanMode", @"DEPRECATED", @"Use -notifyAcknowledge on each device level.", @"notifyAcknowledge");
}

//-------------- register new handler

+ (void)registerReachabilityHandle:(void(^)(NSDictionary *))handle
{
    [AylaReachability register:handle];
}
+ (void)registerNotifyHandle:(void(^)(NSDictionary *))handle
{
    [AylaNotify register:handle];
}

//helpful method
+ (NSString *)buildToDeviceCommand:
    (NSString *)method cmdId:(int)cmdId
    resourse:(NSString *)resource data:(id)data
    uri:(NSString *) uri
{
    NSError *error;
    NSDictionary *messageObj = @{
                                 @"cmd": @{
                                    @"cmd_id": @(cmdId),
                                    @"method": method?:[NSNull null],
                                    @"resource": resource?:[NSNull null],
                                    @"data": data?:[NSNull null],
                                    @"uri": uri?:[NSNull null]
                                 }
                                };
    NSData *msgInData = [NSJSONSerialization dataWithJSONObject:messageObj options:0 error:&error];
    NSString *dataInString =[[NSString alloc] initWithData:msgInData encoding:NSUTF8StringEncoding];
    if (error) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaGateway", @"dsns", error.localizedDescription, @"getNodesConnectionStatus");
        return nil;
    }
    return dataInString;
}

+ (AylaDevice *) deviceWithDsn:(NSString *)dsn
{
    return [[AylaDeviceManager sharedManager] deviceWithDsn:dsn];
}

+ (AylaDevice *) deviceWithDsn:(NSString *)dsn recursiveCheck:(BOOL)recursiveCheck
{
    return [[AylaDeviceManager sharedManager] deviceWithDsn:dsn recursiveCheck:recursiveCheck];
}

+ (AylaDevice *) deviceWithLanIp:(NSString *)lanIp
{
    return [[AylaDeviceManager sharedManager] deviceWithLanIp:lanIp];
}

+ (void) closeAllSessions
{
    NSArray *devices = [[[AylaDeviceManager sharedManager] devices] allValues];
    for(AylaDevice *device in devices) {
        if([device.lanModule.session isTimerOn]) {
            [device.lanModule lanModeDisable];
        }
    }
}

+ (void) resetFromCache
{
    [[AylaDeviceManager sharedManager] resetFromCache:YES];
}

@end
