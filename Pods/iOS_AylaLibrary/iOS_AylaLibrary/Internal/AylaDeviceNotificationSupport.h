//
//  AylaDeviceNotificationSupport.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/3/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaDeviceNotification(Support)

@property (strong, nonatomic) NSNumber *id;

+ (NSOperation *)getNotificationsWithDevice:(AylaDevice *)device params:(NSDictionary *)params
                                          success:(void (^)(AylaResponse *response, NSMutableArray *deviceNotifications))successBlock
                                          failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *)createNotification:(AylaDeviceNotification *)deviceNotification withDevice:(AylaDevice *)device
                                  success:(void (^)(AylaResponse *response, AylaDeviceNotification *createdDeviceNotification))successBlock
                                  failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *)updateNotification:(AylaDeviceNotification *)deviceNotification
                                  success:(void (^)(AylaResponse *response, AylaDeviceNotification *updatedDeviceNotification))successBlock
                                  failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *)destroyNotification:(AylaDeviceNotification *)deviceNotification withDevice:(AylaDevice *)device
                                   success:(void (^)(AylaResponse *response))successBlock
                                   failure:(void (^)(AylaError *err))failureBlock;

@end
