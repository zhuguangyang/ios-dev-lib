//
//  AylaApiClient.m
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 6/4/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaDefines_Internal.h"
#import "AylaErrorSupport.h"
#import "AylaApiClient.h"
#import "AylaHost.h"
#import "AylaSetupSupport.h"
#import "AylaReachability.h"
#import "AylaReachabilitySupport.h"
#import "AylaConnectionOperationSupport.h"
#import "AylaHTTPOperation.h"
#import "AylaErrorSupport.h"
#import "AylaDefines_Internal.h"
#import <AFNetworking/AFURLResponseSerialization.h>

typedef NS_ENUM(NSInteger, AylaApiClientDestination) {
    AylaApiClientDestinationUnknown,
    AylaApiClientDestinationUserService,
    AylaApiClientDestinationDeviceService,
    AylaApiClientDestinationNonSecureDeviceService,
    AylaApiClientDestinationTriggerAppService,
    AylaApiClientDestinationLogService,
    AylaApiClientDestinationDevice
};

@interface AFHTTPSessionManager (Ayla_DataTaskMethods)
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure;
@end

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
static id getCloudErrorsFromNSError(NSError *error){
    NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if(data) {
        NSError *jsonError;
        id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if(!jsonError) {
            return object;
        }
        else {
            AylaLogV(@"AylaApiClient", 0, @"Json parsing error %@, origError %@", jsonError, error);
        }
    }
    return nil;
}
#endif

@interface AylaApiClient ()
@property (nonatomic, assign) AylaApiClientDestination clientDestination;
@end

@implementation AylaApiClient
static NSString * const https = @"https://";
static NSString * const http = @"http://";
static NSString * const serviceDomainUS = @".aylanetworks.com";
static NSString * const serviceDomainCN = @".ayla.com.cn";
static NSString * const serviceDomainEUSuffix = @"-eu";
@synthesize deviceServicePath = _deviceServicePath;
@synthesize userServicePath = _userServicePath;
@synthesize applicationTriggerServicePath = _applicationTriggerServicePath;
@synthesize connectedDevicePath = _connectedDevicePath;
@synthesize connectNewDevicePath = _connectNewDevicePath;
@synthesize logServicePath = _logServicePath;

static NSInteger deviceSeviceType = -1; static NSString *deviceAuthToken = nil;
static NSInteger deviceServiceLocation = -1;
static NSInteger deviceNonSecureProductionSevice = -1;
static NSInteger deviceNonSecureServiceLocation = -1;
static NSInteger userProductionService = -1; static NSString *userAuthToken = nil;
static NSInteger userServiceLocation = -1;
static NSInteger appTriggerProductionService = -1; static NSString *appTriggerAuthToken = nil;
static NSInteger appTriggerServiceLocation = -1;
static NSInteger logServiceType = -1; static NSString *logAuthToken = nil;
static NSInteger logServiceLocation = -1;

+ (NSString *)buildUrlPathWithAppId:(NSString *)appId andSuffixUrl:(NSString *)suffixUrl isHttps:(BOOL)isHttps
{
    return [NSString stringWithFormat:@"%@%@%@", isHttps?https:http, appId, suffixUrl];
}

+ (NSString *)addLocation:(AylaServiceLocation)location toUrlPath:(NSString *)url
{
    NSString *newUrl = url;
    switch (location) {
        case AylaServiceLocationCN:
        {
            newUrl = [url stringByReplacingOccurrencesOfString:serviceDomainUS withString:serviceDomainCN];
            break;
        }
        case AylaServiceLocationEU:
        {
            NSRange rangeOfDot = [newUrl rangeOfString:@"."];
            //Find first dot
            if (rangeOfDot.location != NSNotFound) {
                NSMutableString *mutableUrl = [newUrl mutableCopy];
                [mutableUrl insertString:serviceDomainEUSuffix atIndex:rangeOfDot.location];
                newUrl = mutableUrl;
            }
            break;
        }
        default:
            break;
    }
    return newUrl;
}

