//
//  AylaCacheSupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/30/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaCache(Support)

/**
 * get a cache from storage w/o a unique identifier
 * used to retrieve top level caches like devices and groups
 *
 * @param cacheType - cache type based on AM_CACHE_XXXXX
 * @return
 */
+ (id)   get:(AML_CACHE)cacheType;

/**
 * get a cache from storage
 * used to retrieve device specific caches like properties and LAN config Info
 *
 * @param cacheType - cache type based on AM_CACHE_XXXXX
 * @param uniqueId - unique identifier appended to cache type prefix
 * @return
 */
+ (id)   get:(AML_CACHE)cacheType withIdentifier:(NSString *)uniqueId;

/**
 * save a cache from storage w/o unique name identifier
 * used to save top level caches like devices and groups
 *
 * @param type - one of AM_CACHE_XXXXX
 * @param valueToCache - string data written to storage
 */
+ (BOOL) save:(AML_CACHE)cacheType withObject:(id)values;

/**
 * save a cache from storage w/o unique name identifier
 * used to save device specific level caches like properties and LAN config info
 *
 * @param type - on of AM_CACHE_XXXXX
 * @param uniqueId - appended to type base identifier, typically the device dsn
 * @param valueToCache - string data written to storage
 */
+ (BOOL) save:(AML_CACHE)cacheType withIdentifier:(NSString *)uniqueId andObject:(NSMutableArray *)values;

@end
