//
//  AylaAppNotification.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/3/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaAppNotification.h"
#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaDeviceNotificationSupport.h"
#import "AylaErrorSupport.h"
#import "NSObject+AylaNetworks.h"
#import "NSString+AylaNetworks.h"
@interface AylaAppNotification()

@property (nonatomic, strong) NSNumber *id;
@property (nonatomic, strong) NSNumber *notificationId;

@end

@interface AylaAppNotificationParameters()

- (instancetype)initWithDictionary:(NSDictionary *)appParams;
- (NSDictionary *)toServiceDictionaryWithAppType:(NSString *)appType;

@end

@implementation AylaAppNotification

- (instancetype)init
{
    self = [super init];
    if(self) {
        self.notificationAppParameters = [AylaAppNotificationParameters new];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        self.id = [dictionary objectForKey:attrNameId];
        self.notificationId = [dictionary objectForKey:attrNameNotificationId];
        self.appType = [dictionary objectForKey:attrNameAppType];
        self.nickname = [dictionary objectForKey:attrNameNickname]!= [NSNull null]?
                        [dictionary objectForKey:attrNameNickname]: nil;
        self.notificationAppParameters =
        [[AylaAppNotificationParameters alloc] initWithDictionary:[dictionary objectForKey:@"notification_app_parameters"]];
     }
    return self;
}

+ (NSOperation *) getAppNotificationsWithDeviceNotification:(AylaDeviceNotification *)deviceNotification params:(NSDictionary *)params
                      success:(void (^)(AylaResponse *response, NSMutableArray *deviceAppNotifications))successBlock
                      failure:(void (^)(AylaError *err))failureBlock
{
    if(!deviceNotification || !deviceNotification.id) {
        NSDictionary *errors = @{@"device_notification": @"is invalid"};
        failureBlock([AylaError createWithCode:AML_AYLA_ERROR_FAIL httpCode:0 nativeError:nil andErrorInfo:errors]);
        return nil;
    }
    
    return [[AylaApiClient sharedDeviceServiceInstance] getPath:[NSString stringWithFormat:@"notifications/%@/notification_apps.json", deviceNotification.id]
                 parameters:nil
                    success:^(AylaHTTPOperation *operation, id responseObject) {
                        saveToLog(@"%@, %@, %@, %@", @"I", @"AylaAppNotification", @"none", @"getDeviceAppNotificationsWithDevN");
                        
                        NSArray *resp = responseObject;
                        NSMutableArray *deviceAppNotifications = [NSMutableArray new];
                        for(NSDictionary *dict in resp) {
                            AylaAppNotification *deviceAppNotification = [[AylaAppNotification alloc] initWithDictionary:[dict objectForKey:@"notification_app"]];
                            [deviceAppNotifications addObject:deviceAppNotification];
                        }
                        
                        deviceNotification.appNotifications = deviceAppNotifications;
                        successBlock(operation.response, deviceAppNotifications);
                    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                        saveToLog(@"%@, %@, %@, %@", @"E", @"AylaAppNotification", error.logDescription, @"getDeviceAppNotificationsWithDevN");
                        error.errorCode = AML_AYLA_ERROR_FAIL;
                        failureBlock(error);
                    }];
}

+ (NSOperation *) createAppNotification:(AylaAppNotification *)deviceAppNotification
                       withDeviceNotification:(AylaDeviceNotification *)deviceNotification
                                      success:(void (^)(AylaResponse *response, AylaAppNotification *createdDeviceAppNotification))successBlock
                                      failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    if(!deviceNotification || !deviceNotification.id) {
        [errors setObject:@"is invalid." forKey:@"device_notification"];
    }
    if(!deviceAppNotification) {
        [errors setObject:@"is invalid." forKey:@"device_app_notification"];
    }
    if(!deviceAppNotification.appType) {
        [errors setObject:@"can't be blank." forKey:attrNameAppType];
    }
    if(errors.count > 0) {
        failureBlock([AylaError createWithCode:AML_AYLA_ERROR_FAIL httpCode:0 nativeError:nil andErrorInfo:errors]);
        return nil;
    }
    
    return [[AylaApiClient sharedDeviceServiceInstance] postPath:[NSString stringWithFormat:@"notifications/%@/notification_apps.json", deviceNotification.id]
                  parameters:[deviceAppNotification toServiceDictionary]
                    success:^(AylaHTTPOperation *operation, id responseObject) {
                        saveToLog(@"%@, %@, %@, %@", @"I", @"AylaAppNotification", @"none", @"createDeviceAppNotification");
                        
                        NSDictionary *resp = responseObject;
                        AylaAppNotification *createdAppNotification =
                        [[AylaAppNotification alloc] initWithDictionary:[resp objectForKey:@"notification_app"]];
                        
                        successBlock(operation.response, createdAppNotification);
                    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                        saveToLog(@"%@, %@, %@, %@", @"E", @"AylaAppNotification", error.logDescription, @"createDeviceAppNotification");
                        error.errorCode = AML_AYLA_ERROR_FAIL;
                        failureBlock(error);
                    }];
}