+ (id)sharedDeviceServiceInstance
{
  static AylaApiClient *__sharedDeviceServiceInstance = nil;;
  if ( (deviceSeviceType != [AylaSystemUtils.serviceType integerValue]) ||
       (deviceServiceLocation != [AylaSystemUtils serviceLocation]) ||
       (gblAuthToken!= nil && ![deviceAuthToken isEqualToString:gblAuthToken]))
  {
        deviceAuthToken = gblAuthToken;
        deviceSeviceType = [AylaSystemUtils.serviceType integerValue];
        deviceServiceLocation = [AylaSystemUtils serviceLocation];
        NSString *deviceServicePath = nil;
        switch(deviceSeviceType){
            case AML_DEVICE_SERVICE:
                if([AylaSystemUtils appId]){
                    deviceServicePath = [AylaApiClient buildUrlPathWithAppId:[AylaSystemUtils appId] andSuffixUrl:GBL_DEVICE_SUFFIX_URL isHttps:YES];
                    break;
                }
                else {
                    saveToLog(@"%@, %@, %@:%@, %@", @"W", @"ApiClient", @"deviceServicePath", @"AML_DEVICE_SERVICE with invalid appId", @"sharedDeviceServiceInstance");
                }
            case AML_STAGING_SERVICE:
                deviceServicePath = GBL_DEVICE_STAGING_URL;
                break;
            case AML_DEVELOPMENT_SERVICE:
                deviceServicePath = [AylaApiClient addLocation:deviceServiceLocation toUrlPath:GBL_DEVICE_DEVELOP_URL];
                break;
            case AML_DEMO_SERVICE:
                deviceServicePath = [AylaApiClient addLocation:deviceServiceLocation toUrlPath:GBL_DEVICE_DEMO_URL];
                break;
            default:
                deviceServicePath = [AylaApiClient addLocation:deviceServiceLocation toUrlPath:GBL_DEVICE_SERVICE_URL];
        }
        __sharedDeviceServiceInstance = [[AylaApiClient alloc] initWithBaseURL:[NSURL URLWithString:deviceServicePath]];
        __sharedDeviceServiceInstance.clientDestination = AylaApiClientDestinationDeviceService;
        AylaLogI(@"ApiClient", 0, @"deviceService - using baseUrl: %@", deviceServicePath);
  }
  return __sharedDeviceServiceInstance;
}


+ (id)sharedNonSecureDeviceServiceInstance
{
    static AylaApiClient *__sharedNonSecureDeviceServiceInstance;
    if ((deviceNonSecureProductionSevice != [AylaSystemUtils.serviceType integerValue]) ||
        (deviceNonSecureServiceLocation != [AylaSystemUtils serviceLocation]) ||
        (gblAuthToken!= nil && ![deviceAuthToken isEqualToString:gblAuthToken]))
    {
        deviceNonSecureProductionSevice = [AylaSystemUtils.serviceType integerValue];
        deviceNonSecureServiceLocation = [AylaSystemUtils serviceLocation];
        NSString *deviceServicePath = nil;
        switch(deviceNonSecureProductionSevice){
            case AML_DEVICE_SERVICE:
                if([AylaSystemUtils appId]){
                    deviceServicePath = [AylaApiClient buildUrlPathWithAppId:[AylaSystemUtils appId] andSuffixUrl:GBL_NON_SECURE_DEVICE_SUFFIX_URL isHttps:NO];
                    break;
                }
                else {
                    saveToLog(@"%@, %@, %@:%@, %@", @"W", @"ApiClient", @"deviceServicePath", @"AML_DEVICE_SERVICE with invalid appId", @"sharedNonSecureDeviceServiceInstance");
                }
            case AML_STAGING_SERVICE:
                deviceServicePath = GBL_NON_SECURE_DEVICE_STAGING_URL;
                break;
            case AML_DEVELOPMENT_SERVICE:
                deviceServicePath = [AylaApiClient addLocation:deviceNonSecureServiceLocation toUrlPath:GBL_NON_SECURE_DEVICE_DEVELOP_URL];
                break;
            case AML_DEMO_SERVICE:
                deviceServicePath = [AylaApiClient addLocation:deviceNonSecureServiceLocation toUrlPath:GBL_NON_SECURE_DEVICE_DEMO_URL];
                break;
            default:
                deviceServicePath = [AylaApiClient addLocation:deviceNonSecureServiceLocation toUrlPath:GBL_NON_SECURE_DEVICE_SERVICE_URL];
        }
        __sharedNonSecureDeviceServiceInstance = [[AylaApiClient alloc] initWithBaseURL:[NSURL URLWithString:deviceServicePath]];
        __sharedNonSecureDeviceServiceInstance.clientDestination = AylaApiClientDestinationNonSecureDeviceService;
        //saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApiClient", @"deviceNonSecureServicePath", __sharedNonSecureDeviceServiceInstance.baseURL, @"sharedNonSecureDeviceServiceInstance");
    }
    return __sharedNonSecureDeviceServiceInstance;
}


