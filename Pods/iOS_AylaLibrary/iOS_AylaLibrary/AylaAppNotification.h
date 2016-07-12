//
//  AylaAppNotification.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/3/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AylaDeviceNotification;
@class AylaAppNotificationParameters;
@class AylaResponse;
@class AylaError;
@interface AylaAppNotification : NSObject

@property (nonatomic, strong) NSString *appType;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) AylaAppNotificationParameters *notificationAppParameters;

@end

@interface AylaAppNotificationParameters : NSObject

@property (nonatomic, strong) NSNumber *contactId;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *message;

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *emailTemplateId;
@property (nonatomic, strong) NSString *emailSubject;
@property (nonatomic, strong) NSString *emailBodyHtml;

@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *phoneNumber;

@property (nonatomic, strong) NSString *registrationId;
@property (nonatomic, strong) NSString *applicationId;
@property (nonatomic, strong) NSString *pushSound;
@property (nonatomic, strong) NSString *pushMdata;

@end

extern NSString * const aylaAppNotificationTypeEmail;
extern NSString * const aylaAppNotificationTypeSms;
extern NSString * const aylaAppNotificationTypePush;