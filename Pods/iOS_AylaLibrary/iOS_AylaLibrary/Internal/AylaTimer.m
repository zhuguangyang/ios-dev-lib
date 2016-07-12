//
//  AylaTimer.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/12/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaTimer.h"

@interface AylaTimer(){
    int interval;
    bool ticking;
    void (^tickHandle)(NSTimer *timer);
    __weak NSTimer *timer;
    dispatch_semaphore_t timerSemaphore;
}

@end

@implementation AylaTimer

- (int)getInterval
{
    return interval;
}
- (void)setInterval:(int)_interval
{
    interval = _interval;
}
- (BOOL)isTicking
{
    return ticking;
}

- (void)timerFired:(NSTimer *)_timer
{
    tickHandle(_timer);
}

- (void)doInitailize
{
    timerSemaphore = dispatch_semaphore_create(1);
}

-(id) initWithIntervalAndHandle:(int)_interval tickHandle:(void(^)(NSTimer *timer))_tickHandle {
    self = [super init];
    if(self){
        timer = nil;
        interval = _interval;
        tickHandle = _tickHandle;
        [self doInitailize];    
    }
    return self;
}

- (id)initWithInterval:(int)_interval
{
    self = [super init];
    if(self){
        timer = nil;
        interval = _interval;
        tickHandle = nil;
        [self doInitailize];
    }
    return self;
}

- (void)startAfterDelay:(int)delay
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(delay);
        [self start];
    });
}

- (void)start
{
    dispatch_semaphore_wait(timerSemaphore, DISPATCH_TIME_FOREVER);
    if(timer != nil){
        [timer invalidate];
    }
    NSTimer *aTimer = [NSTimer timerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(timerFired:)
                                   userInfo:nil // input
                                    repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:aTimer forMode:NSRunLoopCommonModes];
    timer = aTimer;
    dispatch_semaphore_signal(timerSemaphore);
    ticking = true;
    
}

- (void)stop
{
    if(timer!= nil && [timer isValid]){
        [timer invalidate];
        //timer = nil;
    }
    ticking = false;
}

- (void)dealloc
{
    if(timer != nil){
        [timer invalidate];
    }
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
#else
    dispatch_release(timerSemaphore);
#endif
}
@end