+ (id)sharedUserServiceInstance
{
  static AylaApiClient *__sharedUserServiceInstance;
  if ( (userProductionService != [AylaSystemUtils.serviceType integerValue]) ||
       (userServiceLocation != [AylaSystemUtils serviceLocation]) ||
      (![userAuthToken isEqualToString:gblAuthToken]))
    {
        userAuthToken = gblAuthToken;
        userProductionService = [AylaSystemUtils.serviceType integerValue];
        userServiceLocation = [AylaSystemUtils serviceLocation];
        NSString *userServicePath = nil;
        switch(userProductionService){
            case AML_STAGING_SERVICE:
                userServicePath = GBL_USER_STAGING_URL;
                break;
            case AML_DEVELOPMENT_SERVICE:
                userServicePath = [AylaApiClient addLocation:userServiceLocation toUrlPath:GBL_USER_DEVELOP_URL];
                break;
            case AML_DEMO_SERVICE:
                userServicePath = [AylaApiClient addLocation:userServiceLocation toUrlPath:GBL_USER_DEMO_URL];
                break;
            default:
                userServicePath = [AylaApiClient addLocation:userServiceLocation toUrlPath:GBL_USER_SERVICE_URL];
        }
        __sharedUserServiceInstance = [[AylaApiClient alloc] initWithBaseURL:[NSURL URLWithString:userServicePath]];
        __sharedUserServiceInstance.clientDestination = AylaApiClientDestinationUserService;
        //saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApiClient", @"userServicePath", __sharedUserServiceInstance.baseURL, @"sharedUserServiceInstance");
  }
  return __sharedUserServiceInstance;
}

+ (id)sharedAppTriggerServiceInstance
{
  static AylaApiClient *__sharedAppTriggerServiceInstance;
  
  if ( (appTriggerProductionService != [AylaSystemUtils.serviceType integerValue]) ||
       (appTriggerServiceLocation != [AylaSystemUtils serviceLocation]) ||
       (![appTriggerAuthToken isEqualToString:gblAuthToken]))
    {
        appTriggerAuthToken = gblAuthToken;
        appTriggerProductionService = [AylaSystemUtils.serviceType integerValue];
        appTriggerServiceLocation = [AylaSystemUtils serviceLocation];
        NSString *appTriggerServicePath = nil;
        switch(appTriggerProductionService){
            case AML_DEVICE_SERVICE:
                if([AylaSystemUtils appId]){
                    appTriggerServicePath = [AylaApiClient buildUrlPathWithAppId:[AylaSystemUtils appId] andSuffixUrl:GBL_APPTRIGGER_SUFFIX_URL isHttps:YES];
                    break;
                }
                else {
                    saveToLog(@"%@, %@, %@:%@, %@", @"W", @"ApiClient", @"appTriggerServicePath", @"AML_DEVICE_SERVICE with invalid appId", @"sharedAppTriggerServiceInstance");
                }
            case AML_STAGING_SERVICE:
                appTriggerServicePath = GBL_APPTRIGGER_STAGING_URL;
                break;
            case AML_DEVELOPMENT_SERVICE:
                appTriggerServicePath = [AylaApiClient addLocation:appTriggerServiceLocation toUrlPath:GBL_APPTRIGGER_DEVELOP_URL];
                break;
            case AML_DEMO_SERVICE:
                appTriggerServicePath = [AylaApiClient addLocation:appTriggerServiceLocation toUrlPath:GBL_APPTRIGGER_DEMO_URL];
                break;
            default:
                appTriggerServicePath = [AylaApiClient addLocation:appTriggerServiceLocation toUrlPath:GBL_APPTRIGGER_SERVICE_URL];
        }
        __sharedAppTriggerServiceInstance = [[AylaApiClient alloc] initWithBaseURL:[NSURL URLWithString:appTriggerServicePath]];
        __sharedAppTriggerServiceInstance.clientDestination = AylaApiClientDestinationTriggerAppService;
        //saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApiClient", @"appTriggerServicePath", __sharedAppTriggerServiceInstance.baseURL, @"sharedAppTriggerServiceInstance");
  }
  return __sharedAppTriggerServiceInstance;
}

