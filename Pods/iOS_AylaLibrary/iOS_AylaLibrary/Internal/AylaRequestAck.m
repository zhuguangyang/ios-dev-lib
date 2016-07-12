//
//  AylaRequestAck.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 1/20/15.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaRequestAck.h"

@implementation AylaRequestAck

- (instancetype)initWithRepeatTime:(NSInteger)repeatTime interval:(NSUInteger)interval
{
    self = [super init];
    if(!self) return nil;
    
    self.repeat = repeatTime;
    self.interval = interval;
    
    return self;
}

- (void)setExecuteBlock:(AylaRequestAckExecuteBlock)executeblock
{
    _executeBlock = executeblock;
}

- (BOOL)executeIfHaveMoreRetries
{
    if(self.repeat -- >0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.executeBlock(self);
        });
        return YES;
    }
    return NO;
}
- (void)execute
{
    self.repeat --;
    self.executeBlock(self);
}

- (void)finish
{
    self.repeat = 0;
    self.executeBlock = nil;
}

@end

NSString * const kAylaRequestAckRepeat = @"repeat";
NSString * const kAylaRequestAckInterval = @"interval";