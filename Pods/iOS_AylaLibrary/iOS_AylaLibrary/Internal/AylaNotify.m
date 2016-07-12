//
//  AylaNotify.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/11/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNotify.h"
#import "AylaNetworks.h"

#define DEFAULT_CODE_DESCRIPTION_400 @"The request could not be completed."
#define DEFAULT_CODE_DESCRIPTION_401 @"The request has been refused for failure of authentication."
#define DEFAULT_CODE_DESCRIPTION_404 @"Some information can not be found for this request."
#define DEFAULT_CODE_DESCRIPTION_412 @"The precondition given for this request evaluated to false."

@interface AylaNotify ()

@property (readwrite, nonatomic) NSString *key;
@property (readwrite, nonatomic) id value;

@end

@implementation AylaNotify

static void (^notifyHandle)(NSDictionary *) = nil;
static unsigned int notifyOutstandingCounter = 0;

+ (void)register:(void (^)(NSDictionary *))handle
{
    notifyHandle = handle;
    notifyOutstandingCounter = 0;
}

+ (void)returnNotify:(NSDictionary *)resp
{
    if(notifyHandle!= nil){
        if(resp == nil){
            NSNumber *state = [NSNumber numberWithInt:200];
            NSDictionary *msg = [[NSDictionary alloc] initWithObjectsAndKeys:state, @"statusCode", nil];
            notifyHandle(msg);
        }
        else
            notifyHandle(resp);
    }
}

+ (int)notifyOutstandingCounter
{
    return notifyOutstandingCounter;
}

+ (void)setNotifyOutstandingCounter:(int)_notifyOutstandingCounter
{
    notifyOutstandingCounter = _notifyOutstandingCounter >= 0? _notifyOutstandingCounter :0;
}

+ (NSString *)codeDescription:(NSUInteger)code
{
    switch (code) {
        case 400:
            return DEFAULT_CODE_DESCRIPTION_400;
        case 401:
            return DEFAULT_CODE_DESCRIPTION_401;
        case 404:
            return DEFAULT_CODE_DESCRIPTION_404;
        case 412:
            return DEFAULT_CODE_DESCRIPTION_412;
        default:
            return DEFAULT_CODE_DESCRIPTION_400;
    }
}

+ (NSDictionary *)initNotifyDictionaryWithType:(NSString *)type dsn:(NSString *)dsn status:(NSUInteger)statusCode
                               description:(NSString *)description values:(NSArray *)propArray
{
    return [AylaNotify initNotifyDictionaryWithType:type dsn:dsn status:statusCode description:description key:@"properties" values:propArray];
}

+ (NSDictionary *)initNotifyDictionaryWithType:(NSString *)type dsn:(NSString *)dsn status:(NSUInteger)statusCode
                                   description:(NSString *)description key:(NSString *)key values:(NSArray *)values
{
    if(statusCode>=200 && statusCode<300) { //success
        if([type isEqualToString:AML_NOTIFY_TYPE_PROPERTY] ||
           [type isEqualToString:AML_NOTIFY_TYPE_NODE])
            return [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", dsn?dsn:@"", @"dsn", [NSNumber numberWithUnsignedInteger:statusCode], @"statusCode", values, key, nil];
        return [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", dsn?dsn:@"", @"dsn", [NSNumber numberWithUnsignedInteger:statusCode], @"statusCode", nil];
    }
    
    // failure
    return [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", dsn?dsn:@"", @"dsn", [NSNumber numberWithUnsignedInteger:statusCode], @"statusCode", description?description:[AylaNotify codeDescription:statusCode], @"description", nil];
}


+ (NSDictionary *)initNotifyDictionaryWithType:(NSString *)type dsn:(NSString *)dsn status:(NSUInteger)statusCode code:(NSUInteger)code
                                   description:(NSString *)description key:(NSString *)key values:(NSArray *)values
{
    if(statusCode>=200 && statusCode<300) { //success
        if([type isEqualToString:AML_NOTIFY_TYPE_PROPERTY] ||
           [type isEqualToString:AML_NOTIFY_TYPE_NODE])
            return [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", dsn?dsn:@"", @"dsn", [NSNumber numberWithUnsignedInteger:statusCode], @"statusCode", values, key, nil];
        return [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", dsn?dsn:@"", @"dsn", [NSNumber numberWithUnsignedInteger:statusCode], @"statusCode", nil];
    }
    
    // failure
    return [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", dsn?dsn:@"", @"dsn", [NSNumber numberWithUnsignedInteger:statusCode], @"statusCode", @(code), @"code", description?description:[AylaNotify codeDescription:statusCode], @"description", nil];
}


@end