// Local module connection
+ (id)sharedConnectedDeviceInstance:(NSString *)lanIp
{
    static AylaApiClient *__sharedConnectedDeviceInstance;
    NSString *basePath = [NSString stringWithFormat:@"%@%@%@", @"http://", lanIp, @"/"];
    //saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApiClient", @"basePath", basePath, @"sharedConnectedDeviceInstance");
    if(__sharedConnectedDeviceInstance == nil ||
       [[__sharedConnectedDeviceInstance.baseURL absoluteString] compare:basePath]!= 0){
        __sharedConnectedDeviceInstance = [[AylaApiClient alloc] initWithBaseURL:[NSURL URLWithString:basePath]];
        __sharedConnectedDeviceInstance.clientDestination = AylaApiClientDestinationDevice;
    }
    return __sharedConnectedDeviceInstance;
}

+ (id)sharedNewDeviceInstance
{
    static AylaApiClient *__sharedNewDeviceInstance = nil;
    NSString *newDevicePath = GBL_MODULE_DEFAULT_WIFI_IPADDR;
    if(__sharedNewDeviceInstance == nil){
        __sharedNewDeviceInstance = [[AylaApiClient alloc] initWithBaseURL:[NSURL URLWithString:newDevicePath]];
        __sharedNewDeviceInstance.clientDestination = AylaApiClientDestinationDevice;
        saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApiClient", @"connectNewDevicePath", __sharedNewDeviceInstance.baseURL, @"sharedNewDeviceInstance");
    }
    return __sharedNewDeviceInstance;
}

+ (id)sharedLogServiceInstance
{
    static AylaApiClient *__sharedLogServiceInstance = nil;
    if ((logServiceType != [AylaSystemUtils.serviceType integerValue ]) ||
        (logServiceLocation != [AylaSystemUtils serviceLocation]) ||
        (![logAuthToken isEqualToString:gblAuthToken]))
    {
        logAuthToken = gblAuthToken;
        logServiceType = [AylaSystemUtils.serviceType integerValue];
        logServiceLocation = [AylaSystemUtils serviceLocation];
        NSString *logServicePath = nil;
        switch(logServiceType){
            case AML_STAGING_SERVICE:
                logServicePath = GBL_LOG_STAGING_URL;
                break;
            case AML_DEVELOPMENT_SERVICE:
                logServicePath = [AylaApiClient addLocation:logServiceLocation toUrlPath:GBL_LOG_DEVELOP_URL];
                break;
            case AML_DEMO_SERVICE:
                logServicePath = [AylaApiClient addLocation:logServiceLocation toUrlPath:GBL_LOG_DEMO_URL];
                break;
            default:
                logServicePath = [AylaApiClient addLocation:logServiceLocation toUrlPath:GBL_LOG_SERVICE_URL];
        }
        __sharedLogServiceInstance = [[AylaApiClient alloc] initWithBaseURL:[NSURL URLWithString:logServicePath]];
        __sharedLogServiceInstance.clientDestination = AylaApiClientDestinationLogService;
        saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApiClient", @"logServicePath", __sharedLogServiceInstance.baseURL, @"sharedLogServiceInstance");
    }
    return __sharedLogServiceInstance;
}

