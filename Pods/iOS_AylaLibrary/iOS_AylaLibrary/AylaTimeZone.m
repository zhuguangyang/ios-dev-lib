//
//  AylaTimeZone.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/29/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaTimeZone.h"
#import "AylaNetworks.h"
#import "AFNetworking.h"
#import "AylaApiClient.h"
#import "AylaDeviceSupport.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaErrorSupport.h"

@interface AylaTimeZone ()
@property (nonatomic, readwrite) NSNumber *key;
@end

@implementation AylaTimeZone
@synthesize utcOffset = _utcOffset;
@synthesize dst = _dst;
@synthesize dstActive = _dstActive;
@synthesize dstNextChangeDate = _dstNextChangeDate;
@synthesize dstNextChangeTime = _dstNextChangeTime;
@synthesize tzId = _tzId;
@synthesize key = _key;

+ (NSOperation *) getTimeZoneWithDevice:(AylaDevice *)device
                       success:(void (^)(AylaResponse *response, AylaTimeZone *devTimeZone)) successBlock
                       failure:(void (^)(AylaError *err)) failureBlock
{
    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"devices/", device.key, @"/time_zones.json"];
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"path", path, @"update");
    return [[AylaApiClient sharedDeviceServiceInstance] getPath:path
                                              parameters:nil
                 success:^(AylaHTTPOperation *operation, id responseObject) {
                     saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"key", device.key, @"update.putPath");
                     NSDictionary *respDict = [responseObject objectForKey:@"time_zone"];
                     AylaTimeZone *instance = nil;
                     if(respDict) {
                         instance = [AylaTimeZone new];
                         instance.dst = [respDict objectForKey:@"dst"]!=[NSNull null]? [respDict objectForKey:@"dst"]: nil;
                         instance.dstActive = [respDict objectForKey:@"dst_active"]!=[NSNull null]? [respDict objectForKey:@"dst_active"]: nil;
                         instance.dstNextChangeDate = [respDict objectForKey:@"dst_next_change_date"]!=[NSNull null]? [respDict objectForKey:@"dst_next_change_date"]: nil;
                         instance.dstNextChangeTime = [respDict objectForKey:@"dst_next_change_time"]!=[NSNull null]? [respDict objectForKey:@"dst_next_change_time"]: nil;
                         instance.utcOffset = [respDict objectForKey:@"utc_offset"]!=[NSNull null]? [respDict objectForKey:@"utc_offset"]: nil;
                         instance.key = [respDict objectForKey:@"key"]!=[NSNull null]? [respDict objectForKey:@"key"]: nil;
                         instance.tzId = [respDict objectForKey:@"tz_id"]!=[NSNull null]? [respDict objectForKey:@"tz_id"]: nil;                         
                     }

                     successBlock(operation.response, instance);
                 }
                 failure:^(AylaHTTPOperation *operation, AylaError *error) {
                     saveToLog(@"%@, %@, %@, %@", @"E", @"TimeZone", error.logDescription, @"getTimeZoneWithDevice.getPath");
                     failureBlock(error);
                 }];
}

- (NSOperation *) updateTimeZoneWithDevice:(AylaDevice *)device
                success:(void (^)(AylaResponse *response, AylaTimeZone *updatedTimeZone))successBlock
                failure:(void (^)(AylaError *err)) failureBlock
{
    NSMutableDictionary *dataDict = [NSMutableDictionary new];

    /**
     * if tz_id is set, we will only use tz_id to update
     */
    if(_tzId) {
        if(_tzId) [dataDict setObject:_tzId forKey:@"tz_id"];
    }
    else if(_utcOffset){
        if(_utcOffset) [dataDict setObject:_utcOffset forKey:@"utc_offset"];
        if(_dst) [dataDict setObject:[NSNumber numberWithBool:_dst.boolValue] forKey:@"dst"];
        if(_dstActive) [dataDict setObject:[NSNumber numberWithBool:_dstActive.boolValue] forKey:@"dst_active"];
        if(_dstNextChangeTime) [dataDict setObject:_dstNextChangeTime forKey:@"dst_next_change_time"];
        if(_dstNextChangeDate) [dataDict setObject:_dstNextChangeDate forKey:@"dst_next_change_date"];
        [dataDict setObject:[NSNull null] forKey:@"tz_id"];
        dataDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:dataDict, @"time_zone", nil];
    }
    else {
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.errorInfo = nil; err.nativeErrorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"devices/", device.key, @"/time_zones.json"];
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"path", path, @"update");
    
    void (^_successBlock)(AylaHTTPOperation *operation, id responseObject)
    = ^(AylaHTTPOperation *operation, id responseObject){
        saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"key", device.key, @"update.put/postPath");
        NSDictionary *respDict = [responseObject objectForKey:@"time_zone"];
        AylaTimeZone *instance = self;
        if(respDict) {
            instance.dst = [respDict objectForKey:@"dst"]!=[NSNull null]? [respDict objectForKey:@"dst"]: nil;
            instance.dstActive = [respDict objectForKey:@"dst_active"]!=[NSNull null]? [respDict objectForKey:@"dst_active"]: nil;
            instance.dstNextChangeDate = [respDict objectForKey:@"dst_next_change_date"]!=[NSNull null]? [respDict objectForKey:@"dst_next_change_date"]: nil;
            instance.dstNextChangeTime = [respDict objectForKey:@"dst_next_change_time"]!=[NSNull null]? [respDict objectForKey:@"dst_next_change_time"]: nil;
            instance.utcOffset = [respDict objectForKey:@"utc_offset"]!=[NSNull null]? [respDict objectForKey:@"utc_offset"]: nil;
            instance.key = [respDict objectForKey:@"key"]!=[NSNull null]? [respDict objectForKey:@"key"]: nil;
            instance.tzId = [respDict objectForKey:@"tz_id"]!=[NSNull null]? [respDict objectForKey:@"tz_id"]: nil;
        }

        successBlock(operation.response, instance);
    };
    
    void (^_failureBlock)(AylaHTTPOperation *operation, AylaError *error)
    = ^(AylaHTTPOperation *operation, AylaError *error){
        error.errorCode = AML_USER_INVALID_PARAMETERS;
        saveToLog(@"%@, %@, %@:%ld, %@", @"E", @"TimeZone", @"NSError.code", (long)error.nativeErrorInfo.code, @"update.put/postPath");
        failureBlock(error);
    };
    
    //NSDictionary *send = [[NSDictionary alloc] initWithObjectsAndKeys:dataDict, @"time_zone", nil];
    NSDictionary *send = dataDict;
    if(_tzId) {
       return  [[AylaApiClient sharedDeviceServiceInstance] putPath:path
                                                  parameters:send
                                                     success:_successBlock
                                                     failure:_failureBlock];
    }
    else {
       return  [[AylaApiClient sharedDeviceServiceInstance] postPath:path
                                                  parameters:send
                                                     success:_successBlock
                                                     failure:_failureBlock];
    }
}


@end
