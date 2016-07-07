//
//  AylaDeviceNotification.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/2/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AylaDevice;
@class AylaResponse;
@class AylaError;
@class AylaAppNotification;
@interface AylaDeviceNotification : NSObject

/** Notification type. One of following:aylaDeviceNotificationTypeOnConnect,aylaDeviceNotificationTypeIpChange, aylaDeviceNotificationTypeOnConnectionLost, aylaDeviceNotificationTypeOnConnectionRestore */
@property (strong, nonatomic) NSString *notificationType;

/** A nickname for the associated device. */
@property (strong, nonatomic) NSString *deviceNickname;

/** number of seconds for which the condition must be active before notification is sent. Minimum is 300 seconds. */
@property (assign, nonatomic) NSUInteger threshold;

/** Complete URL to which the property value must be forwarded. (only for on_connect and ip_change types) */
@property (strong, nonatomic) NSString *url;

/** Username for basic auth if required for the service. */
@property (strong, nonatomic) NSString *userName;

/** Password for basic auth required for the service. */
@property (strong, nonatomic) NSString *password;

/** Custom message for this notification type along default message. */
@property (strong, nonatomic) NSString *message;

@property (nonatomic) NSMutableArray *appNotifications;
@property (nonatomic) AylaAppNotification *appNotification;

/**
 * This pass-through method is used to retrieve all child App Notifications for current device notification.
 * @param params Not required.
 * @param successBlock Block which would be called with retrieved app notifications when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getApps:(NSDictionary *)params
                  success:(void (^)(AylaResponse *response, NSMutableArray *deviceAppNotifications))successBlock
                  failure:(void (^)(AylaError *err))failureBlock;

/**
 * This pass-through method is used to instantiate a new app notification for current device notification.
 * @param appNotification The app notification to be created.
 * @param successBlock Block which would be called with the created app notifications when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) createApp:(AylaAppNotification *)appNotification
                  success:(void (^)(AylaResponse *response, AylaAppNotification *createdDeviceAppNotification))successBlock
                  failure:(void (^)(AylaError *err))failureBlock;

/**
 * This pass-through method is used to update an exsiting app notification for current device notification.
 * @param appNotification The app notification to be updated.
 * @param successBlock Block which would be called with the updated app notifications when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) updateApp:(AylaAppNotification *)appNotification
                  success:(void (^)(AylaResponse *response, AylaAppNotification *updatedDeviceAppNotification))successBlock
                  failure:(void (^)(AylaError *err))failureBlock;

/**
 * This pass-through method is used to remove an existing app notification for current device notification.
 * @param appNotification The app notification to be removed.
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) destroyApp:(AylaAppNotification *)appNotification
                  success:(void (^)(AylaResponse *response))successBlock
                  failure:(void (^)(AylaError *err))failureBlock;

@end

extern NSString * const aylaDeviceNotificationTypeOnConnect;
extern NSString * const aylaDeviceNotificationTypeIpChange;
extern NSString * const aylaDeviceNotificationTypeOnConnectionLost;
extern NSString * const aylaDeviceNotificationTypeOnConnectionRestore;