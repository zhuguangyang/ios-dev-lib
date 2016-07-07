//
//  AylaNotifyHandler.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 3/17/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaLanMode.h"

@class AylaNotifyDescription;
@class AylaResponse;
@protocol AylaDeviceNotifyHandlerProtocol <NSObject>

- (void)didReceiveSessionUpdateForDevice:(NSString *)dsn sessionType:(int)sessionType newState:(int)sessionState response:(AylaResponse *)response;

- (void)didReceivePropertyUpdateForDevice:(NSString *)dsn propertyName:(NSString *)propertyName newValue:(id)value response:(AylaResponse *)response;

@end
