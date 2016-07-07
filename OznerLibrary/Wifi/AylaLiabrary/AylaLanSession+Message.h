//
//  AylaLanSession+Message.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/9/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaLanModule.h"

@class AylaLanMessage;
@class AylaMessageResponse;
@interface AylaLanSession (Message)

- (AylaMessageResponse *)invokeOperationForMessage:(AylaLanMessage *)message;

@end
