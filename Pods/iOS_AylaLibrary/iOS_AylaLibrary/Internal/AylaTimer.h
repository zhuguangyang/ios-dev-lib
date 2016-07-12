//
//  AylaTimer.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/12/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AML_DEFAULT_SESSION_INTERVAL 27

@interface AylaTimer : NSObject

-(int)  getInterval;
-(void) setInterval:(int)interval;
-(BOOL) isTicking;

-(id) initWithIntervalAndHandle:(int)_interval tickHandle:(void(^)(NSTimer *timer))_tickHandle;
-(id) initWithInterval:(int)_interval;

-(void) start;
-(void) startAfterDelay:(int) delay;

-(void) stop;

@end
