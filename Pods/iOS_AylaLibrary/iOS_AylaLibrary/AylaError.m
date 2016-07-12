//
//  AylaError.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/9/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaError.h"
#import "AylaResponseSupport.h"
#import "AylaDefines_Internal.h"

@interface AylaError ()
@property (nonatomic, readwrite) id errorInfo;
@property (nonatomic, readwrite) NSError *nativeErrorInfo;
@property (nonatomic, readwrite) NSInteger errorCode;
@end

@implementation AylaError

- (id)initWithAylaResponse:(AylaResponse *)reponse
{
    self = [super self];
    if(self && reponse) {
        self.httpStatusCode = reponse.httpStatusCode;
    }
    return self;
}

- (id)initWithNSDictionary:(NSDictionary *)dictionary
{
    self = [super initWithNSDictionary:dictionary];
    if(self) {
        self.errorInfo = [dictionary objectForKey:[NSNumber numberWithInt:AylaErrorParameterErrorInfo]]? nil: [dictionary objectForKey:[NSNumber numberWithInt:AylaErrorParameterErrorInfo]];
        
        self.nativeErrorInfo = [dictionary objectForKey:[NSNumber numberWithInt:AylaErrorParameterNativeErrorInfo]]? nil: [dictionary objectForKey:[NSNumber numberWithInt:AylaErrorParameterNativeErrorInfo]];
        
        self.errorCode = [dictionary objectForKey:[NSNumber numberWithInt:AylaErrorParameterErrorCode]]? 0: [(NSNumber *)[dictionary objectForKey:[NSNumber numberWithInt:AylaErrorParameterErrorCode]] integerValue];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    if (copy) {
        AylaError *_copy = copy;
        _copy.errorInfo = self.errorInfo;
        _copy.nativeErrorInfo = self.nativeErrorInfo;
        _copy.errorCode = self.errorCode;
    }
    return copy;
}

+ (AylaError *)createWithCode:(NSInteger)errCode httpCode:(NSInteger)httpCode
                  nativeError:(NSError *)nativeError
               andErrorInfo:(NSDictionary *)dictionary
{
    AylaError *err = [AylaError new];
    err.httpStatusCode = httpCode;
    err.nativeErrorInfo = nativeError;
    err.errorInfo = dictionary;
    err.errorCode = dictionary? errCode: 1; //AML ERROR FAIL
    return err;
}

+ (NSError *)nativeErrorWithCode:(NSInteger)code domain:(NSString *)domain userInfo:(NSDictionary *)userInfo
{
    return [[NSError alloc] initWithDomain:domain code:code userInfo:userInfo];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, code: %ld, httpCode: %ld, nativeError: %@, errorInfo: %@>", AYLA_THIS_CLASS, self, (long)self.errorCode, (unsigned long)self.httpStatusCode, self.nativeErrorInfo, self.errorInfo];
}

- (NSString *)logDescription
{
    return
    [NSString stringWithFormat:@"Descrip: errCode:%ld, http:%ld, nCode:%ld, errInfo:%@",
     (long)self.errorCode,
     (unsigned long)self.httpStatusCode,
     (long)self.nativeErrorInfo.code,
     self.errorInfo];
}

@end

NSString * const AMLErrorDomain = @"com.aylanetworks.errorDomain";
NSString * const kAylaErrorInfoObject = @"object";
NSString * const kAylaErrorInfoObjectErrors = @"object_errors";
NSString * const kAylaErrorInfoObjects = @"objects";
NSString * const kAylaErrorInfoDescription = @"description";
