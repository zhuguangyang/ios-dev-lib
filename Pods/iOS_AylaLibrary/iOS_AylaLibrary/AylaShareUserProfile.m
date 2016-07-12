//
//  AylaShareUserProfile.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/26/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaShareUserProfile.h"

@implementation AylaShareUserProfile

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self && dictionary) {
    
        self.firstName = [dictionary objectForKey:kTextFirstName];
        self.lastName = [dictionary objectForKey:kTextLastName];
        self.email = [dictionary objectForKey:kTextEmail];
    
    }
    return self;
}

static NSString * const kTextFirstName = @"firstname";
static NSString * const kTextLastName = @"lastname";
static NSString * const kTextEmail = @"email";
@end
