//
//  AylaLanCommandEntity.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 3/20/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaLanCommandEntity.h"
#import "AylaLanOperation.h"
#import "AylaDefines_Internal.h"
@implementation AylaLanCommandEntity

@synthesize jsonString = _jsonString;
@synthesize cmdId = _cmdId;
@synthesize baseType = _baseType;

- (instancetype)initWithParams:(int)cmdId jsonString:(NSString *)jsonString type:(int)baseType
{
    self = [super init];
    if(!self) return nil;
    
    _cmdId = cmdId;
    _jsonString = jsonString;
    _baseType = baseType;
    
    return self;
}

- (void)invokeRespBlockWithResponse:(NSDictionary *)resp status:(int)status error:(AylaError *)error onMainQueue:(BOOL)onMainQueue
{
    AylaLanCommandRespBlock block = self.respBlock;
    if(block) {
        if(onMainQueue) {
            AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
            block(self,resp, status, error);
            AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
        }
        else {
            block(self, resp, status, error);
        }
    }
}

- (BOOL)isCancelled
{
    AylaConnectionOperation *operation = self.parentOperation;
    return !operation || operation.isCancelled || operation.isFinished || operation.isTimeout;
}

+ (NSString *)encapsulateLanCommandWithCommandType:(AylaLanCommandType)commandType seqNo:(int)seqNo messageString:(NSString *)messageString
{
    NSMutableString *jsonEnc = [NSMutableString stringWithFormat:@"{\"seq_no\":%d", seqNo];
    switch (commandType) {
            case AYLA_LAN_PROPERTY:
            [jsonEnc appendFormat:@",\"data\":{\"properties\":[%@]}}", messageString];
            break;
            case AYLA_LAN_COMMAND:
            [jsonEnc appendFormat:@",\"data\":{\"cmds\":[%@]}}", messageString];
            break;
            case AYLA_LAN_NODE_PROPERTY:
            [jsonEnc appendFormat:@",\"data\":{\"node_properties\":[%@]}}", messageString];
            break;
        default:
            [jsonEnc appendFormat:@",\"data\":%@}", messageString];
            break;
    }
    return jsonEnc;
}

@end