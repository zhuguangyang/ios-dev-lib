//
//  AylaModule.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/23/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaLogService.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaSetupSupport.h"
#import "AylaDeviceSupport.h"
#import "AylaHost.h"
#import "AylaReachabilitySupport.h"
#import "AylaLanModeSupport.h"
#import "AylaSecuritySupport.h"
#import "AylaErrorSupport.h"
#import "AylaCacheSupport.h"
#import "AylaLanOperation.h"
#import "AylaConnectionOperationSupport.h"
#import "AylaDefines_Internal.h"
#import "TMReachability_Ayla.h"

@implementation AylaModule

@synthesize deviceService = _deviceService;
@synthesize lastConnectMtime = _lastConnectMtime;
@synthesize mtime = _mtime;
@synthesize version = _version;
@synthesize apiVersion = _apiVersion;
@synthesize build = _build;

static NSDictionary *results = nil;
static int responseCode = 0;
static int subTaskFailed = 0;

+ (int)responseCode
{
    return responseCode;
}

+ (NSDictionary *)results
{
    return results;
}

+ (int)subTaskFailed
{
    return subTaskFailed;
}

- (id)initModuleWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self){
        self.dsn = [dictionary valueForKeyPath:@"dsn"];
        self.mac = [dictionary valueForKeyPath:@"mac"];
        self.model = [dictionary valueForKeyPath:@"model"];
        _deviceService = [dictionary valueForKeyPath:@"device_service"];
        _lastConnectMtime = [dictionary valueForKeyPath:@"last_connect_mtime"];
        _mtime = [dictionary valueForKeyPath:@"mtime"];
        _version = [dictionary valueForKeyPath:@"version"];
        _apiVersion = [dictionary valueForKeyPath:@"api_version"];
        _build = [dictionary valueForKeyPath:@"build"];
        self.features = [dictionary valueForKeyPath:@"features"] == [NSNull null]? nil: [dictionary valueForKeyPath:@"features"];
    }
    return self;
}

- (void)startListeningDisconnection
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:kReachabilityChangedNotification_Ayla object:nil];
}

- (BOOL)hasConnected
{
    if(_hasConnected
       && [[AylaSystemUtils getIPAddress] isEqualToString:self.connectorLanIp]) {
        return YES;
    }
    return NO;
}

- (void)networkChanged:(NSNotification *)notification
{
    AylaLogI(AYLA_THIS_CLASS, 0, @"disconnected from %@", self.dsn);
    self.hasConnected = NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setNewDeviceTime:(NSNumber*) newTime
                 success:(void (^)(AylaResponse *response))successBlock
                 failure:(void (^)(AylaError *err))failureBlock
{
    NSDictionary *time =[NSDictionary dictionaryWithObjectsAndKeys:
                         newTime, @"time", nil];
    
    NSMutableURLRequest *request = [[AylaApiClient sharedNewDeviceInstance] requestWithMethod:@"PUT" path:@"time.json" parameters:time];
    [request setTimeoutInterval:DEFAULT_SETUP_WIFI_HTTP_TIMEOUT];
    AylaHTTPOperation *operation = [[AylaApiClient sharedNewDeviceInstance] operationWithRequest:request success:^(AylaHTTPOperation *operation, id responseObject) {
        saveToLog(@"%@, %@, %@:%ld, %@", @"I", AYLA_THIS_CLASS, @"Success", (long)operation.response.httpStatusCode, @"setNewDeviceTime");
        AylaResponse *resp = [AylaResponse new]; resp.httpStatusCode = operation.response.httpStatusCode;
        successBlock(resp);
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        saveToLog(@"%@, %@, %@:%ld, %@", @"E", AYLA_THIS_CLASS, @"Failed", (long)operation.response.httpStatusCode, @"setNewDeviceTime");
        error.errorCode = 1;
        subTaskFailed = AML_SET_NEW_DEVICE_TIME;
        NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
        NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", nil];
        error.errorInfo = description;
        failureBlock(error);
    }];
    [operation start];
}

- (void)getNewDeviceDetail:
                /*success:*/(void (^)(AylaResponse *response, AylaModule *device))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableURLRequest *request = [[AylaApiClient sharedNewDeviceInstance] requestWithMethod:@"GET" path:@"status.json" parameters:nil];
    [request setTimeoutInterval:DEFAULT_SETUP_WIFI_HTTP_TIMEOUT];
    AylaHTTPOperation *operation = [[AylaApiClient sharedNewDeviceInstance]
                                         operationWithRequest:request success:^(AylaHTTPOperation *operation, id responseObject) {
                                             saveToLog(@"%@, %@, %@:%ld, %@", @"I", AYLA_THIS_CLASS, @"Success", (long)operation.response.httpStatusCode, @"getNewDeviceDetail.getPath");
                                             AylaModule *newDevice = [[AylaModule alloc] initModuleWithDictionary:responseObject];
                                             
                                             successBlock(operation.response, newDevice);
                                         } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                             subTaskFailed = AML_GET_NEW_DEVICE_DETAIL;
                                             NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
                                             NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", nil];
                                             error.errorInfo = description;
                                             AylaLogE(AYLA_THIS_CLASS, 0, @"%@, %@", error.logDescription, AYLA_THIS_METHOD);
                                             
                                             failureBlock(error);
                                         }];
    [operation start];
}

