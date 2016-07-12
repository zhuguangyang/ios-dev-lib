//
//  AylaLogService.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 6/24/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaLogService.h"
#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaErrorSupport.h"

@implementation Log
@synthesize time = _time;
@synthesize text = _text;
@synthesize level = _level;
@synthesize mod = _mod;
@end


@implementation AylaLogService
static bool isSending = NO;
static NSMutableArray *queuedLogParams = nil;

+ (void)sendLogServiceMessage:(NSDictionary *)callParams withDelay:(Boolean)delayedExecution
{
    if(queuedLogParams == nil) {
        queuedLogParams = [NSMutableArray new];
    }
    
    if (callParams != nil) {
        [AylaLogService enQueueLogs:callParams]; // queue up the service log message
    }
    
    if (!delayedExecution) {
        [AylaLogService sendNextInLogsQueue];	// send any queued log messages to the service
    }
}

+ (void)sendNextInLogsQueue
{
    if (isSending) {
        return;
    }
    if(gblAuthToken == nil || [gblAuthToken isEqualToString:@""]){
        return;
    }
    [self internalSendNextInLogsQueue];
}

+ (void)internalSendNextInLogsQueue
{
    if(queuedLogParams == nil || [queuedLogParams count] == 0){
        isSending = NO;
        return;
    }
    NSDictionary *next = [queuedLogParams objectAtIndex:0];
    [self create:next];
}



+ (void)create:(NSDictionary *)callParams
{
    isSending = YES;
    NSMutableDictionary *errors  = [NSMutableDictionary new];
    if (![callParams objectForKey:@"dsn"]) {
        [errors setObject:@"can't be blank" forKey:@"dsn"];
    }
    if (![callParams objectForKey:@"level"]) {
        [errors setObject:@"can't be blank" forKey:@"level"];
    }
    if (![callParams objectForKey:@"mod"]) {
        [errors setObject:@"can't be blank" forKey:@"mod"];
    }
    if ([errors count]>0) {
        isSending = NO;
        saveToLog(@"%@, %@, %@:%@, %@", @"I", @"LogService", @"Error", errors, @"create");
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setObject:[callParams objectForKey:@"level"] forKey:@"level"];
    [params setObject:[callParams objectForKey:@"mod"] forKey:@"mod"];
 
    
    NSString *text = [callParams objectForKey:@"text"] == nil? @"check": [callParams objectForKey:@"text"];
    [params setObject:text forKey:@"text"];
    NSNumber *time = [params objectForKey:@"time"];
    if(time == nil) {
       NSUInteger timeInSeconds= [[NSDate date] timeIntervalSince1970];
        time  = [NSNumber numberWithInteger: timeInSeconds];
    }
    
    [params setObject:[NSString stringWithFormat:@"%d", (int)time.integerValue] forKey:@"time"];
    NSDictionary *log = [[NSDictionary alloc] initWithObjectsAndKeys:[callParams objectForKey:@"dsn"], @"dsn", params, @"logs", nil];
    NSString *path = @"app/logs.json";
    [[AylaApiClient sharedLogServiceInstance] postPath:path parameters: log
                                             success:^(AylaHTTPOperation *operation, id response) {
                                                 saveToLog(@"%@, %@, %@:%@, %@", @"I", @"LogService", @"success", @"null", @"create");
                                                 [AylaLogService deQueueLogs];
                                                 [AylaLogService internalSendNextInLogsQueue];
                                             }
                                             failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                 isSending = NO;
                                                 saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"E", @"LogService",
                                                           @"httpStatusCode", (long)operation.response.httpStatusCode, @"response", operation.responseObject, @"logService.create");
                                             }
     ];
}

+ (void)enQueueLogs:(NSDictionary *)aLog
{
    [queuedLogParams addObject:[aLog copy]];
}

+ (NSDictionary *)nextInLogsQueue
{
    return [queuedLogParams count]>0? [queuedLogParams objectAtIndex:0]: nil;
}

+ (void)deQueueLogs
{
    if([queuedLogParams count]>0)
       [queuedLogParams removeObjectAtIndex:0];
}
+ (void)clearLogsQueue
{
    [queuedLogParams removeAllObjects];
}

@end
