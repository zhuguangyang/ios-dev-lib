//
//  AylaSystemUtils.h
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 6/26/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaLogManager.h"
#import "AylaLogManagerSupport.h"

typedef NS_ENUM(NSUInteger, AylaServiceLocation) {
    AylaServiceLocationUS = 0,
    AylaServiceLocationCN,
    AylaServiceLocationEU
};

@interface AylaSystemUtils : NSObject 

/**
 * The Wi-Fi time-out value in seconds
 */
+ (NSNumber *)wifiTimeout;
+ (void) wifiTimeout:(NSNumber *)wifiTimeout;

/**
 * Maximum number of objects returned per request.
 */
+ (NSNumber *)maxCount;
+ (void) maxCount:(NSNumber *)maxCount;

/**
 * Directive to use development, staging or production Ayla cloud services.
 */
+ (NSNumber *)serviceType;
+ (void) serviceType:(NSNumber *)serviceType;

/**
 * Directive to use development, staging or production Ayla cloud services.
 */
+ (AylaServiceLocation) serviceLocation;
+ (AylaServiceLocation) serviceLocationWithAppId:(NSString *)appId;
+ (AylaServiceLocation) serviceLocationWithCountryCode:(NSString *)countryCode;

/**
 * Set level of logs to be displayed/stored
 */
+ (AylaSystemLoggingLevel) loggingLevel;
+ (void) loggingLevel:(AylaSystemLoggingLevel)level;

/**
 * Set logging outputs
 */
+ (AylaSystemLoggingOutput) loggingOutputs;
+ (void) loggingOutputs:(AylaSystemLoggingOutput)outputs;

/**
 * Current Lan Mode State. Normally Set it to ENABLED before LAN Mode method [AylaLanMode enable] is called.
 */
+ (enum AML_LAN_MODE_STATE) lanModeState;
+ (void) lanModeState: (enum AML_LAN_MODE_STATE) lanModeState;

/**
 * Port number of Http Server.
 */
+ (NSNumber *) serverPortNumber;
+ (void) serverPortNumber:(int)serverPortNumber;

/**
 * Set timeout value for service reachability check. 
 */
+ (NSNumber *) serviceReachableTimeout;

/**
 * Regular Expression for device SSID. Used to check connected device during setup task. 
 */
+ (NSString *)deviceSsidRegex;
+ (void) setDeviceSsidRegex: (NSString *)_deviceSsidRegex;

/**
 * Set timeout-value for service reachability check.
 */
+ (void) serviceReachableTimeout:(NSNumber *) serviceReachableTimeout;

/**
 * Set to enable/disable Notify Outstandings.
 *
 * @discussion Notify Outstanding is a mechanism deployed to enhance performance of LME apis. With
 * this feature, when receving a message from module, library will update correponding values and
 * send a notify message back to application. When application calls LME apis to fetch this update, 
 * instead of sending an additional request to module, library will return this value directly from 
 * its cache. By default, this is set to be @(YES).
 */
+ (NSNumber *) notifyOutstandingEnabled;
+ (void) setNotifyOutstandingEnabled:(NSNumber *)setEnabled;

/**
 * Set retries-value for setup confirmation check.
 */
+ (NSNumber *) newDeviceToServiceConnectionRetries;
+ (void) newDeviceToServiceConnectionRetries: (NSNumber *)newDeviceToServiceConnectionRetries;

/**
 * Set to use slow connection mechanism or not
 */
+ (NSNumber *) slowConnection;
+ (void) slowConnection: (NSNumber *)slowConnection;

/**
 * Send app id to library
 */
+ (NSString *) appId;
+ (void) appId:(NSString *)appId;

/**
 * Current iAML version
 */
+ (NSString *) version;

/**
 * Save current configuration settings to nonvolatile memory.
 */
+ (int) saveCurrentSettings;

/**
 * Read the configuration settings from nonvolatile memory and apply to current settings.
 */
+ (int) loadSavedSettings;

/**
 * Set current configuration settings to default values and save them to nonvolatile memory.
 */
+ (int) saveDefaultSettings;

/**
 * Log Support
 */
+ (NSString *) getLogFilePath;
+ (NSString *) getSupportMailAddress;
+ (NSString *) getLogMailSubjectWithAppId:(NSString *)appId;

/* Not available
 + (NSNumber *)refreshInterval;
 + (void) refreshInterval:(NSNumber *)refreshInterval;
 */
@end

#define AylaLogI(tg, flg, fmrt, ...) [[AylaLogManager sharedManager] log:tg level:AML_LOGGING_LEVEL_INFO flag:flg time:nil fmt:fmrt, ##__VA_ARGS__]
#define AylaLogW(tg, flg, fmrt, ...) [[AylaLogManager sharedManager] log:tg level:AML_LOGGING_LEVEL_WARNING flag:flg time:nil fmt:fmrt, ##__VA_ARGS__]
#define AylaLogE(tg, flg, fmrt, ...) [[AylaLogManager sharedManager] log:tg level:AML_LOGGING_LEVEL_ERROR flag:flg time:nil fmt:fmrt, ##__VA_ARGS__]
#define AylaLogD(tg, flg, fmrt, ...) [[AylaLogManager sharedManager] log:tg level:AML_LOGGING_LEVEL_DEBUG flag:flg time:nil fmt:fmrt, ##__VA_ARGS__]
#define AylaLogV(tg, flg, fmrt, ...) [[AylaLogManager sharedManager] log:tg level:AML_LOGGING_LEVEL_VERBOSE flag:flg time:nil fmt:fmrt, ##__VA_ARGS__]
#define AylaLog(tg, lev, flg, tm, fmt, ...) [[AylaLogManager sharedManager] log:tg level:lev flag:flg time:tm fmt:fmrt, ##__VA_ARGS__]

#define saveToLog(fmrt, ...) [[AylaLogManager sharedManager] logOldFormat:fmrt, ##__VA_ARGS__]
