//
//  AylaResponse.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/8/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaResponse : NSObject<NSCopying>

@property (nonatomic, readonly) NSUInteger  httpStatusCode;

//To be within Library scope
- (id) initWithNSDictionary:(NSDictionary *)dictionary;

@end