+ (void)getNewDeviceScanForAPs:
            /*success:*/(void (^)(AylaResponse *response, NSMutableArray *apList)) successBlock
            failure:(void (^)(AylaError *err)) failureBlock
{
    if( [AylaSetup lastMethodCompleted] != AML_SETUP_TASK_CONNECT_TO_NEW_DEVICE &&
       [AylaSetup lastMethodCompleted] != AML_SETUP_TASK_GET_DEVICE_SCAN_FOR_APS)
    {
        saveToLog(@"%@, %@, %@:%@,%@:%d, %@", @"E", AYLA_THIS_CLASS, @"Failed", @"TaskOutOfOrder", @"lastMethodCompleted", [AylaSetup lastMethodCompleted],  @"getNewDeviceScanForAPs");
        NSNumber *methodCompleted = [[NSNumber alloc] initWithInt:[AylaSetup lastMethodCompleted]];
        NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys: methodCompleted ,@"taskOutOfOrder", nil];
        AylaError *err = [AylaError new]; err.errorCode = AML_TASK_ORDER_ERROR; err.httpStatusCode = 0;
        err.errorInfo = description; err.nativeErrorInfo = nil;
        failureBlock(err);
        return;
    }
    
    if([AylaSetup hostNewDeviceSsid] == nil){
        AylaError *err = [AylaError new];
        err.errorCode = AML_NO_DEVICE_CONNECTED;
        err.httpStatusCode = 0;
        NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:@"Invalid new device SSID.", @"error", nil];
        err.errorInfo = description;
        err.nativeErrorInfo = nil;
        failureBlock(err);
        return;
    }
    
    [self setNewDeviceScanForAPs:
     /*success*/^(AylaResponse *response){
         saveToLog(@"%@, %@, %@, %@", @"I", @"AylaModule", @"Success", @"setNewDeviceScanForAPs.postPath");
         
         AYLA_RUN_ASYNC_ON_QUEUE_BEGIN([AylaSetup setupQueue], 2.)
         NSMutableURLRequest *request = [[AylaApiClient sharedNewDeviceInstance] requestWithMethod:@"GET" path:@"wifi_scan_results.json" parameters:nil];
         [request setTimeoutInterval:DEFAULT_SETUP_WIFI_HTTP_TIMEOUT];
         AylaHTTPOperation *operation = [[AylaApiClient sharedNewDeviceInstance]
                                         operationWithRequest:request success:^(AylaHTTPOperation *operation, id responseObject) {
                                             saveToLog(@"%@, %@, %@:%ld, %@", @"I", AYLA_THIS_CLASS, @"Success",(long)operation.response.httpStatusCode, @"getNewDeviceScanForAPs.getPath");
                                             NSDictionary * dict = [responseObject objectForKey:@"wifi_scan"];
                                             NSArray *result = [dict objectForKey:@"results"];
                                             NSMutableArray * apList = [NSMutableArray array];
                                             for(NSDictionary *candidate in result){
                                                 AylaModuleScanResults *ap = [[AylaModuleScanResults alloc] initModuleScanResultWithDictionary:candidate];
                                                 [apList addObject:ap];
                                             }
                                             [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_GET_DEVICE_SCAN_FOR_APS];

                                             successBlock(operation.response, apList);
                                         } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                             saveToLog(@"%@, %@, %@:%ld, %@", @"E", AYLA_THIS_CLASS, @"Failed",(long)operation.response.httpStatusCode,  @"getNewDeviceScanForAPs.getPath");
                                             error.errorCode = 1;
                                             subTaskFailed = AML_GET_NEW_DEVICE_SCAN_FOR_APS;
                                             NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
                                             NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", nil];
                                             error.errorInfo = description;
                                             failureBlock(error);
                                         }];
         [operation start];
         AYLA_RUN_ASYNC_ON_QUEUE_END
     } failure:^(AylaError *err) {
         failureBlock(err);
     }];
    
}

+ (void)setNewDeviceScanForAPs:
            /*success:*/(void (^)(AylaResponse *response)) successBlock
            failure:(void (^)(AylaError *err)) failureBlock
{
    NSMutableURLRequest *request = [[AylaApiClient sharedNewDeviceInstance] requestWithMethod:@"POST" path:@"wifi_scan.json" parameters:nil];
    [request setTimeoutInterval:DEFAULT_SETUP_WIFI_HTTP_TIMEOUT];
    AylaHTTPOperation *operation = [[AylaApiClient sharedNewDeviceInstance]
                                         operationWithRequest:request success:^(AylaHTTPOperation *operation, id responseObject) {
                                             saveToLog(@"%@, %@, %@:%ld, %@", @"I", AYLA_THIS_CLASS, @"Success",(long)operation.response.httpStatusCode, @"setNewDeviceScanForAPs.postPath");
                                             successBlock(operation.response);
                                         } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                             saveToLog(@"%@, %@, %@:%ld, %@:%ld, %@", @"E", AYLA_THIS_CLASS, @"Failed",(long)operation.response.httpStatusCode, @"code", (long)error.nativeErrorInfo.code, @"setNewDeviceScanForAPs.postPath");
                                             error.errorCode = 1;
                                             subTaskFailed = AML_SET_NEW_DEVICE_SCAN_FOR_APS;
                                             NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
                                             NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", nil];
                                             error.errorInfo = description;
                                             failureBlock(error);
                                         }];
    [operation start];
}



