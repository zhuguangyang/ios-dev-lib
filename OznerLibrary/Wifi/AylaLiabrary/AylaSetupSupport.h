//
//  AylaSetupSupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 3/20/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaSetup(Support)

+ (AylaModule *) newDevice;
+ (void) setNewDevice:(AylaModule *)newDevice;

+ (void) setLastMethodCompleted:(int)lastMethodCompleted;
+ (void) setConnectedMode:(NSString *)connectedMode;

+ (NSString *) hostNewDeviceSsid;
+ (void) setHostNewDeviceSsid:(NSString *)hostNewDeviceSsid;

+ (NSString *) setupToken;
+ (void) setSetupToken:(NSString *)setupToken;

+ (NSString *) hostNewDeviceSecurityType;
+ (void) setHostNewDeviceSecurityType:(NSString *)hostNewDeviceSecurityType;

+ (NSString *) hostNewDevicePassword;
+ (void) setHostNewDevicePassword:(NSString *)hostNewDevicePassword;

+ (void) securityType:(AylaSetupSecurityType)type;
+ (AylaSetupSecurityType) securityType;

+ (void) continueBlock:(void (^)(BOOL isEastablished))block;
+ (void (^)(BOOL isEastablished)) continueBlock;

+ (dispatch_queue_t) setupQueue;

+ (void) init;
+ (BOOL) inExit;

@end
