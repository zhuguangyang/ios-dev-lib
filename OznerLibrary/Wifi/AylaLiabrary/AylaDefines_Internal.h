//
//  AylaDefines_Private.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/14/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AYLAssert(condition, desc, ...) \
do { \
    NSAssert(condition, desc, ##__VA_ARGS__); \
}while(0) \

#define AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN dispatch_async(dispatch_get_main_queue(), ^{
#define AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END   });

#define AYLA_RUN_ASYNC_ON_QUEUE_BEGIN(queue, delay) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), queue, ^{
#define AYLA_RUN_ASYNC_ON_QUEUE_END                 });

#define AYLA_JSON_EXTENSION @".json"

#define AYLA_REQUEST_METHOD_GET        @"GET"
#define AYLA_REQUEST_METHOD_POST       @"POST"
#define AYLA_REQUEST_METHOD_PUT        @"PUT"
#define AYLA_REQUEST_METHOD_DELETE     @"DELETE"

#define AYLA_THIS_CLASS NSStringFromClass([self class])
#define AYLA_THIS_METHOD NSStringFromSelector(_cmd)