+ (NSOperation *) updateAppNotification:(AylaAppNotification *)deviceAppNotification withDeviceNotification:(AylaDeviceNotification *)deviceNotification
                                      success:(void (^)(AylaResponse *response, AylaAppNotification *updatedDeviceAppNotification))successBlock
                                      failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    if(!deviceNotification || !deviceNotification.id) {
        [errors setObject:@"is invalid." forKey:@"device_notification"];
    }
    if(!deviceAppNotification || !deviceAppNotification.id) {
        [errors setObject:@"is invalid." forKey:@"device_app_notification"];
    }
    if(!deviceAppNotification.appType) {
        [errors setObject:@"can't be blank." forKey:attrNameAppType];
    }
    if(errors.count > 0) {
        failureBlock([AylaError createWithCode:AML_AYLA_ERROR_FAIL httpCode:0 nativeError:nil andErrorInfo:errors]);
        return nil;
    }
    
    return [[AylaApiClient sharedDeviceServiceInstance] putPath:[NSString stringWithFormat:@"notifications/%@/notification_apps/%@.json", deviceNotification.id, deviceAppNotification.id]
                  parameters:[deviceAppNotification toServiceDictionary]
                     success:^(AylaHTTPOperation *operation, id responseObject) {
                         saveToLog(@"%@, %@, %@, %@", @"I", @"AylaAppNotification", @"none", @"updateDeviceAppNotification");
                         
                         NSDictionary *resp = responseObject;
                         AylaAppNotification *updatedAppNotification =
                         [[AylaAppNotification alloc] initWithDictionary:[resp objectForKey:@"notification_app"]];
                         
                         successBlock(operation.response, updatedAppNotification);
                     } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                         saveToLog(@"%@, %@, %@, %@", @"E", @"AylaAppNotification", error.logDescription, @"updateDeviceAppNotification");
                         error.errorCode = AML_AYLA_ERROR_FAIL;
                         failureBlock(error);
                     }];
}

+ (NSOperation *) destroyAppNotification:(AylaAppNotification *)deviceAppNotification withDeviceNotification:(AylaDeviceNotification *)deviceNotification
                                       success:(void (^)(AylaResponse *response))successBlock
                                       failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    if(!deviceNotification || !deviceNotification.id) {
        [errors setObject:@"is invalid." forKey:@"device_notification"];
    }
    if(!deviceAppNotification || !deviceAppNotification.id) {
        [errors setObject:@"is invalid." forKey:@"device_app_notification"];
    }
    if(errors.count > 0) {
        failureBlock([AylaError createWithCode:AML_AYLA_ERROR_FAIL httpCode:0 nativeError:nil andErrorInfo:errors]);
        return nil;
    }
    
    return [[AylaApiClient sharedDeviceServiceInstance] deletePath:[NSString stringWithFormat:@"notifications/%@/notification_apps/%@.json", deviceNotification.id, deviceAppNotification.id]
                     parameters:nil
                        success:^(AylaHTTPOperation *operation, id responseObject) {
                            saveToLog(@"%@, %@, %@, %@", @"I", @"AylaAppNotification", @"none", @"destroyDeviceAppNotification");
                            successBlock(operation.response);
                        } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                            saveToLog(@"%@, %@, %@, %@", @"E", @"AylaAppNotification", error.logDescription, @"destroyDeviceAppNotification");
                            error.errorCode = AML_AYLA_ERROR_FAIL;
                            failureBlock(error);
                        }];
}

- (NSDictionary *)toServiceDictionary
{
    NSParameterAssert(self.appType);
    NSMutableDictionary *toServiceDictionary = [NSMutableDictionary new];
    [toServiceDictionary setObject:self.appType forKey:attrNameAppType];
    [toServiceDictionary setObject:self.nickname?:[NSNull null] forKey:attrNameNickname];
    [toServiceDictionary setObject:[self.notificationAppParameters toServiceDictionaryWithAppType:self.appType] forKey:@"notification_app_parameters"];
    return @{@"notification_app":toServiceDictionary};
}

//-------------------- helper methods
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaAppNotification *_copy = copy;
        _copy.id = [self.id copy];
        _copy.notificationId = [self.notificationId copy];
        _copy.appType = [self.appType copy];
        _copy.nickname = [self.nickname copy];
        _copy.notificationAppParameters = [self.notificationAppParameters copy];
    }
    return copy;
}

static NSString * const attrNameId = @"id";
static NSString * const attrNameNotificationId = @"notification_id";
static NSString * const attrNameAppType = @"app_type";
static NSString * const attrNameNickname = @"nickname";

@end

@implementation AylaAppNotificationParameters

- (void)setCountryCode:(NSString *)countryCode {
    _countryCode = [countryCode stringByStrippingLeadingZeroes];
}

