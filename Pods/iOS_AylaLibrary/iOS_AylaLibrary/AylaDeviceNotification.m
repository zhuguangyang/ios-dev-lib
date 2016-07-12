//
//  AylaDeviceNotification.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/2/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaDeviceNotification.h"
#import "AylaNetworks.h"
#import "AylaDeviceSupport.h"
#import "AylaErrorSupport.h"
#import "AylaApiClient.h"
#import "AylaAppNotificationSupport.h"
@interface AylaDeviceNotification()

@property (strong, nonatomic) NSNumber *id;
@property (strong, nonatomic) NSNumber *deviceKey;

@end

@implementation AylaDeviceNotification

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        self.id = [dictionary objectForKey:attrNameId];
        self.notificationType = [dictionary objectForKey:attrNameNotificationType];

        self.deviceNickname = [dictionary objectForKey:attrNameDeviceNickname]!=[NSNull null]?
            [dictionary objectForKey:attrNameDeviceNickname]: nil;
        self.threshold = [dictionary objectForKey:attrNameThreshold]!=[NSNull null]?
            [[dictionary objectForKey:attrNameThreshold] unsignedIntegerValue]: 0;
        self.url = [dictionary objectForKey:attrNameUrl]!=[NSNull null]?
            [dictionary objectForKey:attrNameUrl]: nil;
        self.userName = [dictionary objectForKey:attrNameUserName]!=[NSNull null]?
            [dictionary objectForKey:attrNameUserName]: nil;
        self.password = [dictionary objectForKey:attrNamePassword]!=[NSNull null]?
            [dictionary objectForKey:attrNamePassword]: nil;;
        self.message = [dictionary objectForKey:attrNameMessage]!=[NSNull null]?
            [dictionary objectForKey:attrNameMessage]: nil;
        
        self.deviceKey = [dictionary objectForKey:attrNameDeviceKey];
    }
    return self;
}

+ (NSOperation *)getNotificationsWithDevice:(AylaDevice *)device params:(NSDictionary *)params
                                 success:(void (^)(AylaResponse *response, NSMutableArray *deviceNotifications))successBlock
                                 failure:(void (^)(AylaError *err))failureBlock
{
    if(!device || !device.key) {
        NSDictionary *errors = @{@"device": @"is invalid"};
        failureBlock([AylaError createWithCode:AML_AYLA_ERROR_FAIL httpCode:0 nativeError:nil andErrorInfo:errors]);
        return nil;
    }

    return [[AylaApiClient sharedDeviceServiceInstance] getPath:[NSString stringWithFormat:@"devices/%@/notifications.json", device.key]
                parameters:nil
                success:^(AylaHTTPOperation *operation, id responseObject) {
                    saveToLog(@"%@, %@, %@, %@", @"I", @"AylaDeviceNotification", @"none", @"getDeviceNotifications");
                    
                    NSArray *resp = responseObject;
                    NSMutableArray *deviceNotifications = [NSMutableArray new];
                    for(NSDictionary *dict in resp) {
                        AylaDeviceNotification *deviceNotification = [[AylaDeviceNotification alloc] initWithDictionary:[dict objectForKey:@"notification"]];
                        [deviceNotifications addObject:deviceNotification];
                    }
                    
                    device.deviceNotifications = deviceNotifications;
                    successBlock(operation.response, deviceNotifications);
                } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                    saveToLog(@"%@, %@, %@, %@", @"E", @"AylaDeviceNotification", error.logDescription, @"getDeviceNotifications");
                    failureBlock(error);
                }];
}

