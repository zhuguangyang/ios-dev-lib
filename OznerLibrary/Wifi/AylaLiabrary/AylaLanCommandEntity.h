//
//  AylaLanCommandEntity.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 3/20/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaLanModule.h"

typedef NS_ENUM(uint8_t, AylaLanCommandType) {
    AYLA_LAN_UNDEFINED,
    AYLA_LAN_COMMAND,
    AYLA_LAN_PROPERTY,
    AYLA_LAN_NODE_PROPERTY
};

@class AylaError;
@class AylaLanOperation;

typedef void (^AylaLanCommandRespBlock)(AylaLanCommandEntity *command, NSDictionary *resp, int status, AylaError *error);

@interface AylaLanCommandEntity : NSObject
@property (nonatomic, copy) NSString *jsonString;
@property (nonatomic, assign)       int cmdId;
@property (nonatomic, assign)       AylaLanCommandType baseType;
@property (nonatomic, strong)       AylaLanCommandRespBlock respBlock;
@property (nonatomic, weak)         AylaLanOperation *parentOperation;
@property (nonatomic, assign)       NSInteger tag;

- (instancetype)initWithParams:(int)cmdId jsonString:(NSString*)jsonString type:(int) baseType;
- (void)invokeRespBlockWithResponse:(NSDictionary *)resp status:(int)status error:(AylaError *)error onMainQueue:(BOOL)onMainQueue;
- (BOOL)isCancelled;

+ (NSString *)encapsulateLanCommandWithCommandType:(AylaLanCommandType)commandType seqNo:(int)seqNo messageString:(NSString *)messageString;

@end