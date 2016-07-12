//
//  AylaLogSupport.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/28/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AylaLogMessage (Support)

- (instancetype)initWithTag:(NSString *)tag
                      level:(AML_LOGGING_LEVEL)level
                       flag:(NSInteger)flag
                        fmt:(NSString * __nullable)fmt
                       args:(va_list)args;

- (instancetype)initWithTag:(NSString *)tag
                      level:(AML_LOGGING_LEVEL)level
                       flag:(NSInteger)flag
                       time:(NSDate  * __nullable)time
                        fmt:(NSString * __nullable)fmt
                       args:(va_list)args;

- (instancetype)initWithOldFormat:(NSString *)fmt args:(va_list)args;

@end

NS_ASSUME_NONNULL_END