//
//  AylaMessageResponse.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 5/12/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaMessageResponse.h"
#import "AylaResponseSupport.h"
@implementation AylaMessageResponse

+ (instancetype)responseOfMessage:(AylaMessage *)message httpStatusCode:(NSInteger)httpStatusCode
{
    AylaMessageResponse *resp = [AylaMessageResponse new];
    resp.httpStatusCode = httpStatusCode;
    resp.message = message;
    return resp;
}

@end
