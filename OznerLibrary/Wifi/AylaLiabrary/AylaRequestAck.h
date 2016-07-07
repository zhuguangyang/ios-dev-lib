//
//  AylaRequestAck.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 1/20/15.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AylaRequestAck;
typedef void(^AylaRequestAckExecuteBlock)(AylaRequestAck *ack);
@interface AylaRequestAck : NSObject

@property (nonatomic, assign) NSUInteger interval;
@property (nonatomic, assign) NSInteger repeat;
@property (nonatomic, strong) AylaRequestAckExecuteBlock executeBlock;

- (instancetype)initWithRepeatTime:(NSInteger)repeatTime interval:(NSUInteger)interval;
- (void)setExecuteBlock:(AylaRequestAckExecuteBlock)executeblock;

- (void)execute;
- (BOOL)executeIfHaveMoreRetries;
- (void)finish;

@end

extern NSString * const kAylaRequestAckRepeat;
extern NSString * const kAylaRequestAckInterval;