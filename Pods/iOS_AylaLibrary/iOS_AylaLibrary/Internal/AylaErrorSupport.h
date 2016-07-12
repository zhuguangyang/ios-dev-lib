//
//  AylaErrorSupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/9/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaResponseSupport.h"
@interface AylaError (Support)
@property (nonatomic, readwrite) id errorInfo;
@property (nonatomic, readwrite) id nativeErrorInfo;
@property (nonatomic, readwrite) NSInteger errorCode;

+ (AylaError *)createWithCode:(NSInteger)errCode httpCode:(NSInteger)httpCode
                  nativeError:(NSError *)nativeError
                andErrorInfo:(NSDictionary *)dictionary;

- (NSString *)logDescription;

@end
