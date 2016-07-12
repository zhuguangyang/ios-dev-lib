//
//  NSString+AylaNetworks.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/4/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AYLA_EMPTY_STRING @""

@interface NSString (AylaNetworks)

- (BOOL)AYLA_containsString:(NSString *)aString;

- (BOOL)isEmptyString;

- (NSString *)stringByStrippingLeadingZeroes;
@end