+ (NSOperation *)createNotification:(AylaDeviceNotification *)deviceNotification withDevice:(AylaDevice *)device
                         success:(void (^)(AylaResponse *response, AylaDeviceNotification *createdDeviceNotification))successBlock
                         failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    if(!device || !device.key) {
        [errors setObject:@"is invalid." forKey:@"device"];
    }
    if(!deviceNotification) {
        [errors setObject:@"is invalid." forKey:@"device_notification"];
    }
    if(!deviceNotification.notificationType) {
        [errors setObject:@"can't be blank." forKey:attrNameNotificationType];
    }
    if(errors.count > 0) {
        failureBlock([AylaError createWithCode:AML_AYLA_ERROR_FAIL httpCode:0 nativeError:nil andErrorInfo:errors]);
        return nil;
    }
    
    return [[AylaApiClient sharedDeviceServiceInstance] postPath:[NSString stringWithFormat:@"devices/%@/notifications.json", device.key]
                                                      parameters:[deviceNotification toServiceDictionary]
              success:^(AylaHTTPOperation *operation, id responseObject) {
                  saveToLog(@"%@, %@, %@:%ld, %@", @"I", @"AylaDeviceNotification", @"http", (long)operation.response.httpStatusCode, @"createDeviceNotification");
                  
                  AylaDeviceNotification *createdDeviceNotification =
                  [[AylaDeviceNotification alloc] initWithDictionary:[responseObject objectForKey:@"notification"]];
                  
                  successBlock(operation.response, createdDeviceNotification);
              } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                  saveToLog(@"%@, %@, %@, %@", @"E", @"AylaDeviceNotification", error.logDescription, @"createDeviceNotification");
                  failureBlock(error);
              }];
}

+ (NSOperation *)updateNotification:(AylaDeviceNotification *)deviceNotification
                                  success:(void (^)(AylaResponse *response, AylaDeviceNotification *updatedDeviceNotification))successBlock
                                  failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];

    if(!deviceNotification || !deviceNotification.id) {
        [errors setObject:@"is invalid." forKey:@"device_notification"];
    }
    if(!deviceNotification.notificationType) {
        [errors setObject:@"can't be blank." forKey:attrNameNotificationType];
    }
    if(errors.count > 0) {
        failureBlock([AylaError createWithCode:AML_AYLA_ERROR_FAIL httpCode:0 nativeError:nil andErrorInfo:errors]);
        return nil;
    }
    return [[AylaApiClient sharedDeviceServiceInstance] putPath:[NSString stringWithFormat:@"notifications/%@.json", deviceNotification.id]
                  parameters:[deviceNotification toServiceDictionary]
                     success:^(AylaHTTPOperation *operation, id responseObject) {
                         saveToLog(@"%@, %@, %@:%ld, %@", @"I", @"AylaDeviceNotification", @"http", (long)operation.response.httpStatusCode, @"updateDeviceNotification");
                         
                         AylaDeviceNotification *createdDeviceNotification =
                         [[AylaDeviceNotification alloc] initWithDictionary:[responseObject objectForKey:@"notification"]];
                         
                         successBlock(operation.response, createdDeviceNotification);
                     } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                         saveToLog(@"%@, %@, %@, %@", @"E", @"AylaDeviceNotification", error.logDescription, @"updateDeviceNotification");
                         failureBlock(error);
                     }];
}

+ (NSOperation *)destroyNotification:(AylaDeviceNotification *)deviceNotification withDevice:(AylaDevice *)device
                                  success:(void (^)(AylaResponse *response))successBlock
                                  failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    
    if(!deviceNotification || !deviceNotification.id) {
        [errors setObject:@"is invalid." forKey:@"device_notification"];
    }
    if(errors.count > 0) {
        failureBlock([AylaError createWithCode:AML_AYLA_ERROR_FAIL httpCode:0 nativeError:nil andErrorInfo:errors]);
        return nil;
    }
    return [[AylaApiClient sharedDeviceServiceInstance] deletePath:[NSString stringWithFormat:@"notifications/%@.json", deviceNotification.id]
                     parameters:nil
                        success:^(AylaHTTPOperation *operation, id responseObject) {
                            saveToLog(@"%@, %@, %@:%ld, %@", @"I", @"AylaDeviceNotification", @"http", (long)operation.response.httpStatusCode, @"destroyDeviceNotification");
                            
                            successBlock(operation.response);
                        } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                            saveToLog(@"%@, %@, %@, %@", @"E", @"AylaDeviceNotification", error.logDescription, @"destroyDeviceNotification");
                            failureBlock(error);
                        }];
}

