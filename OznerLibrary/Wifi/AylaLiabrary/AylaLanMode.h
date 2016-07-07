//
//  AylaLanMode.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/8/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaSystemUtils.h"

#define POST_LOCAL_REGISTRATION 570
#define PUT_LOCAL_REGISTRATION 700

@class AylaLanCommandEntity;
@class AylaDevice;
@interface AylaLanMode : AylaSystemUtils{
    enum lanModeSession {DOWN, LOCAL_REGISTRATION, KEY_EXCHANGE, UP, UNKNOWN, ERROR};
}

/**
 * Enables the application (activity) to use LAN Mode secure communication. In addition to enabling the application, the current device must 
   also be LAN Mode enabled
 * @params notifyHandle is app provided notifyHandler
 * @params reachabilityHandle is app provided notifyHandler
 * @result would be SUCCESS or ERROR
 */
+ (int)  enableWithNotifyHandle:
            /* notifyHandle*/ (void(^)(NSDictionary*)) notifyHandle
            ReachabilityHandle: (void(^)(NSDictionary*)) reachabilityHandle;

/**
 * Enables the application (activity) to use LAN Mode secure communication. In addition to enabling the application, the current device must
   also be LAN Mode enabled
 * @return can be AML_ERROR_OK or AML_ERROR_FAIL
 */
+ (int)  enable;

/**
 * This method will stop communication with all LME devices, stop the HTTP server, timers, etc. Buffered information of last connected LME device will be cleared.
 * @return can be AML_ERROR_OK or AML_ERROR_FAIL
 */
+ (int)  disable;

/**
 * Resume LAN mode communication and reboot http server. Typically called after LAN mode communication is paused.
 * @return can be AML_ERROR_OK or AML_ERROR_FAIL
 *
 * @deprecated This api has been deprecated since library starts to monitor application state from version 4.10.
 */
+ (int)  resume DEPRECATED_ATTRIBUTE;

/**
 * Pause LAN mode communication. This method will also stop current connection to the LME device and stop http server.
 * @return can be AML_ERROR_OK or AML_ERROR_FAIL
 *
 * @deprecated This api has been deprecated since library starts to monitor application state from version 4.10.
 */
+ (int)   pause DEPRECATED_ATTRIBUTE;

/**
 * If Lan Mode has been Enabled.
 * @return can be YES or NO
 */
+ (BOOL) isEnabled;

/**
 * @deprecated Deprecated in new multi lan session, use noitfyAcknowledge on each device level
 */
+ (void) notifyAcknowledge DEPRECATED_ATTRIBUTE;

/**
 * This method is used to register new reachability handler.
 */
+ (void) registerReachabilityHandle: (void(^)(NSDictionary *)) handle;

/**
 * This method is used to register new notify handler.
 */
+ (void) registerNotifyHandle: (void(^)(NSDictionary *))handle;

/**
 * Get library managed copy of device with device dsn. only for gateway and wifi devices
 */
+ (AylaDevice *) deviceWithDsn:(NSString *)dsn;

/**
 * Get library managed copy of device with device dsn.
 */
+ (AylaDevice *) deviceWithDsn:(NSString *)dsn recursiveCheck:(BOOL)recursiveCheck;

/**
 * Get library managed copy of device with lan ip.
 */
+ (AylaDevice *) deviceWithLanIp:(NSString *)lanIp;

/**
 * List of current lan active devices
 */
+ (NSArray *) activeDeviceList;

/**
 * List of current lan enabled device
 */
+ (NSArray *) enabledDeviceList;

/**
 * Close all devices' lan mode sessions
 */
+ (void) closeAllSessions;

/**
 * Reset lan mode manager from cache. This api will also close all devices' lan mode sessions.
 */
+ (void) resetFromCache;

@end
