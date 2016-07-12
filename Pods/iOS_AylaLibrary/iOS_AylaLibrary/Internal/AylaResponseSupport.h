//
//  AylaResponseSupport.h
//  iMCA
//
//  Created by Yipei Wang on 8/8/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    AylaResponseParameterHttpStatusCode,
} AylaResponseParameter;

@interface AylaResponse (Support)
@property (nonatomic, readwrite) NSUInteger httpStatusCode;
@end
