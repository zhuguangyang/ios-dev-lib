//
//  AylaLanSession+Message.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/9/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaLanSession+Message.h"
#import "AylaLanMessage.h"
#import "AylaMessageResponse.h"
#import "AylaError.h"
#import "AylaErrorSupport.h"
#import "AylaLanCommandEntity.h"
#import "AylaDefines_Internal.h"
@implementation AylaLanSession (Message)

- (AylaMessageResponse *)invokeOperationForMessage:(AylaLanMessage *)message
{
    NSString *cmdIdInStr = [@(message.cmdId) stringValue];
    AylaLanCommandEntity *command = [self getOutstandingCommand:cmdIdInStr];
    NSUInteger status = message.status;
    
    if(!command){
        saveToLog(@"%@, %@, %@, %ld, %@", @"I", @"lanSession+M", @"noReturnBlockForCommandResp-Discard", (long)status, @"invokeOperationForMessage");
    }
    
    [self removeOutstandingCommand:cmdIdInStr];
    [command invokeRespBlockWithResponse:message.contents status:(int)status error:nil onMainQueue:YES];
    
    //Lan Command Resp will always return 2xx to module.
    AylaMessageResponse *resp = [AylaMessageResponse responseOfMessage:message httpStatusCode:AML_ERROR_ASYNC_OK];
    return resp;
}

@end
