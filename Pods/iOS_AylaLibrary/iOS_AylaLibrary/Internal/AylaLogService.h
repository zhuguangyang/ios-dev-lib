//
//  AylaLogService.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 6/24/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Log : NSObject
@property (nonatomic, copy) NSNumber *time;   // Time in seconds since 1970-01-01
@property (nonatomic, copy) NSString *text;   // The data to be logged by the service, required
@property (nonatomic, copy) NSString *level;  // the severity level for this log, required
@property (nonatomic, copy) NSString *mod;    // The module/area this log pertains to, required
@end


@interface AylaLogService : NSObject
/**
 * Send a log message to the service.
 * Queues log message, best effort, no callback, non-persistent
 *
 * @param callParams 		    // log parameters queued for the service, if null, nothing is queued
 * @param delayedExecution	    // if true, send the next log in the queue, if false, just queue the log parameters
 **/
+ (void) sendLogServiceMessage:(NSDictionary *)callParams withDelay:(Boolean)delayedExecution;
@end
