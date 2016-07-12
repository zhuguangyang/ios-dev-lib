//
//  AylaPingHelper.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/27/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimplePing.h"

@interface AylaPingHelper : NSObject <SimplePingDelegate>
@property (nonatomic, retain) SimplePing *pinger;

- (void) pingWithHostAddress: (NSString *)ip delay:(int)delay
               resultBlock: (void (^)(bool))block;
- (void) pingWithHostName:(NSString *)host delay:(int)delay
             resultBlock: (void (^)(bool))block;
@end
