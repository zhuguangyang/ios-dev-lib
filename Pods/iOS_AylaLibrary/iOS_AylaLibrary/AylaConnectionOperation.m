//
//  AylaConnectionOperation.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/9/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaConnectionOperation.h"
#import "AylaResponse.h"
#import "AylaError.h"
#import "AylaErrorSupport.h"
#import "AylaSystemUtils.h"
#import "AylaDefines_Internal.h"
@interface AylaConnectionOperation ()

@property (readwrite, getter=isExecuting) BOOL executing;
@property (readwrite, getter=isCancelled) BOOL cancelled;
@property (readwrite, getter=isFinished)  BOOL finished;
@property (readwrite, getter=isTimeout)   BOOL timeout;
@property (readwrite) BOOL isCallbackBlockInvoked;
@property (nonatomic) NSRecursiveLock *lock;

@end

static dispatch_queue_t ayla_connection_operation_queue(){
    static dispatch_queue_t ayla_connection_operation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ayla_connection_operation_queue = dispatch_queue_create("com.aylanetworks.connectionOperationQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    return ayla_connection_operation_queue;
}

@implementation AylaConnectionOperation

@synthesize executing = _executing;
@synthesize cancelled = _cancelled;
@synthesize finished = _finished;
@synthesize timeout = _timeout;

- (instancetype)init
{
    return [self initWithCallback:nil timeoutInterval:0];
}

- (instancetype)initWithCallback:(AylaConnectionOperationCallbackBlock)callbackBlock timeoutInterval:(NSUInteger)timeoutInterval
{
    self = [super init];
    if(!self) return nil;
    
    _timeoutInterval = timeoutInterval;
    _callbackBlock = [callbackBlock copy];
    _lock = [[NSRecursiveLock alloc] init];
    
    return self;
}

- (void)invokeCallbackBlockWithResponse:(AylaResponse *)response responseObj:(id)respObj error:(AylaError *)error switchToMainQueue:(BOOL)switchToMainQueue
{
   AYLA_RUN_ASYNC_ON_QUEUE_BEGIN(ayla_connection_operation_queue(), 0)
    [self.lock lock];
    if(!self.isCallbackBlockInvoked) {
        self.isCallbackBlockInvoked = YES;
        self.finished = YES;
        AylaConnectionOperationCallbackBlock block = self.callbackBlock;
        if(block) {
            if(switchToMainQueue) {
                AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
                block(response, respObj, error);
                AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
            }
            else {
                [self.lock unlock];
                block(response, respObj, error);
                return;
            }
        }
    }
    [self.lock unlock];
    AYLA_RUN_ASYNC_ON_QUEUE_END
}

- (void)invokeCallbackBlockWithResponse:(AylaResponse *)response responseObj:(id)respObj error:(AylaError *)error
{
    [self invokeCallbackBlockWithResponse:response responseObj:respObj error:error switchToMainQueue:YES];
}

- (void)setTimeout:(BOOL)timeout
{
    [self willChangeValueForKey:@"isTimeout"];
    _timeout = timeout;
    [self didChangeValueForKey:@"isTimeout"];
}

- (BOOL)isTimeout
{
    return _timeout;
}

- (void)start
{
    [self.lock lock];
        if(!self.executing && !self.finished && !self.timeout) {
            self.executing = YES;
            
            AYLA_RUN_ASYNC_ON_QUEUE_BEGIN(ayla_connection_operation_queue(), self.timeoutInterval)
            [self timeoutFired];
            AYLA_RUN_ASYNC_ON_QUEUE_END
        }
        else {
            AylaLogW(AYLA_THIS_CLASS, 0, @"Can't start a executing/executed operation");
        }
    [self.lock unlock];
}

- (void)timeoutFired
{
    [self.lock lock];
    if(!self.finished) {
        self.timeout = YES;
        
        AylaError *error = [AylaError new];
        error.errorCode = AML_ERROR_NATIVE_CODE_REQUEST_TIMED_OUT;
        NSError *naErr = [AylaError nativeErrorWithCode:error.errorCode
                                                 domain:AMLErrorDomain
                                               userInfo:@{NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Operation timed out", nil)}];
        error.nativeErrorInfo = naErr;
        [self invokeCallbackBlockWithResponse:nil responseObj:nil error:error];
    }
    [self.lock unlock];
}

- (BOOL)isExecuting
{
    return _executing;
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)cancel
{
    [self.lock lock];
    if(self.isFinished || self.isTimeout) {
        return;
    }
    
    self.cancelled = YES;
    AylaError *error = [AylaError new];
    error.errorCode = AML_ERROR_NATIVE_CODE_REQUEST_CANCELLED;
    NSError *naErr = [AylaError nativeErrorWithCode:error.errorCode
                                             domain:AMLErrorDomain
                                           userInfo:@{NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"User cancelled operation", nil)}];
    error.nativeErrorInfo = naErr;
    [self invokeCallbackBlockWithResponse:nil responseObj:nil error:error];
    [self.lock unlock];
}

- (BOOL)isCancelled
{
    return _cancelled;
}

- (void)setCancelled:(BOOL)cancelled
{
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = cancelled;
    [self didChangeValueForKey:@"isCancelled"];
}

- (BOOL)isFinished
{
    return _finished;
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)addStatusObserver:(NSObject *)observer
{
    [self addObserver:observer forKeyPath:NSStringFromSelector(@selector(isFinished)) options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeStatusObserver:(NSObject *)observer
{
    @try {
        [self removeObserver:observer forKeyPath:NSStringFromSelector(@selector(isFinished))];
    } @catch (NSException *e) {
    }
}

- (NSUInteger)suggestedTimeoutInterval
{
    return AML_CONNECTION_OPERATION_DEFAULT_TIMEOUT;
}

+ (dispatch_queue_t)connectionOperationQueue
{
    return ayla_connection_operation_queue();
}
@end
