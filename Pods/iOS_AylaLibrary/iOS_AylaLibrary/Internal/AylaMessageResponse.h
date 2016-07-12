//
//  AylaMessageResponse.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 5/12/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaResponse.h"

@class AylaMessage;
@interface AylaMessageResponse : AylaResponse

@property (strong, nonatomic) id responseObject;
@property (strong, nonatomic) NSString *responseString;

@property (strong, nonatomic) AylaMessage *message;

+ (instancetype)responseOfMessage:(AylaMessage *)message httpStatusCode:(NSInteger)httpStatusCode;

@end