- (NSOperation *) getApps:(NSDictionary *)params
                  success:(void (^)(AylaResponse *response, NSMutableArray *deviceAppNotifications))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaAppNotification getAppNotificationsWithDeviceNotification:self params:params success:successBlock failure:failureBlock];
}

- (NSOperation *) createApp:(AylaAppNotification *)appNotification
                  success:(void (^)(AylaResponse *response, AylaAppNotification *createdDeviceAppNotification))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaAppNotification createAppNotification:appNotification withDeviceNotification:self success:successBlock failure:failureBlock];
}

- (NSOperation *) updateApp:(AylaAppNotification *)appNotification
                  success:(void (^)(AylaResponse *response, AylaAppNotification *updatedDeviceAppNotification))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaAppNotification updateAppNotification:appNotification withDeviceNotification:self success:successBlock failure:failureBlock];
}

- (NSOperation *) destroyApp:(AylaAppNotification *)appNotification
                   success:(void (^)(AylaResponse *response))successBlock
                   failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaAppNotification destroyAppNotification:appNotification withDeviceNotification:self success:successBlock failure:failureBlock];
}

- (NSDictionary *)toServiceDictionary
{
    NSParameterAssert(self.notificationType);
    NSMutableDictionary *toServiceDictionary = [NSMutableDictionary new];
    [toServiceDictionary setObject:self.notificationType forKey:attrNameNotificationType];
    [toServiceDictionary setObject:self.deviceNickname?:[NSNull null] forKey:attrNameDeviceNickname];
    
    if([self.notificationType isEqualToString:aylaDeviceNotificationTypeOnConnectionLost] ||
       [self.notificationType isEqualToString:aylaDeviceNotificationTypeOnConnectionRestore]) {
        
        [toServiceDictionary setObject:self.threshold?@(self.threshold):[NSNull null] forKey:attrNameThreshold];
    }
    else if([self.notificationType isEqualToString:aylaDeviceNotificationTypeOnConnect] ||
            [self.notificationType isEqualToString:aylaDeviceNotificationTypeIpChange]) {
        
        [toServiceDictionary setObject:self.url?:[NSNull null] forKey:attrNameUrl];
        [toServiceDictionary setObject:self.userName?:[NSNull null] forKey:attrNameUserName];
        [toServiceDictionary setObject:self.password?:[NSNull null] forKey:attrNamePassword];
    }
    return @{@"notification":toServiceDictionary};
}


- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaDeviceNotification *_copy = copy;
        _copy.id = [self.id copy];
        _copy.deviceNickname = [self.deviceNickname copy];
        _copy.notificationType = [self.notificationType copy];
        _copy.threshold = self.threshold;
                
        _copy.url = [self.url copy];
        _copy.userName = [self.userName copy];
        _copy.password = [self.password copy];
        _copy.message = [self.message copy];
        
        _copy.deviceKey = [self.deviceKey copy];
        _copy.appNotifications = self.appNotifications;
        _copy.appNotification = self.appNotification;
    }
    return copy;
}

static NSString * const attrNameId = @"id";
static NSString * const attrNameDeviceNickname = @"device_nickname";
static NSString * const attrNameNotificationType = @"notification_type";
static NSString * const attrNameThreshold = @"threshold";
static NSString * const attrNameUrl = @"url";
static NSString * const attrNameUserName = @"username";
static NSString * const attrNamePassword = @"password";
static NSString * const attrNameMessage = @"message";
static NSString * const attrNameDeviceKey = @"device_key";

@end

NSString * const aylaDeviceNotificationTypeOnConnect = @"on_connect";
NSString * const aylaDeviceNotificationTypeIpChange = @"ip_change";
NSString * const aylaDeviceNotificationTypeOnConnectionLost = @"on_connection_lost";
NSString * const aylaDeviceNotificationTypeOnConnectionRestore = @"on_connection_restore";