+ (void)disconnectNewDevice:(NSDictionary *)params
                    success:(void (^)(AylaResponse *response))successBlock
                    failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableURLRequest *request = [[AylaApiClient sharedNewDeviceInstance] requestWithMethod:@"PUT" path:@"wifi_stop_ap.json" parameters:nil];
    [request setTimeoutInterval:DEFAULT_SETUP_WIFI_HTTP_TIMEOUT];
    AylaHTTPOperation *operation = [[AylaApiClient sharedNewDeviceInstance]
                                    operationWithRequest:request success:^(AylaHTTPOperation *operation, id responseObject) {
                                        saveToLog(@"%@, %@, %@:%ld, %@", @"I", @"DeviceModule", @"Success",(long)operation.response.httpStatusCode, @"disconnectNewDevice");

                                        successBlock(operation.response);
                                    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                        saveToLog(@"%@, %@, %@:%ld, %@", @"W", AYLA_THIS_CLASS, @"Failed",(long)operation.response.httpStatusCode, @"disconnectNewDevice");
                                        failureBlock(error);
                                    }];
    [operation start];
}


+ (void)connectNewDevcieToServiceContinued:(NSDictionary *)callParams
                                   success:(void (^)(AylaResponse *response))successBlock
                                   failure:(void (^)(AylaError *err))failureBlock
{
    int pollInterval = DEFAULT_SETUP_STATUS_POLLING_INTERVAL;
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"DeviceSetup", @"Success", @"", @"connectNewDeviceToService");
    __block int errorTries = 2;
    void (^__block __weak __failureBlock)(AylaError *);
    void (^__block __weak __successBlock)(AylaResponse *response, AylaWiFiStatus *);
    void (^__block _failureBlock)(AylaError *);
    void (^__block _successBlock)(AylaResponse *response, AylaWiFiStatus *);
    __successBlock = _successBlock = ^(AylaResponse *response, AylaWiFiStatus *wifiStatus) {
        
        AYLA_RUN_ASYNC_ON_QUEUE_BEGIN([AylaSetup setupQueue], pollInterval)
        [AylaSetup getNewDeviceWiFiStatus:^(AylaResponse *response, AylaWiFiStatus *wifiStatus) {
           errorTries = 2;
           NSArray *connectionHistory = wifiStatus.connectHistory;
           if ([connectionHistory count]>0) {
               AylaWiFiConnectHistory *latestHistory = [connectionHistory objectAtIndex:0];
               if ([latestHistory.error intValue] == 0) { // no error
                   [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE];
                   saveToLog(@"%@, %@, %@:%@, %@", @"I", @"DeviceSetup", @"Success", @"0", @"connectNewDeviceToService.getNewDeviceWiFiStatus");
                   successBlock(response);
               }
               else if ([latestHistory.error intValue] == 6 ||
                        [latestHistory.error intValue] == 3) { // incorrect key
                   saveToLog(@"%@, %@, %@:%@, %@", @"E", @"DeviceSetup", @"Failed", @"Incorrect Key", @"connectNewDeviceToService.getNewDeviceWiFiStatus");
                   AylaError *err = [AylaError new]; err.errorCode = AML_SETUP_DEVICE_ERROR; err.httpStatusCode = 400; err.nativeErrorInfo = nil;
                   subTaskFailed = AML_GET_NEW_DEVICE_WIFI_STATUS;
                   NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
                   NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", latestHistory.error, @"error", latestHistory.msg, @"msg", nil];
                   err.errorInfo = description;
                   failureBlock(err);
               }
               else if ([latestHistory.error intValue] == 20) {
                   saveToLog(@"%@, %@, %@:%ld, %@:%@, %@", @"I", @"DeviceSetup", @"StillInProgress",  (long)[latestHistory.error integerValue], @"oneMoreTires", @"null" , @"connectNewDeviceToService.getNewDeviceWiFiStatus");
                   
                   void (^strongSuccessBlock)(AylaResponse *response, AylaWiFiStatus *) = __successBlock;
                   AYLA_RUN_ASYNC_ON_QUEUE_BEGIN([AylaSetup setupQueue], pollInterval)
                   [AylaSetup getNewDeviceWiFiStatus: strongSuccessBlock
                                             failure: _failureBlock];
                   AYLA_RUN_ASYNC_ON_QUEUE_END
               }
               else {
                   saveToLog(@"%@, %@, %@:%ld, %@:%@, %@", @"E", @"DeviceSetup", @"errCode", (long)[latestHistory.error integerValue], @"msg", latestHistory.msg, @"connectNewDeviceToService.getNewDeviceWiFiStatus");
                   AylaError *err = [AylaError new]; err.errorCode = AML_SETUP_DEVICE_ERROR; err.httpStatusCode = 400; err.nativeErrorInfo = nil;
                   subTaskFailed = AML_GET_NEW_DEVICE_WIFI_STATUS;
                   NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
                   NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", latestHistory.error, @"error", latestHistory.msg, @"msg", nil];
                   err.errorInfo = description;
                   failureBlock(err);
               }
           } else {
               saveToLog(@"%@, %@, %@:%@, %@", @"E", @"DeviceSetup", @"Failed", @"No WiFi history received from module.", @"connectNewDeviceToService.getNewDeviceWiFiStatus");
               AylaError *err = [AylaError new]; err.errorCode = AML_SETUP_DEVICE_ERROR; err.httpStatusCode = 404; err.nativeErrorInfo = nil;
               subTaskFailed = AML_GET_NEW_DEVICE_WIFI_STATUS;
               NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
               NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", nil];
               err.errorInfo = description;
               failureBlock(err);
           }
        } failure:^(AylaError *err) {
           if (errorTries-- > 0){
               if ([AylaHost isNewDeviceConnected]) {
                   void (^strongSuccessBlock)(AylaResponse *response, AylaWiFiStatus *) = __successBlock;
                   AYLA_RUN_ASYNC_ON_QUEUE_BEGIN([AylaSetup setupQueue], DEFAULT_SETUP_STATUS_POLLING_INTERVAL)
                   saveToLog(@"%@, %@, %@:%ld, %@:%d, %@", @"I", @"DeviceSetup", @"FailureBlockOneMoreTry", (long)err.errorCode, @"errorTries", errorTries, @"connectNewDeviceToService.getNewDeviceWiFiStatus");
                   [AylaSetup getNewDeviceWiFiStatus: strongSuccessBlock
                                             failure: _failureBlock];
                   AYLA_RUN_ASYNC_ON_QUEUE_END
               }
               else {
                   saveToLog(@"%@, %@, %@:%ld, %@", @"E", @"DeviceSetup", @"Failed", (long)err.errorCode, @"connectNewDeviceToService.getNewDeviceWiFiStatus");
                   //now set last method completed to AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE to guarrantee confirm connection method could be called after this failure
                   [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE];
                   failureBlock(err);
               }
           }
           else {
               saveToLog(@"%@, %@, %@:%ld, %@", @"E", @"DeviceSetup", @"Failed", (long)err.errorCode, @"connectNewDeviceToService.getNewDeviceWiFiStatus");
               //now set last method completed to AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE to guarrantee confirm connection method could be called after this failure
               [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE];
               failureBlock(err);
           }
        }];
        AYLA_RUN_ASYNC_ON_QUEUE_END
    };
    
    __failureBlock = _failureBlock = ^(AylaError *err) {
        
        if (errorTries-- > 0){
            if ([AylaHost isNewDeviceConnected]) {
                void (^strongFailureBlock)(AylaError *) = __failureBlock;
                AYLA_RUN_ASYNC_ON_QUEUE_BEGIN([AylaSetup setupQueue], 2.)
                saveToLog(@"%@, %@, %@:%ld, %@:%d, %@", @"I", @"DeviceSetup", @"FailureBlockOneMoreTry", (long)err.errorCode, @"errorTries", errorTries, @"connectNewDeviceToService.getNewDeviceWiFiStatus");
                [AylaSetup getNewDeviceWiFiStatus:_successBlock
                                          failure:strongFailureBlock];
                AYLA_RUN_ASYNC_ON_QUEUE_END
            }
            else {
                saveToLog(@"%@, %@, %@:%ld, %@", @"E", @"DeviceSetup", @"Failed", (long)err.errorCode, @"connectNewDeviceToService.getNewDeviceWiFiStatus");
                //now set last method completed to AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE to guarrantee confirm connection method could be called after this failure
                [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE];
                failureBlock(err);
            }
        }
        else {
            saveToLog(@"%@, %@, %@:%ld, %@", @"E", @"DeviceSetup", @"Failed", (long)err.errorCode, @"connectNewDeviceToService.getNewDeviceWiFiStatus");
            //now set last method completed to AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE to guarrantee confirm connection method could be called after this failure
            [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE];
            failureBlock(err);
        }
    };
    
    /**
     * Check if new device supports feature "ap-sta"
     */
    
    BOOL isApStaSupported = NO;
    
    /**
     * Key "Features" is added since device ver 1.4
     */
    if([AylaSetup newDevice].features != nil){
        for(NSString *feature in [AylaSetup newDevice].features) {
            if([feature isEqualToString:@"ap-sta"]) {
                isApStaSupported = YES;
                break;
            }
        }
    }
    
    if(isApStaSupported) {
        AYLA_RUN_ASYNC_ON_QUEUE_BEGIN([AylaSetup setupQueue], pollInterval)
        // start to poll network status
        [AylaSetup getNewDeviceWiFiStatus:_successBlock failure:^(AylaError *err) {
            if([AylaHost isNewDeviceConnected]) {
                [AylaSetup getNewDeviceWiFiStatus:_successBlock failure:_failureBlock];
            }
            else {
                [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE];
                failureBlock(err);
            }
        }];
        AYLA_RUN_ASYNC_ON_QUEUE_END
    }
    else { // new ap-sta setup is not supported by current device.
        if(callParams) {
            
            AylaHTTPOperation *operation = [callParams objectForKey:@"operation"];
            NSDictionary *responseObject = [callParams objectForKey:@"response"];
            
            if(operation.response.httpStatusCode == 200){
                AylaError *err = [AylaError new]; err.httpStatusCode = operation.response.httpStatusCode;
                err.errorCode = AML_SETUP_CONNECTION_ERROR;
                NSString *description = [responseObject valueForKeyPath:@"msg"];
                NSDictionary *error = [[NSDictionary alloc] initWithObjectsAndKeys:description, @"msg", [responseObject valueForKeyPath:@"error"], @"error", nil];
                err.errorInfo = error;
                err.nativeErrorInfo = nil;
                subTaskFailed = AML_CONNECT_NEW_DEVICE_TO_SERVICE;
                saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaSetup", @"Failed", description, @"AylaModule.setDeviceConnectToNetwork_handler");
                failureBlock(err);
            }
            else{
                [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE];
                [AylaSetup setConnectedMode:AML_CONNECTION_UNKNOWN];  //
                saveToLog(@"%@, %@, %@:%@, %@", @"I", @"AylaSetup", @"Success",@"OK", @"connectNewDeviceToService.postPath");
                AylaResponse *resp = [AylaResponse new]; resp.httpStatusCode = operation.response.httpStatusCode;
                successBlock(resp);
            }
        }
        else { //encrypted
            [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE];
            [AylaSetup setConnectedMode:AML_CONNECTION_UNKNOWN];  //
            saveToLog(@"%@, %@, %@:%@, %@", @"I", @"AylaSetup", @"Success",@"OK", @"connectNewDeviceToService.postPath");
            AylaResponse *resp = [AylaResponse new]; resp.httpStatusCode = AML_ERROR_ASYNC_OK;
            successBlock(resp);
        }
        
    }


}


