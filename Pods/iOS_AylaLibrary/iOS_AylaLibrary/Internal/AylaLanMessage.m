//
//  AylaLanMessage.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 5/12/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaLanMessage.h"
#import "AylaLanModule.h"
#import "NSString+AylaNetworks.h"

NSString * const AylaLanPathDatapoint = @"property/datapoint.json";
NSString * const AylaLanPathConnStatus = @"/conn_status.json";
NSString * const AylaLanPathCommands = @"/commands.json";
NSString * const AylaLanPathDatapointAck = @"property/datapoint/ack.json";

NSString * const AylaLanPathNodePrefix = @"node/";
NSString * const AylaLanPathLocalLanPrefix = @"local_lan/";

@implementation AylaLanMessage

- (instancetype)initWithMethod:(AylaMessageMethod)method urlString:(NSString *)urlString contents:(id)contents contextHandler:(AylaLanSession *)session
{
    self = [super init];
    if(!self) return nil;
    
    self.source = AylaMessageSourceLAN;
    self.method = method;
    self.urlString = urlString;
    self.contents = contents;
    self.urlParams = [AylaLanMessage parseParamsWithUrlString:urlString];
    [self setTypeWithUrlPath:urlString];
    self.contextHandler = session;
    
    return self;
}

- (void)setTypeWithUrlPath:(NSString *)path
{
    self.type = AylaMessageTypeUnknown;
    if(self.method == AylaMessageMethodPOST) {
        if([path AYLA_containsString:AylaLanPathDatapoint]) {
            self.type = AylaMessageTypeDatapointUpdate;
        }
        else if([path AYLA_containsString:AylaLanPathConnStatus]) {
            self.type = AylaMessageTypeConnStatusUpdate;
        }
        else if([path AYLA_containsString:AylaLanPathDatapointAck]) {
            self.type = AylaMessageTypeDatapointAck;
        }
    } else
    if (self.method == AylaMessageMethodGET) {
        if([path AYLA_containsString:AylaLanPathCommands]) {
            self.type = AylaMessageTypeCommands;
        }
    }
}

- (NSUInteger)cmdId
{
   return [[self.urlParams objectForKey:kAylaLanMessageParamCmdId] integerValue];
}
- (NSInteger)status
{
    return [[self.urlParams objectForKey:kAylaLanMessageParamStatus] integerValue];
}

- (BOOL)isCallback
{
    return [self.urlParams objectForKey:kAylaLanMessageParamCmdId]? YES: NO;
}

+ (NSDictionary *)parseParamsWithUrlString:(NSString *)urlString
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    NSArray *components = [urlString componentsSeparatedByString:@"?"];
    if(components.count > 0) {
        [dictionary setObject:components.firstObject forKey:@"kBasicUrl"];
        
        if(components.count == 1) {
            return dictionary;
        }
        
        NSString *paramsString = components.lastObject;
        NSArray *paramsEquators = [paramsString componentsSeparatedByString:@"&"];
        [paramsEquators enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSArray *kvPair = [(NSString *)obj componentsSeparatedByString:@"="];
            if(kvPair.count == 2) {
                [dictionary setObject:kvPair[1] forKey:kvPair[0]];
            }
        }];
    }
    return dictionary;
};

@end

NSString * const kAylaLanMessageParamCmdId = @"cmd_id";
NSString * const kAylaLanMessageParamStatus = @"status";
NSString * const kAylaLanMessageParamId = @"id";

NSString * const kAylaLanMessageParamData = @"data";
NSString * const kAylaLanMessageParamName = @"name";
NSString * const kAylaLanMessageParamValue = @"value";

//-------------------------------------------------------------
/**
 *  Lan Message Content Formats
 */
/*
 ## AylaMessageTypeDatapointUpdate
 {"data":{"name":"Blue_button","value":1}}
*/