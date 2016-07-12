//
//  AylaLogger.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/28/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaLogger.h"


@interface AylaLogger () {
@protected
    dispatch_queue_t _queue;
}

@property (nonatomic, readwrite, strong) AylaLogFormatter *formatter;
@property (nonatomic, readwrite, copy) AylaLoggerFilterBlock filterBlock;

@end

@implementation AylaLogger

+ (instancetype)loggerWithFilterBlock:(AylaLoggerFilterBlock)filterBlock formatter:(AylaLogFormatter *)formatter
{
    return [[self alloc] initWithFilterBlock:filterBlock formatter:formatter];
}

+ (instancetype)logger
{
    return [[self alloc] init];
}

- (instancetype)init
{
    return [self initWithFilterBlock:nil formatter:nil];
}

- (instancetype)initWithFilterBlock:(AylaLoggerFilterBlock)filterBlock formatter:(AylaLogFormatter *)formatter
{
    self = [super init];
    if(!self) return nil;
    
    self.filterBlock = filterBlock;
    
    const char *queue_label = NULL;
    _queue = dispatch_queue_create(queue_label, DISPATCH_QUEUE_SERIAL);
    
    self.formatter = formatter?:[AylaLogFormatter defaultLogFormatter];
    
    return self;
}

@end


@interface AylaFileLogger () {
    NSFileHandle *_logFileHandle;
    NSString *_logFilePath;
}

@end

@implementation AylaFileLogger

static NSString * const AylaLibLogFileName = @"aml_log";
//static const int AylaLibLogFileMaximumNum = 4;
static const int AylaLibLogFileMaximumSize = 256 * 1000;

- (void)logMessage:(AylaLogMessage *)message
{
    dispatch_async(_queue, ^{
        [self processMessage:message];
    });
}

- (void)processMessage:(AylaLogMessage *)message
{
    if([self acceptMessage:message]) {
        if([self validateLogFiles]) {
            NSString *msg = [self.formatter formattedLogMessage:message];
            [_logFileHandle writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
            [_logFileHandle synchronizeFile];
        }
    }
}

- (BOOL)validateLogFiles
{
    if(_logFileHandle) {
        return YES;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [[paths objectAtIndex:0] stringByAppendingString:@"/Ayla"];
    
    _logFilePath = [documentsDirectory stringByAppendingPathComponent:[AylaLibLogFileName stringByAppendingString:@".txt"]];
    //NSLog(@"%@, %@, %@:%@, %@", @"I", @"FileLogger", @"_pLogFilePath", _pLogFilePath, @"Filelogger.init");
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_logFilePath]) {
        [fileManager createFileAtPath:_logFilePath
                             contents:nil
                           attributes:nil];
    }
    else{
        NSDictionary *fileAttrs = [fileManager attributesOfItemAtPath:_logFilePath error:nil];
        unsigned long long logSize = [fileAttrs fileSize];
        if(logSize > AylaLibLogFileMaximumSize){ // // Once file size is over 256k, add a new aml_log file and remove the oldest one
            NSString *filePathLog3 = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%d.txt", AylaLibLogFileName, 3]];
            if ([fileManager fileExistsAtPath:filePathLog3]) {
                [fileManager removeItemAtPath:filePathLog3 error:nil];
            }
            NSString *filePathLog2 = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%d.txt", AylaLibLogFileName, 2]];
            if ([fileManager fileExistsAtPath:filePathLog2]) {
                [fileManager moveItemAtPath:filePathLog2 toPath:filePathLog3 error:nil];
            }
            NSString *filePathLog1 = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%d.txt", AylaLibLogFileName, 1]];
            if ([fileManager fileExistsAtPath:filePathLog1]) {
                [fileManager moveItemAtPath:filePathLog1 toPath:filePathLog2 error:nil];
            }
            [fileManager moveItemAtPath:_logFilePath toPath:filePathLog1 error:nil];
            [fileManager createFileAtPath:_logFilePath
                                 contents:nil
                               attributes:nil];
        }
    }
    
    _logFileHandle = [NSFileHandle fileHandleForWritingAtPath:_logFilePath];
    if (_logFileHandle != nil) {
        [_logFileHandle seekToEndOfFile];
        return YES;
    } else {
        NSLog(@"E, FileLogger, logfile:nil, Filelogger init failed to get log file handle");
        return NO;
    }
}

- (BOOL)acceptMessage:(AylaLogMessage *)message
{
    AylaLoggerFilterBlock filter = self.filterBlock;
    if(filter) {
        return filter(message);
    }
    return YES;
}

- (void)dealloc {
    [_logFileHandle synchronizeFile];
    [_logFileHandle closeFile];
}

@end


@implementation AylaConsoleLogger

- (void)logMessage:(AylaLogMessage *)message
{
    if([self acceptMessage:message]) {
        NSLog(@"%@", [self.formatter formattedLogMessage:message]);
    }
}

- (BOOL)acceptMessage:(AylaLogMessage *)message
{
    AylaLoggerFilterBlock filter = self.filterBlock;
    if(filter) {
        return filter(message);
    }
    return YES;
}

@end

@implementation AylaLogFormatter

+ (instancetype)defaultLogFormatter
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if(!self) return nil;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    _timeFormatter = formatter;
    
    return self;
}

- (NSString *)formattedLogMessage:(AylaLogMessage *)message
{
    NSString *level = [AylaLogFormatter stringFromLoggingLevel:message.level];
    NSString *time = [_timeFormatter stringFromDate:message.time];
    return message.oldFormat? [NSString stringWithFormat:@"%@, %@\n", time, message.message]:
    [NSString stringWithFormat:@"%@, %@, %@, %@\n", time, level, message.tag, message.message];
}

//------------------------ Helpful methods -----------------------
+ (NSString *)stringFromLoggingLevel:(AML_LOGGING_LEVEL)level
{
    NSString *levelStr = nil;
    switch (level) {
        case AML_LOGGING_LEVEL_INFO:
            levelStr = @"I";
            break;
        case AML_LOGGING_LEVEL_ERROR:
            levelStr = @"E";
            break;
        case AML_LOGGING_LEVEL_WARNING:
            levelStr = @"W";
            break;
        case AML_LOGGING_LEVEL_DEBUG:
            levelStr = @"D";
            break;
        case AML_LOGGING_LEVEL_VERBOSE:
            levelStr = @"V";
            break;
        default:
            levelStr = @"U";
            break;
    }
    return levelStr;
}

@end

