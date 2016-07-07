//
//  AylaLocation.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/19/15.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Country parameters
 */
extern NSString * const kAylaLocationParamName;
extern NSString * const kAylaLocationParamISOCode;
extern NSString * const kAylaLocationParamDialCode;

/**
 *  Time Zone parameters
 */
extern NSString * const kAylaLocationParamTimeZoneId;

@interface AylaLocation : NSObject

/**
 *  Get an array of countries.
 *  Each country will be retuned in a dictionary like
 *  @code
 *   {
 *       kAylaLocationParamName : "United States",
 *       kAylaLocationParamDialCode: "+1",
 *       kAylaLocationParamISOCode: "US"
 *    }
 *  @endcode
 *  @note This api will read country list from a json file. Avoid to call this method from main thread if high UI performance must be maintained. An empty array will be returned if country list can not be parsed from the file.
 */
+ (NSArray *)allCountries;

/**
 *  Get an array of time zones which could be recognized by library.
 *  Each country will be retuned in a dictionary like
 *  @code
 *  {
 *      kAylaLocationParamTimeZoneId: "America/Los_Angeles"
 *  }
 *  @endcode
 *  @note This api will read time zone list from a json file. Avoid to call this method from main thread if high UI performance must be maintained. An empty array will be returned if time zone list can not be parsed from the file.
 */
+ (NSArray *)allTimeZones;

@end

NS_ASSUME_NONNULL_END