+ (instancetype)HTTPClient
{
    return [[[self class] alloc] initWithBaseURL:nil];
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        saveToLog(@"%@, %@, %@", @"I", @"ApiClient", @"initWithBaseURL");
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        
        // Only append "Authorization" to header when baseUrl is not nil.
        if(url && gblAuthToken &&
           [url.absoluteString rangeOfString:https].location != NSNotFound ) {
            [self.requestSerializer setValue:[@"auth_token " stringByAppendingString:gblAuthToken] forHTTPHeaderField:@"Authorization"];
            AylaLogD(@"ApiClient", 0, @"Token assigned to baseUrl %@", url);
        }
        else {
            AylaLogD(@"ApiClient", 0, @"Empty token assigned to baseUrl %@", url);
        }
    }
    return self;
}

- (AylaHTTPOperation *)getPath:(NSString *)path
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(AylaHTTPOperation *, id))successBlock
                       failure:(void (^)(AylaHTTPOperation *, AylaError *))failureBlock
{
    AylaHTTPOperation *operation = [self operationWithMethod:AYLA_REQUEST_METHOD_GET
                                                        path:path
                                                  parameters:parameters
                                                     success:successBlock
                                                     failure:failureBlock];
    [operation start];
    return operation;
}

- (AylaHTTPOperation *)postPath:(NSString *)path
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(AylaHTTPOperation *, id))successBlock
                        failure:(void (^)(AylaHTTPOperation *, AylaError *))failureBlock
{
    AylaHTTPOperation *operation = [self operationWithMethod:AYLA_REQUEST_METHOD_POST
                                                        path:path
                                                  parameters:parameters
                                                     success:successBlock
                                                     failure:failureBlock];
    [operation start];
    return operation;
}

- (AylaHTTPOperation *)putPath:(NSString *)path
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(AylaHTTPOperation *, id))successBlock
                       failure:(void (^)(AylaHTTPOperation *, AylaError *))failureBlock
{
    AylaHTTPOperation *operation = [self operationWithMethod:AYLA_REQUEST_METHOD_PUT
                                                        path:path
                                                  parameters:parameters
                                                     success:successBlock
                                                     failure:failureBlock];
    [operation start];
    return operation;
}

- (AylaHTTPOperation *)deletePath:(NSString *)path
                       parameters:(NSDictionary *)parameters
                          success:(void (^)(AylaHTTPOperation *, id))successBlock
                          failure:(void (^)(AylaHTTPOperation *, AylaError *))failureBlock
{
    AylaHTTPOperation *operation = [self operationWithMethod:AYLA_REQUEST_METHOD_DELETE
                                                        path:path
                                                  parameters:parameters
                                                     success:successBlock
                                                     failure:failureBlock];
    [operation start];
    return operation;
}

- (AylaHTTPOperation *)operationWithGET:(NSString *)path
                             parameters:(NSDictionary *)parameters
                                success:(void (^)(AylaHTTPOperation *, id))successBlock
                                failure:(void (^)(AylaHTTPOperation *, AylaError *))failureBlock
{
    return
    [self operationWithMethod:AYLA_REQUEST_METHOD_GET
                         path:path
                   parameters:parameters
                      success:successBlock
                      failure:failureBlock];
}

- (AylaHTTPOperation *)operationWithPOST:(NSString *)path
                              parameters:(NSDictionary *)parameters
                                 success:(void (^)(AylaHTTPOperation *, id))successBlock
                                 failure:(void (^)(AylaHTTPOperation *, AylaError *))failureBlock
{
    return
    [self operationWithMethod:AYLA_REQUEST_METHOD_POST
                         path:path
                   parameters:parameters
                      success:successBlock
                      failure:failureBlock];
}

- (AylaHTTPOperation *)operationWithPUT:(NSString *)path
                             parameters:(NSDictionary *)parameters
                                success:(void (^)(AylaHTTPOperation *, id))successBlock
                                failure:(void (^)(AylaHTTPOperation *, AylaError *))failureBlock
{
    return
    [self operationWithMethod:AYLA_REQUEST_METHOD_PUT
                         path:path
                   parameters:parameters
                      success:successBlock
                      failure:failureBlock];
}

