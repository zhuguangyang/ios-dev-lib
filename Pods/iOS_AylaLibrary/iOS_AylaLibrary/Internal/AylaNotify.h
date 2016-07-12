//
//  AylaNotify.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/11/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, AylaNotifyType) {
    AylaNotifyTypeSession,
    AylaNotifyTypeProperty,
    AylaNotifyTypeNodeProperty
};

@interface AylaNotify : NSObject

@property (strong, nonatomic) NSString *dsn;
@property (assign, nonatomic) int statusCode;

@property (readonly, nonatomic) NSString *desription;

@property (readonly, nonatomic) NSString *key;
@property (readonly, nonatomic) id value;

+(void) register: (void(^)(NSDictionary *)) handle;

+(void) returnNotify: (NSDictionary *) respNotify;

+(int) notifyOutstandingCounter;
+(void) setNotifyOutstandingCounter:(int) _notifyOutstandingCounter;

+(NSDictionary *) initNotifyDictionaryWithType:(NSString *)type dsn:(NSString *)dsn status:(NSUInteger)statusCode
                                   description:(NSString *)description values:(NSArray *)propArray;

+ (NSDictionary *)initNotifyDictionaryWithType:(NSString *)type
                                           dsn:(NSString *)dsn
                                        status:(NSUInteger)statusCode
                                   description:(NSString *)description
                                           key:(NSString *)key
                                        values:(NSArray *)values;

+ (NSDictionary *)initNotifyDictionaryWithType:(NSString *)type dsn:(NSString *)dsn status:(NSUInteger)statusCode code:(NSUInteger)code
                                   description:(NSString *)description key:(NSString *)key values:(NSArray *)values;

@end
