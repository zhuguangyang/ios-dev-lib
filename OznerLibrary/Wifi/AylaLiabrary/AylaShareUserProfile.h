//
//  AylaShareUserProfile.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/26/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaShareUserProfile : NSObject

@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *email;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
