//
//  AylaArrayQueue.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/14/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaArrayQueue.h"
#import "AylaDefines_Internal.h"

static char * const dispatchQueueId = "com.aylanetworks.arrayqueue.dispatchQueue";

@interface AylaArrayQueue () {
    dispatch_queue_t _dispatchQueue;
}

@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation AylaArrayQueue

+ (instancetype)queue
{
    AylaArrayQueue *queue = [[AylaArrayQueue alloc] initWithArray:nil];
    return queue;
}

- (instancetype)init
{
    self = [super init];
    if(!self) return nil;
    
    _array = [NSMutableArray array];
    _dispatchQueue = dispatch_queue_create(dispatchQueueId, DISPATCH_QUEUE_CONCURRENT);
    
    return self;
}

- (instancetype)initWithArray:(NSArray *)array
{
    self = [super init];
    if(!self) return nil;
    
    _array = [[NSMutableArray alloc] initWithArray:array?:@[]];
    _dispatchQueue = dispatch_queue_create(dispatchQueueId, DISPATCH_QUEUE_CONCURRENT);

    return self;
}

- (NSArray *)allObjects
{
    return [NSArray arrayWithArray:_array];
}

- (NSArray *)allObjects_sync
{
    __block NSArray *array = nil;
    dispatch_sync(_dispatchQueue, ^{
        array = [self allObjects];
    });
    return array;
}

- (NSInteger)countOfObjects
{
    return  [_array count];
}

- (void)enQueue:(id)object
{
    AYLAssert(object != nil,  @"enqueue obj can't be nil.");
    dispatch_barrier_async(_dispatchQueue, ^{
        [_array addObject:object];
    });
}

- (void)enQueueFromArray:(NSArray *)array
{
    AYLAssert(array != nil, @"enqueue array can't be nil.");
    dispatch_barrier_async(_dispatchQueue, ^{
        [_array addObjectsFromArray:array];
    });
}

- (id)deQueue
{
    __block id object = nil;

    dispatch_sync(_dispatchQueue, ^{
        if(_array.count > 0) {
            object = _array[0];
            [_array removeObjectAtIndex:0];
        }
    });

    return object;
}

- (id)nextInQueue
{
    __block id object = nil;
    
    dispatch_sync(_dispatchQueue, ^{
        if(_array.count > 0) {
            object = _array[0];
        }
    });
    
    return object;
}

- (id)lastQueued
{
    __block id object = nil;
    dispatch_sync(_dispatchQueue, ^{
        object = [_array lastObject];
    });

    return object;
}

- (void)removeObject:(id)object
{
    NSAssert(object != nil, @"to-be-removed obj can't be nil.");
    dispatch_barrier_async(_dispatchQueue, ^{
        [_array removeObject:object];
    });
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    dispatch_barrier_async(_dispatchQueue, ^{
        [_array removeObjectAtIndex:index];
    });
}

- (void)cleanAll
{
    dispatch_barrier_async(_dispatchQueue, ^{
        [_array removeAllObjects];
    });
}

@end