+ (void)connectNewDeviceToService:(NSString *)ssid
                         password:(NSString *)password
                         optionalParams:(NSDictionary *)callParams
                         success:(void (^)(AylaResponse *))successBlock
                         failure:(void (^)(AylaError *))failureBlock
{
    //currently step getNewDeviceScanForAPs can be skipped here
    if( [AylaSetup lastMethodCompleted] != AML_SETUP_TASK_CONNECT_TO_NEW_DEVICE &&
       [AylaSetup lastMethodCompleted] != AML_SETUP_TASK_GET_DEVICE_SCAN_FOR_APS )
    {
        saveToLog(@"%@, %@, %@:%@,%@:%d, %@", @"E", @"AylaModule", @"Failed", @"TaskOutOfOrder", @"lastMethodCompleted", [AylaSetup lastMethodCompleted],  @"connectNewDeviceToService");
        NSNumber *methodCompleted = [[NSNumber alloc] initWithInt:[AylaSetup lastMethodCompleted]];
        NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys: methodCompleted ,@"taskOutOfOrder", nil];
        AylaError *err = [AylaError new]; err.errorCode = AML_TASK_ORDER_ERROR;
        err.errorInfo = description; err.nativeErrorInfo = nil;
        err.httpStatusCode = 0;
        failureBlock(err);
        return;
    }
    
    if([AylaSetup hostNewDeviceSsid] == nil){
        AylaError *err = [AylaError new]; err.httpStatusCode = 0;
        err.errorCode = AML_NO_DEVICE_CONNECTED;
        NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:@"Invalid new device SSID.", @"error", nil];
        err.errorInfo = description;
        err.nativeErrorInfo = nil;
        failureBlock(err);
        return;
    }
    
    NSString *setupToken = [AylaSystemUtils randomToken: DEFAULT_SETUP_TOKEN_LEN];
    [AylaSetup setSetupToken:setupToken];
    NSString *path;
    
    NSString *ssidHtml = [AylaSystemUtils uriEscapedStringFromString:ssid];
    NSString *passwordHtml = [AylaSystemUtils uriEscapedStringFromString:password];

    if(password==nil || [password isEqualToString:@""])
        path = [[NSString alloc] initWithFormat:@"wifi_connect.json?ssid=%@&setup_token=%@",
                ssidHtml,
                setupToken];
    else
        path = [[NSString alloc] initWithFormat:@"wifi_connect.json?ssid=%@&key=%@&setup_token=%@",
                ssidHtml,
                passwordHtml,
                setupToken];
    // check optinal params
    if( callParams &&
       [callParams objectForKey:AML_SETUP_LOCATION_LONGTITUDE] &&
       [callParams objectForKey:AML_SETUP_LOCATION_LATITUDE]) {
        
        if([[callParams objectForKey:AML_SETUP_LOCATION_LATITUDE] isKindOfClass:[NSNumber class]] &&
           [[callParams objectForKey:AML_SETUP_LOCATION_LONGTITUDE] isKindOfClass:[NSNumber class]]) {
         
            double longtitude = [(NSNumber *)[callParams objectForKey:AML_SETUP_LOCATION_LONGTITUDE] doubleValue];
            double latitude = [(NSNumber *)[callParams objectForKey:AML_SETUP_LOCATION_LATITUDE] doubleValue];
            
            NSString *locInfo = [NSString stringWithFormat:@"location=%f,%f", latitude, longtitude];
            path = [NSString stringWithFormat:@"%@&%@", path, locInfo];
        }
        else {
            AylaError *err = [AylaError new]; err.httpStatusCode = 0;
            err.errorCode = AML_NO_DEVICE_CONNECTED;
            NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:@"Invalid location information.", @"error", nil];
            err.errorInfo = description;
            err.nativeErrorInfo = nil;
            failureBlock(err);
            return;
        }
    }
    
    AylaDevice *lanDevice = [AylaLanMode deviceWithDsn:[AylaSetup newDevice].dsn];
    AylaLanSession *session = lanDevice.lanModule.session;
    if([AylaSetup securityType] != AylaSetupSecurityTypeNone &&
       lanDevice &&
       session) {
         int cmdId = [session nextCommandOutstandingId];
         __block int getResp = NO;
         NSString *jsonString = [AylaLanMode buildToDeviceCommand:@"POST" cmdId:cmdId resourse:path
                                                            data:nil
                                                              uri:@"/local_lan/connect_status"];
        
        AylaLanCommandEntity *command =
        [[AylaLanCommandEntity alloc] initWithParams:cmdId jsonString:jsonString type:AYLA_LAN_COMMAND];

        [command setRespBlock:^(AylaLanCommandEntity *command, NSDictionary *resp, int status, AylaError *error) {
            [command.parentOperation invokeCallbackBlockWithResponse:nil responseObj:resp error:error];
        }];
        
        AylaLanOperation *operation =
        [[AylaLanOperation alloc] initWithSubType:AylaLanOperationTypeCommand commands:@[command]
        callbackBlock:^(AylaResponse *response, id responseObj, AylaError *error) {
            
            getResp = YES;
            if(!error) {
                [AylaModule connectNewDevcieToServiceContinued:nil success:successBlock failure:failureBlock];
            }
            else {
                error.errorCode = AML_SETUP_DEVICE_ERROR;
                error.nativeErrorInfo = nil;
                subTaskFailed = AML_CONNECT_NEW_DEVICE_TO_SERVICE;
                NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
                saveToLog(@"%@, %@, %@:%lu, %@", @"E", @"DeviceSetup", @"httpStatusCode", (unsigned long)error.httpStatusCode, @"connectNewDeviceToService");
                error.errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", @"Securing setup: failure response from module.", @"msg", [NSNumber numberWithInt:0], @"error", nil];
                failureBlock(error);
            }
        }];
        
        [operation setTimeoutInterval:[operation suggestedTimeoutInterval]];
        [session pushOperation:operation];
    }
    else {
    
    NSMutableURLRequest *request = [[AylaApiClient sharedNewDeviceInstance] requestWithMethod:@"POST" path:path parameters:nil];
    [request setTimeoutInterval:DEFAULT_SETUP_WIFI_HTTP_TIMEOUT];
    AylaHTTPOperation *operation = [[AylaApiClient sharedNewDeviceInstance]
                                         operationWithRequest:request success:^(AylaHTTPOperation *operation, id responseObject) {
                                             [AylaModule connectNewDevcieToServiceContinued:[NSDictionary dictionaryWithObjectsAndKeys:operation, @"operation", responseObject, @"response", nil]
                                                                                    success:successBlock failure:failureBlock];
                                         } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                             saveToLog(@"%@, %@, %@:%ld, %@", @"E", @"DeviceSetup", @"Failed", (long)error.nativeErrorInfo.code, @"connectNewDeviceToService.postPath");
                                             error.errorCode = 1;
                                             subTaskFailed = AML_CONNECT_NEW_DEVICE_TO_SERVICE;
                                             NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
                                             NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", nil];
                                             error.errorInfo = description;
                                             failureBlock(error);
                                         }];
      [operation start];
    }
}

