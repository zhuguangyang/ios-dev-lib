//
//  NSObject+AylaNetworks.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/24/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "NSObject+AylaNetworks.h"

@implementation NSObject (AylaNetworks)

- (id)nilIfNull
{
    return self != [NSNull null]? self: nil;
}

- (BOOL)isNumber
{
    return [self isKindOfClass:[NSNumber class]];
}

@end
