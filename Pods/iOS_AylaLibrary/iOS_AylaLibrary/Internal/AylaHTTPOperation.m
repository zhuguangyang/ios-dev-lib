//
//  AylaHTTPOperation.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/29/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaHTTPOperation.h"
#import "AylaDefines.h"
#import "AylaDefines_Internal.h"
#import <AFNetworking/AFHTTPRequestOperation.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import "AylaConnectionOperationSupport.h"

@interface AylaHTTPOperation ()

@property BOOL isObservingTask;
@property (nonatomic, weak) NSOperationQueue *assignedOperationQueue;

@end

@implementation AylaHTTPOperation

- (instancetype)init
{
    self = [super init];
    if(!self) return nil;
    
    return self;
}

- (instancetype)initWithTask:(id)task
{
    self = [super init];
    if(!self) return nil;
    
    _task = task;
    
    return self;
}

- (void)setTask:(id)task
{
    _task = task;
}

- (void)setAssignedOperationQueue:(NSOperationQueue *)queue
{
    _assignedOperationQueue = queue;
}

- (void)start
{
    [self.lock lock];
    
    if(!self.task || ![self _startObservingTask]) {
        [self.lock unlock];
        return;
    }
    
    NSOperationQueue *queue = self.assignedOperationQueue;
    if(queue && [self.task isKindOfClass:[NSOperation class]]) {
        [queue addOperation:self.task];
    }
    else {
        [self.task resume];
    }
    
    [self.lock unlock];
}

- (void)cancel
{
    [self.lock lock];
    
    [self.task cancel];
    
    [self.lock unlock];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary AYLA_GENERIC(NSString *,id) *)change context:(void *)context
{
    if (object == self.task) {
        if([object isKindOfClass:[AFHTTPRequestOperation class]]) {
            if([keyPath isEqualToString:@"isExecuting"]) {
                [self setExecuting:[change[NSKeyValueChangeNewKey] boolValue]];
            }
            else if([keyPath isEqualToString:@"isFinished"]) {
                [self setFinished:[change[NSKeyValueChangeNewKey] boolValue]];
            }
            else if([keyPath isEqualToString:@"isCancelled"]) {
                [self setCancelled:[change[NSKeyValueChangeNewKey] boolValue]];
            }
        }
        else if([object isKindOfClass:[NSURLSessionTask class]]) {
            if([keyPath isEqualToString:@"state"]) {
                switch ([change[NSKeyValueChangeNewKey] integerValue]) {
                    case NSURLSessionTaskStateRunning:
                        [self setExecuting:YES];
                        break;
                    case NSURLSessionTaskStateCanceling:
                        [self setCancelled:YES];
                        break;
                    case NSURLSessionTaskStateCompleted:
                        [self setFinished:YES];
                        if ([change[NSKeyValueChangeNewKey] integerValue] != [change[NSKeyValueChangeOldKey] integerValue]) {
                            [self setExecuting:NO];
                        }
                        break;
                    default:
                        break;
                }
            }
        }
    }
}

- (void)timeoutFired
{
    //Ayla HTTP Operation should not use its own timeout timer.
}

- (BOOL)_startObservingTask
{
    [self.lock lock];
    BOOL re = NO;
    if(!self.isObservingTask) {
        if([self.task isKindOfClass:[AFHTTPRequestOperation class]]) {
            AFHTTPRequestOperation *operation = self.task;
            [operation addObserver:self forKeyPath:@"isExecuting" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
            [operation addObserver:self forKeyPath:@"isCancelled" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
            [operation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
            self.isObservingTask = YES;
            re = YES;
        }
        else if([self.task isKindOfClass:[NSURLSessionTask class]]) {
            NSURLSessionDataTask *task = self.task;
            [task addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
            self.isObservingTask = YES;
            re = YES;
        }
    }
    [self.lock unlock];
    return re;
}

- (void)_stopObservingTask
{
    [self.lock lock];
    if(self.isObservingTask) {
        id task = self.task;
        if([task isKindOfClass:[AFHTTPRequestOperation class]]) {
            [task removeObserver:self forKeyPath:@"isExecuting"];
            [task removeObserver:self forKeyPath:@"isCancelled"];
            [task removeObserver:self forKeyPath:@"isFinished"];
        }
        else if ([task isKindOfClass:[NSURLSessionTask class]]) {
            [task removeObserver:self forKeyPath:@"state"];
        }
        self.isObservingTask = NO;
    }
    [self.lock unlock];
}

- (void)dealloc
{
    [self _stopObservingTask];
}

- (NSUInteger)suggestedTimeoutInterval
{
    return AML_HTTP_OPERATION_DEFAULT_TIMEOUT;
}

@end
