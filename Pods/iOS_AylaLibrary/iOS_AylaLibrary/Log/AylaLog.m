//
//  AylaLog.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/23/15.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaLog.h"

@interface AylaLogMessage ()

@property (nonatomic, readwrite) NSString *tag;
@property (nonatomic, readwrite, assign) NSInteger flag;
@property (nonatomic, readwrite, assign) AML_LOGGING_LEVEL level;
@property (nonatomic, readwrite) NSDate *time;
@property (nonatomic, readwrite) NSString *message;
@property (nonatomic, readwrite, assign) BOOL oldFormat;

@end

@implementation AylaLogMessage

- (instancetype)initWithTag:(NSString *)tag
                      level:(AML_LOGGING_LEVEL)level
                       flag:(NSInteger)flag
                        fmt:(NSString *)fmt
                       args:(va_list)args
{
    NSString *message;
    if(fmt) {
        message = [[NSString alloc] initWithFormat:fmt arguments:args];
    }
    return [self initWithTag:tag level:level flag:flag time:nil message:message];
}


- (instancetype)initWithTag:(NSString *)tag
                      level:(AML_LOGGING_LEVEL)level
                       flag:(NSInteger)flag
                       time:(NSDate  * __nullable)time
                        fmt:(NSString *)fmt
                       args:(va_list)args
{
    NSString *message;
    if(fmt) {
        message = [[NSString alloc] initWithFormat:fmt arguments:args];
    }
    return [self initWithTag:tag level:level flag:flag time:time message:message];
}

static NSString * const DefaultLogTag = @"AylaLib";
- (instancetype)initWithOldFormat:(NSString *)fmt args:(va_list)args
{
    self = [super init];
    if(!self) return nil;
    
    NSString *levelInStr;
    NSString *tag;
    NSString *message = [[NSString alloc] initWithFormat:fmt arguments:args];
    
    NSArray *components = [message componentsSeparatedByString:@", "];
    NSUInteger compCount = components.count;
    if(compCount > 0) {
        levelInStr = components[0];
        switch ((int)[levelInStr characterAtIndex:0]) {
            case 'E':
                self.level = AML_LOGGING_LEVEL_ERROR;
                break;
            case 'W':
                self.level = AML_LOGGING_LEVEL_WARNING;
                break;
            case 'I':
                self.level = AML_LOGGING_LEVEL_INFO;
                break;
            case 'D':
                self.level = AML_LOGGING_LEVEL_DEBUG;
                break;
            case 'V':
                self.level = AML_LOGGING_LEVEL_VERBOSE;
                break;
            default:
                self.level = AML_LOGGING_LEVEL_VERBOSE;
                break;
        }
    }
    if(compCount > 1) {
        tag = components[1];
    }
    self.tag = tag?:DefaultLogTag;
    self.time = [NSDate date];
    self.message = message;
    self.oldFormat = YES;
    return self;
}

- (instancetype)initWithTag:(NSString *)tag
                      level:(AML_LOGGING_LEVEL)level
                       flag:(NSInteger)flag
                       time:(NSDate *)time
                    message:(NSString *)message
{
    self = [super init];
    if(!self) return nil;
    
    self.tag = tag;
    self.flag = flag;
    self.level = level;
    self.time = time?:[NSDate date];
    self.message = message;
    
    return self;
}

@end

