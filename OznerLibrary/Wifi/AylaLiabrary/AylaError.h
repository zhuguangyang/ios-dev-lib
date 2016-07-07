//
//  AylaError.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/9/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

typedef enum {
    AylaErrorParameterErrorCode = 1000,
    AylaErrorParameterNativeErrorInfo,
    AylaErrorParameterErrorInfo
} AylaErrorParameter;

#import <Foundation/Foundation.h>
#import "AylaResponse.h"

// AML ERRORS
typedef enum {
    AML_ERROR_OK = 0,                   // No error
    AML_ERROR_FAIL = 1,                 // The operation did not succeed. Check the nativeErrorInfo(normally it's a NSError object) object for details
    AML_AYLA_ERROR_FAIL = 2,            // The operation did not succeed. Check the errorInfo object for details
    
    AML_ERROR_ASYNC_OK = 200,
    AML_ERROR_ASYNC_OK_NON_AUTH_INFO = 203,
    AML_ERROR_ASYNC_OK_PARTIAL_CONTENT = 206,
    AML_ERROR_BAD_REQUEST = 400,
    AML_ERROR_NOT_FOUND = 404,          // No results were found
    AML_ERROR_REQUEST_TIMEOUT = 408,
    AML_ERROR_PRECONDITION_FAILED = 412,
    
    AML_ERROR_NATIVE_CODE_REQUEST_CANCELLED = NSURLErrorCancelled,
    AML_ERROR_NATIVE_CODE_REQUEST_TIMED_OUT = NSURLErrorTimedOut,
    
    AML_ALLOCATION_FAILURE = -2001,
    AML_NO_ITEMS_FOUND = -2002,
    AML_JSON_PARSE_ERROR = -2003,
    AML_USER_NO_AUTH_TOKEN = -2004,
    AML_USER_INVALID_PARAMETERS = -2005,
    AML_USER_OAUTH_DENY = -2006,         // available since version 2.23
    AML_USER_OAUTH_ERROR = -2007,
    AML_ERROR_BUSY = -2008,
    AML_ERROR_NO_CONNECTIVITY = -2009,
} AML_ERROR_DOMAIN;

@interface AylaError :AylaResponse<NSCopying>
@property (nonatomic, readonly) id errorInfo;
@property (nonatomic, readonly) NSError *nativeErrorInfo; //Note: nativeErrorInfo: NSError on iOS, {API name & error code} on Android
@property (nonatomic, readonly) NSInteger errorCode;

- (id)initWithAylaResponse:(AylaResponse *)reponse;

+ (NSError *)nativeErrorWithCode:(NSInteger)code domain:(NSString *)domain userInfo:(NSDictionary *)userInfo;

@end

extern NSString * const AMLErrorDomain;
extern NSString * const kAylaErrorInfoObject;
extern NSString * const kAylaErrorInfoObjectErrors;
extern NSString * const kAylaErrorInfoObjects;
extern NSString * const kAylaErrorInfoDescription;