+ (void)confirmNewDeviceToServiceConnection:
                /*success:*/(void (^)(AylaResponse *response, NSDictionary *result))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    if([AylaSetup lastMethodCompleted] != AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE &&
       [AylaSetup lastMethodCompleted] != AML_SETUP_TASK_GET_NEW_DEVICE_WIFI_STATUS)
    {
        saveToLog(@"%@, %@, %@:%@,%@:%d, %@", @"E", AYLA_THIS_CLASS, @"Failed", @"TaskOutOfOrder", @"lastMethodCompleted", [AylaSetup lastMethodCompleted],  @"confirmNewDeviceToServiceConnection");
        NSNumber *methodCompleted = [[NSNumber alloc] initWithInt:[AylaSetup lastMethodCompleted]];
        NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys: methodCompleted ,@"taskOutOfOrder", nil];
        AylaError *err = [AylaError new]; err.errorCode = AML_TASK_ORDER_ERROR; err.httpStatusCode = 0;
        err.errorInfo = description; err.nativeErrorInfo = nil;
        failureBlock(err);
        return;
    }
    
    void (^_successBlock)(AylaResponse *, NSDictionary *) = ^(AylaResponse *resp, NSDictionary *responce) {
        
        NSDictionary *info = [responce objectForKey:@"device"];
        
        [AylaSetup setLanIp:[info valueForKeyPath:@"lan_ip"]];
        [AylaSetup setConnectedMode:AML_CONNECTED_TO_SERVICE];
        
        AylaDevice *device = [AylaDevice new];
        [device setSetupToken: [AylaSetup setupToken]];
        [device setRegistrationType:[info valueForKeyPath:@"registration_type"]];
        [device setLanIp:[AylaSetup lanIp]];
        [device setDsn: [[AylaSetup newDevice] dsn]];
        
        NSString *connectedAt = [info valueForKeyPath:@"connected_at"];
        [device setConnectedAt:connectedAt];
        saveToLog(@"%@, %@, %@:%@, %@:%@, %@", @"I", AYLA_THIS_CLASS, @"connectedAt", connectedAt , @"lanIp", [AylaSetup lanIp],  @"confirmNewDeviceToServiceConnection.getPath");
        
        // Save New Device to cache
        [AylaCache save:AML_CACHE_SETUP withObject:[NSArray arrayWithObjects:device, nil]];
        
        NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:@"success", @"success", device, @"device", nil];
        
        [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_CONFIRM_NEW_DEVICE_TO_SERVICE_CONNECTION];
        [AylaReachability setConnectivity:AML_REACHABILITY_REACHABLE];
        
        if(![AylaSetup inExit]){
            successBlock(resp, result);
        }
    }; 
    
    void (^__block __weak __failureBlock)(AylaHTTPOperation *, AylaError *);
    void (^__block _failureBlock)(AylaHTTPOperation *, AylaError *);
    __failureBlock = _failureBlock = ^(AylaHTTPOperation *operation, AylaError *err){
        if([AylaSetup inExit]){
            return;
        }
        if(err.errorCode == 1){
            NSError * nserr = err.nativeErrorInfo;
            
            int tries = AylaSetup.newDeviceToServiceConnectionRetries;
            int noInternetTries = AylaSetup.newDeviceToServiceNoInternetConnectionRetries;
            
            if(tries < [[AylaSystemUtils newDeviceToServiceConnectionRetries] integerValue] &&
               noInternetTries < DEFAULT_NEW_DEVICE_TO_SERVICE_NO_INTERNET_CONNECTION_RETRIES &&
               (nserr.code == NSURLErrorNotConnectedToInternet||
                nserr.code == NSURLErrorCannotFindHost||
                nserr.code == NSURLErrorCannotConnectToHost||
                operation.response.httpStatusCode == 404)){

                   void (^strongFailureBlock)(AylaHTTPOperation *, AylaError *) = __failureBlock;
                   AYLA_RUN_ASYNC_ON_QUEUE_BEGIN([AylaSetup setupQueue], 2.)
                   if(nserr.code == NSURLErrorNotConnectedToInternet){
                       [AylaSetup setNewDeviceToServiceNoInternetConnectionRetries:noInternetTries+1];
                   }
                   else{
                       if (nserr.code == NSURLErrorCannotConnectToHost) {
                           [AylaSetup setNewDeviceToServiceConnectionRetries:tries+2];
                       }
                       else
                           [AylaSetup setNewDeviceToServiceConnectionRetries:tries+1];
                   }
                   
                   saveToLog(@"%@, %@, %@:%ld, %@:%d, %@:%d, %@", @"I", AYLA_THIS_CLASS,
                             @"error", (long)nserr.code, @"tries", tries, @"noInternetTries", noInternetTries,
                             @"confirmNewDeviceToServiceConnection.failureBlock.Retry");
                   [AylaDevice getNewDeviceConnected:AylaSetup.newDevice.dsn setupToken:AylaSetup.setupToken
                                             success:_successBlock
                                             failure:strongFailureBlock];
                   AYLA_RUN_ASYNC_ON_QUEUE_END
               }
            else{
                saveToLog(@"%@, %@, %@:%ld, %@", @"E", AYLA_THIS_CLASS, @"nativeError", (long)nserr.code, @"confirmNewDeviceToServiceConnection");
                failureBlock(err);
            }            
        }
        else{
            saveToLog(@"%@, %@, %@:%ld, %@", @"E", AYLA_THIS_CLASS, @"AylaError", (long)err.errorCode, @"confirmNewDeviceToServiceConnection");
            failureBlock(err);
        }
    };
    
    void (^__block confirmBlock)(void) = ^(void){
        double delayInSeconds = DEFAULT_SETUP_STATUS_POLLING_INTERVAL;
        AYLA_RUN_ASYNC_ON_QUEUE_BEGIN([AylaSetup setupQueue], delayInSeconds)
        [AylaDevice getNewDeviceConnected:AylaSetup.newDevice.dsn
                               setupToken:AylaSetup.setupToken
                                  success:_successBlock
                                  failure:_failureBlock];
        AYLA_RUN_ASYNC_ON_QUEUE_END
    };
    
    /**
     * Disconnect new device
     */
    if ([AylaHost isNewDeviceConnected]) {
        [AylaModule disconnectNewDevice:nil success:^(AylaResponse *response){
            
            [[AylaSetup newDevice] lanModeDisable];
            double delayInSeconds = 1.0;
            AYLA_RUN_ASYNC_ON_QUEUE_BEGIN([AylaSetup setupQueue], delayInSeconds)
            [AylaDevice getNewDeviceConnected:AylaSetup.newDevice.dsn
                                   setupToken:AylaSetup.setupToken
                                      success:_successBlock
                                      failure:_failureBlock];
            [AylaSecurity refreshSessionKeyPair];
            AYLA_RUN_ASYNC_ON_QUEUE_END
        } failure:^(AylaError *err) {
            if(err.httpStatusCode == 403) { // Disconnect request is refused by module
                saveToLog(@"%@, %@, %@:%ld, %@", @"E", AYLA_THIS_CLASS, @"Failed", (long)err.errorCode, @"connectNewDeviceToService.disconnectNewDevice");                subTaskFailed = AML_DISCONNECT_NEW_DEVICE;
                NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
                NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", nil];
                err.errorInfo = description;
                failureBlock(err);
            }
            else {
                if ([AylaHost isNewDeviceConnected]) {
                    AylaError *err = [AylaError new]; err.errorCode = AML_AYLA_ERROR_FAIL; err.httpStatusCode = 0; err.nativeErrorInfo = nil;
                    subTaskFailed = AML_DISCONNECT_NEW_DEVICE;
                    NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
                    NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", nil];
                    err.errorInfo = description;
                    failureBlock(err);
                }
                else {
                    [[AylaSetup newDevice] lanModeDisable];
                    confirmBlock();
                }
            }
        }];
    }
    else {
        confirmBlock();
    }
       
}