- (AylaHTTPOperation *)operationWithDELETE:(NSString *)path
                                parameters:(NSDictionary *)parameters
                                   success:(void (^)(AylaHTTPOperation *, id))successBlock
                                   failure:(void (^)(AylaHTTPOperation *, AylaError *))failureBlock
{
    return
    [self operationWithMethod:AYLA_REQUEST_METHOD_DELETE
                         path:path
                   parameters:parameters
                      success:successBlock
                      failure:failureBlock];
}


- (AylaHTTPOperation *)operationWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
                                   success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                   failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock
{
    __block AylaHTTPOperation *operation = [[AylaHTTPOperation alloc] init];
    
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    NSURLSessionDataTask *task =
    [self dataTaskWithHTTPMethod:method
                       URLString:path
                      parameters:parameters
                         success:^(NSURLSessionDataTask *task, id responseObject) {
                             NSHTTPURLResponse *taskResp = (NSHTTPURLResponse *)task.response;
                             AylaResponse *response = [[AylaResponse alloc] init];
                             response.httpStatusCode = taskResp.statusCode;
                             
                             operation.response = response;
                             operation.responseObject = responseObject;
                             [self didReceiveOperationSuccessResponse:operation.response];
                             successBlock(operation, responseObject);
                         }
                         failure:^(NSURLSessionDataTask *task, NSError *error) {
                             NSHTTPURLResponse *taskResp = (NSHTTPURLResponse *)task.response;
                             NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
                             if(data) {
                                 NSError *jsonError;
                                 id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                                 if(!jsonError) {
                                     operation.responseObject = object;
                                 }
                                 else {
                                     AylaLogV(@"AylaApiClient", 0, @"Json parsing error %@, origError %@", jsonError, error);
                                 }
                                 operation.responseObject = object;
                             }
                             
                             AylaError *err = [AylaError createWithCode:operation.responseObject? AML_AYLA_ERROR_FAIL: AML_ERROR_FAIL
                                                               httpCode:taskResp.statusCode
                                                            nativeError:error
                                                           andErrorInfo:operation.responseObject];
                             
                             operation.response = err;
                             failureBlock(operation, err);
                         }];
    operation.task = task;
#else
    void (^successResp)(AFHTTPRequestOperation *, id)
    = ^(AFHTTPRequestOperation *httpRequestOperation, id responseObject) {
        AylaResponse *response = [AylaResponse new];
        response.httpStatusCode = httpRequestOperation.response.statusCode;
        operation.response = response;
        [self didReceiveOperationSuccessResponse:response];
        successBlock(operation, responseObject);
    };

    void (^failureResp)(AFHTTPRequestOperation *, NSError *)
    = ^(AFHTTPRequestOperation *httpRequestOperation, NSError *error) {
        AylaError *err = [AylaError createWithCode:httpRequestOperation.responseObject? AML_AYLA_ERROR_FAIL: AML_ERROR_FAIL
                                            httpCode:httpRequestOperation.response.statusCode
                                         nativeError:error
                                        andErrorInfo:httpRequestOperation.responseObject];
        operation.response = err;
        failureBlock(operation, err);
    };

    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *httpRequestOperation = [self HTTPRequestOperationWithRequest:request success:successResp failure:failureResp];
    [operation setAssignedOperationQueue:self.operationQueue];
    [operation setTask:httpRequestOperation];
#endif
    return operation;
}

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
- (AylaHTTPOperation *)operationWithUploadRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData
                                         progress:(NSProgress *__autoreleasing __nullable *)progress
                                          success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                          failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock
{
    __block AylaHTTPOperation *operation = [[AylaHTTPOperation alloc] init];
    NSURLSessionTask *task =
    [self uploadTaskWithRequest:request
                       fromData:bodyData
                       progress:progress
              completionHandler:^(NSURLResponse *response, id responseObject, NSError * error) {
                  
                  if(!error) {
                      AylaResponse *resp = [AylaResponse new];
                      resp.httpStatusCode = [(NSHTTPURLResponse *)response statusCode];
                      operation.response = resp;
                      successBlock(operation, responseObject);
                  }
                  else {
                      id cloudErrors = getCloudErrorsFromNSError(error);
                      AylaError *err = [AylaError createWithCode:cloudErrors? AML_AYLA_ERROR_FAIL: AML_ERROR_FAIL
                                                        httpCode:[(NSHTTPURLResponse *)response statusCode]
                                                     nativeError:error
                                                    andErrorInfo:cloudErrors];
                      operation.response = err;
                      failureBlock(operation, err);
                  }
    }];
    operation.task = task;
    return operation;
}

