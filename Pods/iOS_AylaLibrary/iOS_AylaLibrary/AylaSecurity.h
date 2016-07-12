//
//  AylaSecurity.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/12/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef
enum { IAML_SECURITY_KEY_SIZE_1024 = 1024,
       IAML_SECURITY_KEY_SIZE_1536 = 1536,
       IAML_SECURITY_KEY_SIZE_2048 = 2048
} IAML_SECURITY_KEY_SIZE;

#define AML_SECURITY_KEY_EXCHG_REQ_TIME_OUT 6

extern NSString * const localSetupUri;
@interface AylaSecurity : NSObject

+ (void) generateSessionKeyPair:(IAML_SECURITY_KEY_SIZE)keySize;

@end
