//
//  AylaEncryption.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/13/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AylaLanModule;
@interface AylaEncryption : NSObject

@property (copy, nonatomic) NSNumber *version;
@property (copy, nonatomic) NSNumber *proto1;
@property (copy, nonatomic) NSNumber *keyId1;
@property (assign, nonatomic) NSInteger sessionId;

@property (copy, nonatomic) NSString *sRnd1;
@property (copy, nonatomic) NSString *sRnd2;
@property (copy, nonatomic) NSNumber *nTime1;
@property (copy, nonatomic) NSNumber *nTime2;

@property (strong, readonly, nonatomic) NSData *appSignKey;
@property (strong, readonly, nonatomic) NSData *devSignKey;

@property (weak, nonatomic) AylaLanModule *lanModule;

- (void) updateParamsWithVersion:(NSNumber *)version proto1:(NSNumber *)proto1 keyId1:(NSNumber *)keyId1;

- (int) generateSessionkeys:(NSDictionary *)param sRnd1:(NSString*)_sRnd1 nTime1:(NSNumber *)_nTime1 sRnd2:(NSString*)_sRnd2 nTime2:(NSNumber*)_nTime2;

+ (NSData *)    hmacForKeyAndData:(NSData*)key data:(NSData*)data;

- (NSData *)    lanModeEncryptInStream:(NSString *)plainText;
- (NSString *)  lanModeDecryptInStream:(NSData *)cipherData;

+ (NSData *)    base64Decode:(NSString *)string;

+ (NSData *)    dataFromHexString:(NSString *)hexString;
+ (NSString *)  dataToHexString:(NSData *)data;

- (NSString *)  encryptEncapsulateSignWithPlaintext:(NSString *)plaintext sign:(NSData *)sign;

- (void)        cleanEncrypSession;


//-----------TokenGeneration-----------------------------
+ (NSString *)   randomToken:(int)len;

@end