- (AylaHTTPOperation *)operationWithStreamedUploadRequest:(NSURLRequest *)request
                                                 progress:(NSProgress *__autoreleasing __nullable *)progress
                                                  success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                                  failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock
{
    __block AylaHTTPOperation *operation = [[AylaHTTPOperation alloc] init];
    NSURLSessionTask *task =
    [self uploadTaskWithStreamedRequest:request
                               progress:progress
                      completionHandler:^(NSURLResponse * __nonnull response, id  __nullable responseObject, NSError * __nullable error) {
                          if(!error) {
                              AylaResponse *resp = [AylaResponse new];
                              resp.httpStatusCode = [(NSHTTPURLResponse *)response statusCode];
                              operation.response = resp;
                              successBlock(operation, responseObject);
                          }
                          else {
                              id cloudErrors = getCloudErrorsFromNSError(error);
                              AylaError *err = [AylaError createWithCode:cloudErrors? AML_AYLA_ERROR_FAIL: AML_ERROR_FAIL
                                                                httpCode:[(NSHTTPURLResponse *)response statusCode]
                                                             nativeError:error
                                                            andErrorInfo:cloudErrors];
                              operation.response = err;
                              failureBlock(operation, err);
                          }
    }];
    operation.task = task;
    return operation;
}

- (AylaHTTPOperation *)operationWithDownloadRequest:(NSURLRequest *)request
                                           progress:(NSProgress *__autoreleasing __nullable *)progress
                                        destination:(NSURL * __nonnull (^)(NSURL * __nonnull, NSURLResponse *__nonnull))destination
                                            success:(void (^)(AylaHTTPOperation *operation, NSURL *filePath))successBlock
                                            failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock
{
    __block AylaHTTPOperation *operation = [[AylaHTTPOperation alloc] init];
    NSURLSessionTask *task =
    [self downloadTaskWithRequest:request
                         progress:progress
                      destination:destination
                completionHandler:^(NSURLResponse * __nonnull response, NSURL * __nullable filePath, NSError * __nullable error) {
                    if(!error) {
                        AylaResponse *resp = [AylaResponse new];
                        resp.httpStatusCode = [(NSHTTPURLResponse *)response statusCode];
                        operation.response = resp;
                        successBlock(operation, filePath);
                    }
                    else {
                        id cloudErrors = getCloudErrorsFromNSError(error);
                        AylaError *err = [AylaError createWithCode:cloudErrors? AML_AYLA_ERROR_FAIL: AML_ERROR_FAIL
                                                          httpCode:[(NSHTTPURLResponse *)response statusCode]
                                                       nativeError:error
                                                      andErrorInfo:cloudErrors];
                        operation.response = err;
                        failureBlock(operation, err);
                    }
                }];
    operation.task = task;
    return operation;
}
#endif

- (AylaHTTPOperation *)operationWithUploadRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData
                                          success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                          failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock
{
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    return [self operationWithUploadRequest:request fromData:bodyData progress:nil success:successBlock failure:failureBlock];
#else
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [mutableRequest setHTTPBody:bodyData];
    
    return [self operationWithRequest:mutableRequest success:successBlock failure:failureBlock];
#endif
}

- (AylaHTTPOperation *)operationWithStreamedUploadRequest:(NSURLRequest *)request
                                                  success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                                  failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock
{
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    return [self operationWithStreamedUploadRequest:request progress:nil success:successBlock failure:failureBlock];
#else
    return [self operationWithRequest:request success:successBlock failure:failureBlock];
#endif
}