+ (void)getNewDeviceWiFiStatus:
        /*success:*/(void (^)(AylaResponse *response, AylaWiFiStatus *result))successBlock
        failure:(void (^)(AylaError *err))failureBlock
{    
    if( [AylaSetup lastMethodCompleted] != AML_SETUP_TASK_CONNECT_TO_NEW_DEVICE &&
       [AylaSetup lastMethodCompleted] != AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE &&
       [AylaSetup lastMethodCompleted] != AML_SETUP_TASK_GET_DEVICE_SCAN_FOR_APS )
    {
        saveToLog(@"%@, %@, %@:%@,%@:%d, %@", @"E", @"AylaModule", @"Failed", @"TaskOutOfOrder", @"lastMethodCompleted", [AylaSetup lastMethodCompleted],  @"getNewDeviceWiFiStatus");
        NSNumber *methodCompleted = [[NSNumber alloc] initWithInt:[AylaSetup lastMethodCompleted]];
        NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys: methodCompleted ,@"taskOutOfOrder", nil];
        AylaError *err = [AylaError new]; err.errorCode = AML_TASK_ORDER_ERROR; err.httpStatusCode = 0;
        err.errorInfo = description; err.nativeErrorInfo = nil;
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        failureBlock(err);
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
        return;
    }
    
    if([AylaSetup hostNewDeviceSsid] == nil){
        AylaError *err = [AylaError new];
        err.errorCode = AML_NO_DEVICE_CONNECTED;
        err.httpStatusCode = 0;
        NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:@"Invalid new device SSID.", @"error", nil];
        err.errorInfo = description;
        err.nativeErrorInfo = nil;
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        failureBlock(err);
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
        return;
    }
    
    NSMutableURLRequest *request = [[AylaApiClient sharedNewDeviceInstance] requestWithMethod:@"GET" path:@"wifi_status.json" parameters:nil];
    [request setTimeoutInterval:DEFAULT_SETUP_WIFI_HTTP_TIMEOUT];
    AylaHTTPOperation *operation = [[AylaApiClient sharedNewDeviceInstance]
                                         operationWithRequest:request success:^(AylaHTTPOperation *operation, id responseObject) {
                                             NSDictionary *dict = [responseObject valueForKey:@"wifi_status"];
                                             AylaWiFiStatus *wifiStatus = [[AylaWiFiStatus alloc] initWiFiStatusWithDictionary:dict];
                                             saveToLog(@"%@, %@, %@:%@, %@:%lu, %@", @"I", @"AylaSetup", @"mac", wifiStatus.mac, @"wifiConnectHistories", (unsigned long)wifiStatus.connectHistory.count, @"getNewDeviceWiFiStatus");
                                             // Currently do not update lastMethodCompleted here
                                             // [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_GET_NEW_DEVICE_WIFI_STATUS];
                                             [AylaModule appendToLogService:dict];

                                             successBlock(operation.response, wifiStatus);
                                         } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                             saveToLog(@"%@, %@, %@, %@", @"E", @"DeviceSetup", @"Failed", @"getNewDeviceWiFiStatus.getPath");
                                             error.errorCode = 1;
                                             subTaskFailed = AML_GET_NEW_DEVICE_WIFI_STATUS;
                                             NSNumber *taskFailed = [[NSNumber alloc] initWithInt:subTaskFailed];
                                             NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:taskFailed, @"subTaskFailed", nil];
                                             error.errorInfo = description;
                                             failureBlock(error);
                                         }];
    [operation start];
}


