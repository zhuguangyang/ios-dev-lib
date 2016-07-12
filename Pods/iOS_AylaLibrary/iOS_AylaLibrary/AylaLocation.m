//
//  AylaLocation.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/19/15.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaLocation.h"
#import "AylaSystemUtils.h"
#import "AylaSystemUtilsSupport.h"
@implementation AylaLocation

+ (NSArray * __nonnull)allCountries
{
    NSString * const countryFileName = @"AylaCountryCodes";

    NSError *error;
    NSData *contentsInData = [AylaLocation dataFromFileInBundle:countryFileName error:&error];
    
    if(error || !contentsInData) return @[];

    NSArray *countryArray = [NSJSONSerialization JSONObjectWithData:contentsInData options:0 error:&error];
    if(error) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaLocation", @"err-json", error.debugDescription, @"allCountries");
    }
    
    return countryArray?:@[];
}

+ (NSArray * __nonnull)allTimeZones
{   
    NSString * const tzFileName = @"AylaTimeZones";
    
    NSError *error;
    NSData *contentsInData = [AylaLocation dataFromFileInBundle:tzFileName error:&error];
    
    if(error || !contentsInData) return @[];
    
    NSArray *tzArray = [NSJSONSerialization JSONObjectWithData:contentsInData options:0 error:&error];
    if(error) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaLocation", @"err-json", error.debugDescription, @"allTimeZones");
    }
    
    return tzArray?:@[];
}

+ (NSData *)dataFromFileInBundle:(NSString *)fileName error:(NSError * __autoreleasing *)error
{
    NSString * const AylaLibraryBundleName = @"AylaLibraryBundle";
    NSString *bundlePath =[[NSBundle mainBundle] pathForResource:AylaLibraryBundleName ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *countryFilePath = [bundle pathForResource:fileName ofType:@"json"];
    
    NSData *contentsInData = [NSData dataWithContentsOfFile:countryFilePath options:0 error:error];
    
    if(*error) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaLocation", @"err", [*error description], @"dataFromFileInBundle");
        return nil;
    }

    return contentsInData;
}

@end

NSString * const kAylaLocationParamName = @"name";
NSString * const kAylaLocationParamISOCode = @"iso_code";
NSString * const kAylaLocationParamDialCode = @"dial_code";
NSString * const kAylaLocationParamTimeZoneId = @"tz_id";
