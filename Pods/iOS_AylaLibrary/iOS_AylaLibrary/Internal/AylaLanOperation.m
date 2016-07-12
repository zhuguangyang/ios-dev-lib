//
//  AylaLanOperation.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/9/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaConnectionOperationSupport.h"
#import "AylaLanOperation.h"
#import "AylaLanCommandEntity.h"
#import "AylaDevice.h"
#import "AylaDeviceSupport.h"
#import "AylaArrayQueue.h"
#import "AylaError.h"
#import "AylaErrorSupport.h"
@interface AylaLanOperation ()

@property (nonatomic, strong) AylaArrayQueue *commandQueue;
@property (nonatomic, weak) AylaDevice *destination;

@end

@implementation AylaLanOperation

@synthesize callbackBlock = _callbackBlock;
@synthesize type = _type;

+ (instancetype)operationWithsubType:(AylaLanOperationType)subType commands:(NSArray *)commands callbackBlock:(AylaConnectionOperationCallbackBlock)callbackBlock
{
    return [[AylaLanOperation alloc] initWithSubType:subType commands:commands callbackBlock:callbackBlock];
}

- (instancetype)initWithSubType:(AylaLanOperationType)subType commands:(NSArray *)commands callbackBlock:(AylaConnectionOperationCallbackBlock)callbackBlock
{
    self = [super init];
    if(!self) return nil;
    
    _type = AylaConnectionOperationTypeLan;
    _subType = subType;
    _commandQueue = [AylaArrayQueue queue];
    _callbackBlock = callbackBlock;
    [self setCommands:commands];
    
    return self;
}

- (BOOL)startOnSession:(AylaLanSession *)session
{
    if(!session || session.sessionState != UP) {
        return NO;
    }
    
    [session pushOperation:self];
    
    return YES;
}

- (NSArray *)commands
{
    return [_commandQueue allObjects_sync];
}

- (void)setCommands:(NSArray *)commands
{
    for (AylaLanCommandEntity *command in commands) {
        command.parentOperation = self;
    }
    _commandQueue = [[AylaArrayQueue alloc] initWithArray:commands];
}

- (NSUInteger)suggestedTimeoutInterval
{
    return AML_LAN_OPERATION_DEFAULT_TIMEOUT + (_commandQueue.countOfObjects >> 2);
}

@end