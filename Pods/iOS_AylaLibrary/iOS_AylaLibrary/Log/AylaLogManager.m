//
//  AylaLog.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/23/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaLogManager.h"
#import "AylaSystemUtils.h"
#import "NSObject+AylaNetworks.h"
#import "AylaLogger.h"
#import "AylaLogSupport.h"

@interface AylaLogManager () {
    int _curOutputs;
    dispatch_queue_t _queue;
}

@property (nonatomic, readwrite) NSMutableDictionary *mutableLoggers;
@property (nonatomic, readwrite) NSMutableDictionary *mutableSysLoggers;

@end

@implementation AylaLogManager

static NSString * const DefaultFileLoggerKey = @"com.aylanetworks.fileLogger";
static NSString * const DefaultConsoleLoggerKey = @"com.aylanetworks.consoleLogger";
static NSString * const DefaultCloudLoggerKey = @"com.aylanetworks.cloudLogger";

+ (instancetype)sharedManager
{
    static AylaLogManager *manager = nil;
    static dispatch_once_t managerToken;
    dispatch_once(&managerToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if(!self) return nil;
    
    const char *queue_label = "com.aylanetworks.logManagerQueue";
    _queue = dispatch_queue_create(queue_label, DISPATCH_QUEUE_SERIAL);
    
    _mutableLoggers = [NSMutableDictionary dictionary];
    _mutableSysLoggers = [NSMutableDictionary dictionary];
    
    return self;
}

- (AylaSystemLoggingLevel)loggingLevel
{
    return [AylaSystemUtils loggingLevel];
}

- (void)updateLoggingLevel:(AylaSystemLoggingLevel)loggingLevel
{
    [AylaSystemUtils loggingLevel:loggingLevel];
}

- (AylaSystemLoggingOutput)loggingOutputs
{
    return [AylaSystemUtils loggingOutputs];
}

- (void)updateLoggingOutputs:(AylaSystemLoggingOutput)loggingOutputs
{
    [AylaSystemUtils loggingOutputs:loggingOutputs];
}

- (void)updateSysLoggers
{
    if(_curOutputs == self.loggingOutputs) return;
    AylaSystemLoggingOutput outputs = self.loggingOutputs;
    void(^handleBlock)(AylaSystemLoggingOutput option, NSString *key, Class LoggerClass) =
    ^(AylaSystemLoggingOutput loggerOption, NSString *key, Class LoggerClass) {
        if((outputs & loggerOption) > 0) {
            if(![_mutableSysLoggers objectForKey:key]) {
                AylaLogger *logger = [[LoggerClass alloc] initWithFilterBlock:nil formatter:nil];
                [_mutableSysLoggers setObject:logger forKey:key];
            }
        }
        else{
            [_mutableSysLoggers removeObjectForKey:key];
        }
    };
    handleBlock(AylaSystemLoggingOutputConsole, DefaultConsoleLoggerKey, [AylaConsoleLogger class]);
    handleBlock(AylaSystemLoggingOutputLogFile, DefaultFileLoggerKey, [AylaFileLogger class]);
    _curOutputs = outputs;
}

- (void)addLogger:(id<AylaLoggerProtocol>)logger withKey:(NSString *)key
{
    if(![key nilIfNull] || !logger) return;
    dispatch_async(_queue, ^{
        [_mutableLoggers setObject:logger forKey:key];
    });
}

-(void)removeLoggerWithKey:(NSString *)key
{
    if(![key nilIfNull]) return;
    dispatch_async(_queue, ^{
        [_mutableLoggers removeObjectForKey:key];
    });
}

- (NSArray *)loggers
{
    return _mutableLoggers.allValues;
}

- (void)log:(NSString *)tag
      level:(AML_LOGGING_LEVEL)level
       flag:(NSInteger)flag
       time:(NSDate *)time
        fmt:(NSString *)fmt, ...
{
    //Skip messages based on logging level
    if((level & [self loggingLevel]) <= 0) return;
    
    va_list args;
    va_start(args, fmt);
    AylaLogMessage *message = [[AylaLogMessage alloc] initWithTag:tag level:level flag:flag time:time fmt:fmt args:args];
    va_end(args);
    
    dispatch_async(_queue, ^{
        @autoreleasepool {
            [self updateSysLoggers];
            for (id<AylaLoggerProtocol> logger in _mutableSysLoggers.allValues) {
                [logger logMessage:message];
            }
            if((_curOutputs & AylaSystemLoggingOutputAppLoggers) > 0) {
                for (id<AylaLoggerProtocol> logger in _mutableLoggers.allValues) {
                    [logger logMessage:message];
                }
            }
        }
    });
}

- (void)logOldFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    AylaLogMessage *message = [[AylaLogMessage alloc] initWithOldFormat:fmt args:args];
    va_end(args);

    //Skip messages based on logging level
    if((message.level & [self loggingLevel]) <= 0) return;
    
    dispatch_async(_queue, ^{
        @autoreleasepool {
            [self updateSysLoggers];
            for (id<AylaLoggerProtocol> logger in _mutableSysLoggers.allValues) {
                [logger logMessage:message];
            }
            if((_curOutputs & AylaSystemLoggingOutputAppLoggers) > 0) {
                for (id<AylaLoggerProtocol> logger in _mutableLoggers.allValues) {
                    [logger logMessage:message];
                }
            }
        }
    });
}

@end
