//
//  AylaApiClient.h
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 6/4/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import "AylaHTTPOperation.h"

#define AML_SERVICE_LOCATION_CODE_US @""
#define AML_SERVICE_LOCATION_CODE_CN @"-cn"

@class AylaHTTPOperation;

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
@interface AylaApiClient : AFHTTPSessionManager
#else
@interface AylaApiClient : AFHTTPRequestOperationManager
#endif

@property (nonatomic, copy) NSString *deviceServicePath;             // base URL to Ayla Device Service
@property (nonatomic, copy) NSString *userServicePath;               // base URL to Ayla User Service
@property (nonatomic, copy) NSString *applicationTriggerServicePath; // base URL to Ayla ApplicationTrigger Service
@property (nonatomic, copy) NSString *connectedDevicePath;           // base URL to a device that has completed setup and is connecto to the Ayla device service
@property (nonatomic, copy) NSString *connectNewDevicePath;          //base URL to ayla new device
@property (nonatomic, copy) NSString *logServicePath;

- (AylaHTTPOperation *)getPath:(NSString *)path
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                       failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)postPath:(NSString *)path
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                        failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)putPath:(NSString *)path
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                       failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)deletePath:(NSString *)path
                       parameters:(NSDictionary *)parameters
                          success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                          failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)operationWithGET:(NSString *)path
                           parameters:(NSDictionary *)parameters
                                success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)operationWithPOST:(NSString *)path
                              parameters:(NSDictionary *)parameters
                                 success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                 failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)operationWithPUT:(NSString *)path
                            parameters:(NSDictionary *)parameters
                                success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)operationWithDELETE:(NSString *)path
                              parameters:(NSDictionary *)parameters
                                   success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                   failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)operationWithRequest:(NSURLRequest *)request
                                    success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                    failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)operationWithUploadRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData
                                          success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                          failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)operationWithStreamedUploadRequest:(NSURLRequest *)request
                                                  success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                                                  failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (AylaHTTPOperation *)operationWithDownloadRequest:(NSURLRequest *)request
                                        destination:(NSURL * (^)(NSURL * targetPath, NSURLResponse * response))destination
                                            success:(void (^)(AylaHTTPOperation *operation, NSURL *filePath))successBlock
                                            failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters;

+ (instancetype)sharedDeviceServiceInstance;
+ (instancetype)sharedUserServiceInstance;
+ (instancetype)sharedAppTriggerServiceInstance;
+ (instancetype)sharedConnectedDeviceInstance: (NSString *)url;
+ (instancetype)sharedNonSecureDeviceServiceInstance;
+ (instancetype)sharedNewDeviceInstance;
+ (instancetype)sharedLogServiceInstance;
+ (instancetype)HTTPClient;

@end

