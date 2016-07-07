//
//  AylaAppNotificationSupport.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/6/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaAppNotification(Support)

@property (nonatomic, strong, readwrite) NSNumber *id;
@property (nonatomic, strong, readwrite) NSNumber *notificationId;

+ (NSOperation *) getAppNotificationsWithDeviceNotification:(AylaDeviceNotification *)deviceNotification params:(NSDictionary *)params
                                      success:(void (^)(AylaResponse *response, NSMutableArray *deviceAppNotifications))successBlock
                                      failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) createAppNotification:(AylaAppNotification *)deviceAppNotification withDeviceNotification:(AylaDeviceNotification *)deviceNotification
                                      success:(void (^)(AylaResponse *response, AylaAppNotification *createdDeviceAppNotification))successBlock
                                      failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) updateAppNotification:(AylaAppNotification *)deviceAppNotification withDeviceNotification:(AylaDeviceNotification *)deviceNotification
                                      success:(void (^)(AylaResponse *response, AylaAppNotification *updatedDeviceAppNotification))successBlock
                                      failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) destroyAppNotification:(AylaAppNotification *)deviceAppNotification withDeviceNotification:(AylaDeviceNotification *)deviceNotification
                                       success:(void (^)(AylaResponse *response))successBlock
                                       failure:(void (^)(AylaError *err))failureBlock;

@end
