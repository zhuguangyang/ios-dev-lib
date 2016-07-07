//
//  AylaLog.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/23/15.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint16_t, AML_LOGGING_LEVEL) {
    AML_LOGGING_LEVEL_ERROR   = 1 << 0,
    AML_LOGGING_LEVEL_WARNING = 1 << 1,
    AML_LOGGING_LEVEL_INFO    = 1 << 2,
    AML_LOGGING_LEVEL_DEBUG   = 1 << 3,
    AML_LOGGING_LEVEL_VERBOSE = 1 << 4
};

NS_ASSUME_NONNULL_BEGIN

@class AylaLogMessage;

/**
 *  The 'AylaLoggerProtocol' procotol is adopted by an object which will be used as application loggers in AylaLogManager.
 */
@protocol AylaLoggerProtocol <NSObject>

/**
 *  This methond will be called whenever a new log arrives.
 */
- (void)logMessage:(AylaLogMessage *)message;

@end

/**
 *  An AylaLogMessage object is a representation of a log message.
 */
@interface AylaLogMessage : NSObject

/** Message tag */
@property (nonatomic, readonly) NSString *tag;

/** Message flag */
@property (nonatomic, readonly, assign) NSInteger flag;

/** Message logging level */
@property (nonatomic, readonly, assign) AML_LOGGING_LEVEL level;

/** Message timestamp */
@property (nonatomic, readonly) NSDate *time;

/** Message content */
@property (nonatomic, readonly) NSString *message;

/** If message follows old format */
@property (nonatomic, readonly, assign) BOOL oldFormat;

@end

NS_ASSUME_NONNULL_END