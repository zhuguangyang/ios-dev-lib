//
//  AylaLanModeSupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 3/20/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaLanCommandEntity.h"
#import "AylaTimer.h"
@interface AylaLanMode(Support)

//---------helpful functions--------------
+ (AylaDevice *)          device;
+ (void)                  setDevice:(AylaDevice *)_device;
+ (NSMutableDictionary *) devices;
+ (int)                   sessionState;
+ (void)                  setSessionState:(enum lanModeSession) _sessionState;
+ (BOOL)                  inSetupMode;
+ (void)                  inSetupMode:(BOOL)_inSetupMode;

+ (NSString *) buildToDeviceCommand:
                          (NSString *)method cmdId:(int)cmdId
                           resourse:(NSString *)resource data:(NSString *)data
                                uri:(NSString *) uri;

@end
