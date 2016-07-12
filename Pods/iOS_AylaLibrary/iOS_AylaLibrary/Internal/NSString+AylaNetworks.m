//
//  NSString+AylaNetworks.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/4/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "NSString+AylaNetworks.h"

@implementation NSString (AylaNetworks)

- (BOOL)AYLA_containsString:(NSString *)aString
{
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 80000
    return [self containsString:aString];
#else
    return [self rangeOfString:aString].location != NSNotFound;
#endif
}

- (BOOL)isEmptyString
{
    return ([self isKindOfClass:[NSNull class]]) || (self.length == 0);
}

- (NSString *)stringByStrippingLeadingZeroes {
    NSRange range = [self rangeOfString:@"^0*" options:NSRegularExpressionSearch];
    NSString *strippedString = [self stringByReplacingCharactersInRange:range withString:@""];
    
    return strippedString;
}

@end
