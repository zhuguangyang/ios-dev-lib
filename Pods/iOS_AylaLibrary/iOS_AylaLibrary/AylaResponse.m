//
//  AylaResponse.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/8/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaResponse.h"
#import "AylaResponseSupport.h"
@interface AylaResponse ()
@property (nonatomic, readwrite) NSUInteger httpStatusCode;
@end

@implementation AylaResponse
@synthesize httpStatusCode = _httpStatusCode;

- (id)initWithNSDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        _httpStatusCode = [dictionary objectForKey:[NSNumber numberWithInt:AylaResponseParameterHttpStatusCode]]? 0:[(NSNumber *)[dictionary objectForKey:[NSNumber numberWithInt:AylaResponseParameterHttpStatusCode]] integerValue];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaResponse *_copy = copy;
        _copy.httpStatusCode = self.httpStatusCode;
    }
    return copy;
}

@end
