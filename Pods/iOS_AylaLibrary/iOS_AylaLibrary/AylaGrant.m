//
//  AylaGrant.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/19/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaGrant.h"

@implementation AylaGrant

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        //{"user_id":1, "start_date_at":"2014-06-17T23:14:33Z", "end_date_at":null, "operation":"write"}
        self.userId = [dictionary objectForKey:attrNameUserId];
        self.shareId = [dictionary objectForKey:attrNameShareId];
        self.operation = [dictionary objectForKey:attrNameOperation];
        self.startDateAt = [dictionary objectForKey:attrNameStartDateAt]!= [NSNull null]?
                           [dictionary objectForKey:attrNameStartDateAt]: nil;
        self.endDateAt = [dictionary objectForKey:attrNameEndDateAt]!= [NSNull null]?
                         [dictionary objectForKey:attrNameEndDateAt]: nil;
        self.role = [dictionary objectForKey:attrNameRole];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"grant - {\n"
            "user_id: %@\n"
            "share_id: %@\n"
            "operation: %@\n"
            "start_date_at: %@\n"
            "end_date_at: %@ }\n"
            , self.userId, self.shareId ,self.operation, self.startDateAt, self.endDateAt];
}

static NSString * const attrNameUserId = @"user_id";
static NSString * const attrNameShareId = @"share_id";
static NSString * const attrNameOperation = @"operation";
static NSString * const attrNameStartDateAt = @"start_date_at";
static NSString * const attrNameEndDateAt = @"end_date_at";
static NSString * const attrNameRole = @"role";
@end
