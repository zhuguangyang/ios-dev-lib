//
//  AylaSecuritySupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/27/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AML_SECURITY_KEY_EXCHANGE_RSA_WITH_KEY_PAIR 3
#define AML_SECURITY_KEY_EXCHANGE_RSA_WITHOUT_KEY_PAIR 7

@class AylaLanSession;
@interface AylaSecurity(Support)
+ (void)        startKeyNegotiation:(AylaLanSession *)session returnBlock:(void (^)(BOOL result))errorBlock;
+ (void)        startKeyExchange:(AylaLanSession *)session returnBlock:(void (^)(BOOL))returnBlock;
+ (NSString *)  processRSAKeyExhangeWithDictionary:(NSDictionary *)params session:(AylaLanSession *)session;
+ (void)        cleanCurrentSession;
+ (void)        refreshSessionKeyPair;
+ (BOOL)        isRSAKeyPairAvailable;

/** DH Key Exchange would be deprecated
 + (NSString *) processDHKeyExhangeWithDictionary:(NSDictionary *)params;
 */
@end
