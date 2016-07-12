//
//  AylaCache.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/29/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Overview
 
 This class controls library caching. One important difference from traditional
 caching is that some caching is required for LAN Mode Enablement (LME) to function.
 Therefore, if caching is totally disabled, and there is no service reachability,
 direct communication with Ayla devices will not be possible. Therefore, disabling
 caching is not recommended, but is included for completeness. Caching is enabled
 by default.
 
 Uses
 
 Caching allows for devices and properties to be saved so they are available when
 service connectivity is not present. The typical use case here is WLAN sign-in
 (device access w/o service authentication).
 
 If present, cached values are also used when AylaSystemUtils.slowConnection equals
 AylaNetworks.YES. If no cached values have been saved, then the values will be
 retrieved from the service. Think of slowConnection as a preference, but not a
 requirement, to used cached values.
 
 Indications
 
 When cached values are return in getDevices() and getProperties() the return code
 is set to 203. This allows the application designer how to handle cached values.
*/
typedef
enum {
    AML_CACHE_DEVICE        = 0x01,
    AML_CACHE_PROPERTY      = 0x02,
    AML_CACHE_LAN_CONFIG    = 0x04,
    AML_CACHE_SETUP         = 0x08,
    AML_CACHE_GROUP         = 0x10,
    AML_CACHE_NODE          = 0x20,
    AML_CACHE_ALL           = 0xFF
} AML_CACHE;

@interface AylaCache : NSObject


+ (BOOL) cachingEnabled;

/**
 * Determine if a particular cache(s) is/are enabled
 * @param cacheToCheck - bit mask based on AML_CACHE_XXXXX
 * @return true if the caches to check are enabled
 */
+ (BOOL) cachingEnabled:(NSInteger)selection;

/**
 * @warning - enabling/disabling individual caches may lead to unexpected behavior, consider clearCache() instead
 * Enable cache(s) based on AML_CACHE_XXXXX
 * @param cachestoSet
 */
+ (void) enable:(NSInteger)cachesToSet;

/**
 * @warning - disabling/enabling individual caches may lead to unexpected behavior, consider clearCache() instead
 * Disable cache(s) based on AML_CACHE_XXXXX
 * @param cachesToDisable
 */
+ (void) disable:(NSInteger)cachesToDisable;

/**
 * Clear all caches
 */
+ (void) clearAll;

/**
 * Clear caches based on AML_CACHE_XXXXX
 * @param cachesToClear
 */
+ (void) clear:(NSInteger)cachesToClear;

/**
 * Clear caches based on AML_CACHE_XXXXX
 * @param cachesToClear
 * @param params to specify what to be cleaned
 * @warning currently only support AML_CACHE_PROPERTY
 */
+ (void) clear:(NSInteger)cachesToClear withParams:(NSDictionary *)params;

/**
 * @return caches bit mask based on AML_CACHE_XXXXX
 */
+ (NSInteger) caches;

@end

extern NSString * const kAylaCacheParamDeviceDsn;
