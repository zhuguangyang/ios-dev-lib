//
//  AylaArrayQueue.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/14/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaArrayQueue : NSObject

+ (instancetype)queue;
- (instancetype)initWithArray:(NSArray *)array;

- (NSArray *)allObjects;

/**
 * Call in dispatch_queue to sync of all objects.
 */
- (NSArray *)allObjects_sync;
- (NSInteger)countOfObjects;

- (void)enQueue:(id)object;
- (void)enQueueFromArray:(NSArray *)array;

- (id)deQueue;

- (id)nextInQueue;
- (id)lastQueued;

- (void)removeObject:(id)object;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)cleanAll;
@end