- (NSDictionary *)toServiceDictionaryWithAppType:(NSString *)appType
{
    NSParameterAssert(appType);
    NSMutableDictionary *appParams = [NSMutableDictionary new];
    [appParams setObject:self.contactId?:[NSNull null] forKey:attrNameContactId];
    [appParams setObject:self.username?:[NSNull null] forKey:attrNameUserName];
    [appParams setObject:self.message?:[NSNull null] forKey:attrNameMessage];
    if([appType isEqualToString:aylaAppNotificationTypeEmail]) {
        [appParams setObject:self.email?:[NSNull null] forKey:attrNameEmailAddr];
        [appParams setObject:self.emailSubject?:[NSNull null] forKey:attrNameEmailSubject];
        [appParams setObject:self.emailTemplateId?:[NSNull null] forKey:attrNameEmailTemplateId];
        [appParams setObject:self.emailBodyHtml?:[NSNull null] forKey:attrNameEmailBodyHtml];
    }
    else if([appType isEqualToString:aylaAppNotificationTypeSms]) {
        [appParams setObject:self.countryCode?:[NSNull null] forKey:attrNameCountryCode];
        [appParams setObject:self.phoneNumber?:[NSNull null] forKey:attrNamePhoneNumber];
    }
    else if([appType isEqualToString:aylaAppNotificationTypePush]) {
        [appParams setObject:self.applicationId?:[NSNull null] forKey:attrNameAppId];
        [appParams setObject:self.registrationId?:[NSNull null] forKey:attrNameRegistrationId];
        [appParams setObject:self.pushMdata?:[NSNull null] forKey:attrNamePushData];
        [appParams setObject:self.pushSound?:[NSNull null] forKey:attrNamePushSound];
    }
    return appParams;
}

- (instancetype)initWithDictionary:(NSDictionary *)appParams
{
    self = [super init];
    if(self) {
        if(appParams) {
            self.contactId = [[appParams objectForKey:attrNameContactId] nilIfNull];
            self.username = [[appParams objectForKey:attrNameUserName] nilIfNull];
            self.message = [[appParams objectForKey:attrNameMessage] nilIfNull];

            self.email = [[appParams objectForKey:attrNameEmailAddr] nilIfNull];
            self.emailSubject = [[appParams objectForKey:attrNameEmailSubject] nilIfNull];
            self.emailTemplateId = [[appParams objectForKey:attrNameEmailTemplateId] nilIfNull];
            self.emailBodyHtml = [[appParams objectForKey:attrNameEmailBodyHtml] nilIfNull];
        
            self.countryCode = [[appParams objectForKey:attrNameCountryCode] nilIfNull];
            self.phoneNumber = [[appParams objectForKey:attrNamePhoneNumber] nilIfNull];
        
            self.applicationId = [[appParams objectForKey:attrNameAppId] nilIfNull];
            self.registrationId = [[appParams objectForKey:attrNameRegistrationId] nilIfNull];
            self.pushMdata = [[appParams objectForKey:attrNamePushData] nilIfNull];
            self.pushSound = [[appParams objectForKey:attrNamePushSound] nilIfNull];
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaAppNotificationParameters *_copy = copy;
        _copy.contactId = [self.contactId copy];
        _copy.username = [self.username copy];
        _copy.message = [self.message copy];
        
        _copy.email = [self.email copy];
        _copy.emailSubject = [self.emailSubject copy];
        _copy.emailTemplateId = [self.emailTemplateId copy];
        _copy.emailBodyHtml = [self.emailBodyHtml copy];
        
        _copy.countryCode = [self.countryCode copy];
        _copy.phoneNumber = [self.phoneNumber copy];
        
        _copy.applicationId = [self.applicationId copy];
        _copy.registrationId = [self.registrationId copy];
        _copy.pushSound = [self.pushSound copy];
        _copy.pushMdata = [self.pushMdata copy];
    }
    return copy;
}

static NSString * const attrNameContactId = @"contact_id";

static NSString * const attrNameUserName = @"username";
static NSString * const attrNameMessage = @"message";

static NSString * const attrNameEmailAddr = @"email";
static NSString * const attrNameEmailTemplateId = @"email_template_id";
static NSString * const attrNameEmailSubject = @"email_subject";
static NSString * const attrNameEmailBodyHtml = @"email_body_html";

static NSString * const attrNameAppId = @"application_id";
static NSString * const attrNameRegistrationId = @"registration_id";
static NSString * const attrNamePushData = @"push_mdata";
static NSString * const attrNamePushSound = @"push_sound";

static NSString * const attrNameCountryCode = @"country_code";
static NSString * const attrNamePhoneNumber= @"phone_number";

@end

NSString * const aylaAppNotificationTypeEmail = @"email";
NSString * const aylaAppNotificationTypeSms = @"sms";
NSString * const aylaAppNotificationTypePush = @"push_ios";