- (AylaHTTPOperation *)operationWithDownloadRequest:(NSURLRequest *)request
                                        destination:(NSURL * __nonnull (^)(NSURL * __nonnull targetPath, NSURLResponse * response))destination
                                            success:(void (^)(AylaHTTPOperation *operation, NSURL *filePath))successBlock
                                            failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock
{
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    return [self operationWithDownloadRequest:request progress:nil destination:destination success:successBlock failure:failureBlock];
#else
    
    NSURL *filePath = destination(request.URL, nil);
    AylaHTTPOperation *operation = [self operationWithRequest:request success:successBlock failure:failureBlock];
    [(AFHTTPRequestOperation *)operation.task setOutputStream:[NSOutputStream outputStreamToFileAtPath:filePath.path append:NO]];
    return operation;
#endif
}

- (AylaHTTPOperation *)operationWithRequest:(NSURLRequest *)request
                                    success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                    failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock
{
    __block AylaHTTPOperation *operation = [[AylaHTTPOperation alloc] init];
    
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    
    NSURLSessionDataTask *task =
    [self dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if(!error) {
            AylaResponse *resp = [[AylaResponse alloc] init];
            resp.httpStatusCode = [(NSHTTPURLResponse *)response statusCode];
            
            operation.response = resp;
            operation.responseObject = responseObject;
            [self didReceiveOperationSuccessResponse:operation.response];
            successBlock(operation, responseObject);
        }
        else {
            NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            if(data) {
                NSError *jsonError;
                id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                if(!jsonError) {
                    operation.responseObject = object;
                }
                else {
                    AylaLogV(@"AylaApiClient", 0, @"Json parsing error %@, origError %@", jsonError, error);
                }
                operation.responseObject = object;
            }
            
            AylaError *err = [AylaError createWithCode:operation.responseObject? AML_AYLA_ERROR_FAIL: AML_ERROR_FAIL
                                              httpCode:[(NSHTTPURLResponse *)response statusCode]
                                           nativeError:error
                                          andErrorInfo:operation.responseObject];
            operation.response = err;
            failureBlock(operation, err);
        }
    }];
    operation.task = task;
#else
    void (^successResp)(AFHTTPRequestOperation *, id)
    = ^(AFHTTPRequestOperation *httpRequestOperation, id responseObject) {
        AylaResponse *response = [AylaResponse new];
        response.httpStatusCode = httpRequestOperation.response.statusCode;
        operation.response = response;
        [self didReceiveOperationSuccessResponse:response];
        successBlock(operation, responseObject);
    };
    
    void (^failureResp)(AFHTTPRequestOperation *, NSError *)
    = ^(AFHTTPRequestOperation *httpRequestOperation, NSError *error) {
        AylaError *err = [AylaError createWithCode:httpRequestOperation.responseObject? AML_AYLA_ERROR_FAIL: AML_ERROR_FAIL
                                          httpCode:httpRequestOperation.response.statusCode
                                       nativeError:error
                                      andErrorInfo:httpRequestOperation.responseObject];
        operation.response = err;
        failureBlock(operation, err);
    };
    
    AFHTTPRequestOperation *httpRequestOperation = [self HTTPRequestOperationWithRequest:request success:successResp failure:failureResp];
    [operation setAssignedOperationQueue:self.operationQueue];
    [operation setTask:httpRequestOperation];
#endif
    return operation;
}


- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    NSError *error;
    
    NSMutableURLRequest *urlRequest
    = [self.requestSerializer requestWithMethod:method URLString:[NSString stringWithFormat:@"%@%@",self.baseURL.absoluteString?:@"", path, nil] parameters:parameters error:&error];
    
    if(error) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"ApiClient", @"error", [NSNumber numberWithInteger:error.code], @"requestWithMethod");
    }
    
    return urlRequest;
}

- (void)didReceiveOperationSuccessResponse:(AylaResponse *)response
{
    if(self.clientDestination == AylaApiClientDestinationDeviceService) {
        [AylaReachability setConnectivity:AML_REACHABILITY_REACHABLE];
    }
}

+ (NSString *)logTag
{
    return @"ApiClient";
}

@end
