//
//  AylaLanOperation.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/9/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaConnectionOperation.h"

#define AML_LAN_OPERATION_DEFAULT_TIMEOUT 20

typedef NS_ENUM(uint8_t, AylaLanOperationType) {
    AylaLanOperationTypeCommand,
    AylaLanOperationTypeProperty
};

@class AylaLanSession;
@interface AylaLanOperation : AylaConnectionOperation

@property (nonatomic, assign) AylaLanOperationType subType;

+ (instancetype)operationWithsubType:(AylaLanOperationType)subType commands:(NSArray *)commands callbackBlock:(AylaConnectionOperationCallbackBlock)callbackBlock;
- (instancetype)initWithSubType:(AylaLanOperationType)subType commands:(NSArray *)commands callbackBlock:(AylaConnectionOperationCallbackBlock)callbackBlock;

- (NSArray *)commands;

//@note Each call will trigger to allocate a new commands queue
- (void)setCommands:(NSArray *)commands;

- (BOOL)startOnSession:(AylaLanSession *)session;

@end
