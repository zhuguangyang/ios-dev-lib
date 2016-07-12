//
//  AylaConnectionOperationSupport.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/18/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "AylaConnectionOperation.h"
#import "AylaHTTPOperation.h"

@interface AylaConnectionOperation(Support)

/** Connection operation type */
@property (nonatomic, assign, readwrite)   AylaConnectionOperationType type;
@property (nonatomic, assign)   NSUInteger timeoutInterval;
@property (nonatomic) NSRecursiveLock *lock;

- (void)timeoutFired;
- (instancetype)initWithCallback:(AylaConnectionOperationCallbackBlock)callbackBlock timeoutInterval:(NSUInteger)timeoutInterval;
- (void)invokeCallbackBlockWithResponse:(AylaResponse *)response responseObj:(id)respObj error:(AylaError *)error;
- (void)invokeCallbackBlockWithResponse:(AylaResponse *)response responseObj:(id)respObj error:(AylaError *)error switchToMainQueue:(BOOL)switchToMainQueue;
- (void)addStatusObserver:(NSObject *)observer;
- (void)removeStatusObserver:(NSObject *)observer;

- (void)setExecuting:(BOOL)executing;
- (void)setCancelled:(BOOL)cancelled;
- (void)setFinished:(BOOL)finished;
- (void)setTimeout:(BOOL)timeout;

// Get connection operation queue
+ (dispatch_queue_t)connectionOperationQueue;

@end

@interface AylaHTTPOperation (Support)

- (void)setAssignedOperationQueue:(NSOperationQueue *)queue;

@end
