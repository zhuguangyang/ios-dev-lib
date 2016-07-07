//
//  AylaTimeZone.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/29/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AylaDevice;
@class AylaResponse;
@class AylaError;
@interface AylaTimeZone : NSObject
@property (nonatomic, readwrite, copy) NSString *utcOffset;
@property (nonatomic, readwrite) NSNumber *dst; // Optional. BOOL value which specifies if the location follows DS T
@property (nonatomic, readwrite) NSNumber *dstActive; // Optional. BOOL value which specifies if DST is currenlty active
@property (nonatomic, readwrite) NSString *dstNextChangeDate; // Optional. Next DST state change from active/inactive OR from inactive/active. Format must be yyyy-mm-dd
@property (nonatomic, readwrite) NSString *dstNextChangeTime;
@property (nonatomic, readwrite, copy) NSString *tzId; // Optional. String identifier for the timezone. eg "America/New_York"

+ (NSOperation *) getTimeZoneWithDevice:(AylaDevice *)device
                       success:(void (^)(AylaResponse *response, AylaTimeZone *devTimeZone)) successBlock
                       failure:(void (^)(AylaError *err)) failureBlock;

- (NSOperation *) updateTimeZoneWithDevice:(AylaDevice *)device
                          success:(void (^)(AylaResponse *response, AylaTimeZone *updatedTimeZone))successBlock
                          failure:(void (^)(AylaError *err)) failureBlock;

@end