+ (void)appendToLogService:(NSDictionary *)wifiStatusDict
{
    //Skip invalid wifi status
    if(!wifiStatusDict) {
        return;
    }
    
    NSMutableDictionary *aLog = [NSMutableDictionary new];
    [aLog setObject:[wifiStatusDict objectForKey:@"dsn"] forKey:@"dsn"];
    [aLog setObject:@"warning" forKey:@"level"];
    [aLog setObject:@"AylaSetup.AylaModule.getNewDeviceWiFiStatus" forKey:@"mod"];
    
    NSUInteger timeInSeconds= [[NSDate date] timeIntervalSince1970];
    NSNumber *time  = [NSNumber numberWithInteger: timeInSeconds];
    [aLog setObject:time forKey:@"time"];
    
    NSError *error;
    NSData *logInJson = [NSJSONSerialization dataWithJSONObject:wifiStatusDict
                                                       options:0
                                                         error:&error];
    NSString *logString = nil;
    if (!logInJson) {
        saveToLog(@"%@, %@, %@, %@", @"E", @"DeviceSetup", @"FailedToGenerateLogInJson", @"appendToLogService");
        logString = @"Failed to generate a valid Json String - appendToLogService.";
    }
    else
        logString = [[NSString alloc] initWithData:logInJson encoding:NSUTF8StringEncoding];
    
    [aLog setObject:logString forKey:@"text" ];
    [AylaLogService sendLogServiceMessage:aLog withDelay:YES];
}


@end
