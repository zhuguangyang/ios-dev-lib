//
//  AylaSystemUtilsSupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 3/20/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaSystemUtils(Support)

+ (void) initialize;

+ (NSString *) settingsFilePath;
+ (NSString *) usersArchiversFilePath;
+ (NSString *) deviceArchiversFilePath;
+ (NSString *) devicesArchiversFilePath;

// General System Utilities
+ (NSString *)       getIPAddress;
+ (NSString *)       rootDocumentsDirectory;
+ (NSString *)       shortErrorFromError:(NSError *)error;
+ (NSDateFormatter*) timeFmt;
+ (NSString *)       randomToken:(int)len;
+ (NSString *)       stringFromJsonObject:(id)object;
+ (NSString *)       jsonEscapedStringFromString:(NSString *)string;
+ (NSString *)       uriEscapedStringFromString:(NSString *)string;
+ (Class)            classFromClassName:(NSString *)className;
@end
