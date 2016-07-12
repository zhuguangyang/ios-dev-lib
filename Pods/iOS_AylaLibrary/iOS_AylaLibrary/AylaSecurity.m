//
//  AylaSecurity.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/12/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaSecurity.h"
#import "AylaApiClient.h"
#import "AylaSystemUtils.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaEncryption.h"
#import "AylaNotify.h"
#import "AylaLanModeSupport.h"
#import "NSData+Base64.h"
#import "AylaLanModule.h"
#import "AylaDefines_Internal.h"

NSString * const localSetupUri = @"/local_lan";

const char keyExchangeIdentifierPublic[] = "com.aylanetworks.keyEchange.rsaPublicKey";
const char keyExchangeIdentifierPrivate[] = "com.aylanetworks.keyEchange.rsaPrivateKey";

@implementation AylaSecurity

enum {
    IAML_SECURITY_KEY_STATUS_NONE,
    IAML_SECURITY_KEY_STATUS_WORKING,
    IAML_SECURITY_KEY_STATUS_DONE
};

static int keySizeChoice = IAML_SECURITY_KEY_SIZE_1024;
static int keyStatus = IAML_SECURITY_KEY_STATUS_NONE;

/**
 * Delete key pair from key chain.
 */
+ (void)deleteSessionKeys
{
    NSMutableDictionary *query1 = [NSMutableDictionary new];
    //Set the public key query dictionary.
    [query1 setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [query1 setObject:[NSData dataWithBytes:keyExchangeIdentifierPublic length:sizeof(keyExchangeIdentifierPublic)] forKey:(__bridge id)kSecAttrApplicationTag];
    [query1 setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [query1 setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    SecItemDelete((__bridge CFDictionaryRef)query1);
    
    //Set private key query dictionary
    [query1 setObject:[NSData dataWithBytes:keyExchangeIdentifierPrivate length:sizeof(keyExchangeIdentifierPrivate)] forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)query1);
}



/**
 * @param dictionary keySize, keyType, publicKeyTag, privateKeyTag required
 */
+ (BOOL)generateKeyPair:(NSDictionary *)dictionary
{
    [AylaSecurity deleteSessionKeys];
    keyStatus = IAML_SECURITY_KEY_STATUS_WORKING;
    OSStatus sanityCheck = noErr;
    SecKeyRef publicKey = NULL;
    SecKeyRef privateKey = NULL;
    
    AylaLogI(AYLA_THIS_CLASS, 0, @"%@, %@", @"entry", AYLA_THIS_METHOD);
    NSUInteger keySize = ((NSNumber *)[dictionary objectForKey:@"keySize"]).unsignedIntegerValue;

    NSData *publicTag = [dictionary objectForKey:@"publicKeyTag"];
    NSData *privateTag = [dictionary objectForKey:@"privateKeyTag"];

    NSMutableDictionary * privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * keyPairAttr = [[NSMutableDictionary alloc] init];
    
    [keyPairAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [keyPairAttr setObject:[NSNumber numberWithUnsignedInteger:keySize] forKey:(__bridge id)kSecAttrKeySizeInBits];
    
    [privateKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [privateKeyAttr setObject:privateTag forKey:(__bridge id)kSecAttrApplicationTag];
    [publicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [publicKeyAttr setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
    
    [keyPairAttr setObject:privateKeyAttr forKey:(__bridge id)kSecPrivateKeyAttrs];
    [keyPairAttr setObject:publicKeyAttr forKey:(__bridge id)kSecPublicKeyAttrs];
    
    BOOL result = NO;
    sanityCheck = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr, &publicKey, &privateKey);
    if(sanityCheck == noErr  && publicKey != NULL && privateKey != NULL) {
        AylaLogI(AYLA_THIS_CLASS, 0, @"%@, %@", @"completed", AYLA_THIS_METHOD);
        keyStatus = IAML_SECURITY_KEY_STATUS_DONE;
        result = YES;
    }
    else {
        AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%d, %@", @"failed", (int)sanityCheck, AYLA_THIS_METHOD);
        keyStatus = IAML_SECURITY_KEY_STATUS_NONE;
    }
    
    if(keyExchangeWaitingBlock){
        keyExchangeWaitingBlock(result);
        keyExchangeWaitingBlock = nil;
    }

    if(publicKey) CFRelease(publicKey);
    if(privateKey) CFRelease(privateKey);
    return result;
}

+ (NSData *)pkcsUnpadWithBuffer:(unsigned char *)dataPtr andLength:(NSUInteger)len
{
    unsigned char *p = dataPtr;
    if(*p++!=0 || *p!=2) {
        return nil;
    }
    for(p=p+1; p<dataPtr+len; p++) {
        if(*p == 0)
            break;
    }
    if(p>=p+len){
        return nil;
    }
    if(p-dataPtr < 8)
        return nil;
    p++;
    NSData *unpaddedData = [NSData dataWithBytes:p length:len-(p-dataPtr)];
    return unpaddedData;
}

/**
 * Beginning of key exchange
 */
+ (void)startKeyNegotiation:(AylaLanSession *)session returnBlock:(void (^)(BOOL result))errorBlock
{
    //NSString *path = [NSString stringWithFormat:@"local_reg.json"];
    NSString *ip = [AylaSystemUtils getIPAddress];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            ip,@"ip",
                            [AylaSystemUtils serverPortNumber],@"port",
                            localSetupUri,@"uri",
                            [NSNumber numberWithInt:NO], @"notify",
                            nil];
    NSDictionary *send = [[NSDictionary alloc] initWithObjectsAndKeys:params, @"local_reg",nil];

    [session sendExtensionMessage:POST_LOCAL_REGISTRATION params:send withTimeout:AML_SECURITY_KEY_EXCHG_REQ_TIME_OUT
    success:^(AylaHTTPOperation *operation, id responseObject) {
        saveToLog(@"%@, %@, %@, %@", @"I", @"AylaSecurity", @"success", @"local_reg.keyNegotiation");
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        if(operation.response.httpStatusCode == 412) { // Key Exchange Required
            [AylaSecurity startKeyExchange:session returnBlock:^(BOOL re){}];
        }
        else {
            if(errorBlock) {
                errorBlock(NO);
            }
        }
        saveToLog(@"%@, %@, %@:%d, %@:%ld, %@", @"E", @"->AylaDevice", @"errCode", 0, @"httpCode", (long)operation.response.httpStatusCode,  @"local_reg.keyNegotiatoin");;
    }];
}


static void (^keyExchangeWaitingBlock)(BOOL) = nil;
+ (void)startKeyExchange:(AylaLanSession *)session returnBlock:(void (^)(BOOL))returnBlock
{
    __block void (^continueBlock)(BOOL) = ^(BOOL result) {
        // Get public key in bits;
        NSMutableDictionary *keyChainQuery = [NSMutableDictionary new];
        [keyChainQuery setObject:[NSData dataWithBytes:keyExchangeIdentifierPublic length:sizeof(keyExchangeIdentifierPublic)] forKey:(__bridge id)kSecAttrApplicationTag];
        [keyChainQuery setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
        
        NSData *pubKeyInBits = [AylaSecurity readFromKeyChainInBits:keyChainQuery];
        NSString * encodedKey = [pubKeyInBits base64EncodedString];
        
        // Do key exchange here
        [AylaSecurity keyExchangeNotificationRSAWithPublicKey:encodedKey session:session];
        if(returnBlock)
            returnBlock(YES);
    };

    if(![AylaSecurity isRSAKeyPairAvailable] && keyStatus != IAML_SECURITY_KEY_STATUS_WORKING) {
        // Do Key Generation
        NSData *privateTag = [[NSData alloc] initWithBytes:keyExchangeIdentifierPrivate length:sizeof(keyExchangeIdentifierPrivate)];
        NSData *publicTag = [[NSData alloc] initWithBytes:keyExchangeIdentifierPublic length:sizeof(keyExchangeIdentifierPublic)];
        NSInteger keySize = keySizeChoice;
        
        NSDictionary *keyDict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInteger:keySize], @"keySize", @"rsa", @"keyType", publicTag, @"publicKeyTag", privateTag, @"privateKeyTag", nil];
        BOOL status = [AylaSecurity generateKeyPair:keyDict];
        if(!status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *returnNotify = [AylaNotify initNotifyDictionaryWithType:AML_NOTIFY_TYPE_SESSION dsn:[AylaLanMode device].dsn status:400 description:nil values:nil];
                [AylaNotify returnNotify:returnNotify];
            });
            saveToLog(@"%@, %@, %@, %@", @"E", @"AylaSecurity", @"key pair generation failed", @"generateKeyPair");
            return;
        }
        continueBlock(YES);
    }
    else if(keyStatus == IAML_SECURITY_KEY_STATUS_WORKING) {
        // Key generating ->  wait until key generated
        keyExchangeWaitingBlock = ^(BOOL result){
            if(result && continueBlock){
                continueBlock(result);
            }
            else if(returnBlock)
                returnBlock(result);
            keyExchangeWaitingBlock = nil;
        };
    }
    else {
        continueBlock(YES);
    }
}

+ (void)keyExchangeNotificationRSAWithPublicKey:(NSString *)encodedPubKey session:(AylaLanSession *)session
{
    //NSString *path = [NSString stringWithFormat:@"local_reg.json"];
    NSString *ip = [AylaSystemUtils getIPAddress];
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            ip,@"ip",
                            [AylaSystemUtils serverPortNumber],@"port",
                            localSetupUri,@"uri",
                            [NSNumber numberWithInt:NO], @"notify",
                            encodedPubKey, @"key",
                            nil];
    NSDictionary *send = [[NSDictionary alloc] initWithObjectsAndKeys:params, @"local_reg",nil];
    
    [session sendExtensionMessage:POST_LOCAL_REGISTRATION params:send withTimeout:AML_SECURITY_KEY_EXCHG_REQ_TIME_OUT success:^(AylaHTTPOperation *operation, id responseObject) {
        saveToLog(@"%@, %@, %@, %@", @"I", @"AylaSecurity", @"success", @"local_reg.keyExchange");
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *returnNotify = [AylaNotify initNotifyDictionaryWithType:AML_NOTIFY_TYPE_SESSION dsn:[AylaLanMode device].dsn status:404 description:nil values:nil];
            [AylaNotify returnNotify:returnNotify];
        });
        saveToLog(@"%@, %@, %@:%d, %@:%ld, %@", @"E", @"AylaSecurity", @"errCode", 0, @"httpCode", (long)operation.response.httpStatusCode,  @"local_reg.keyExchange");;
    }];
}


+ (CFTypeRef)readFromKeyChainInCFType:(NSMutableDictionary *)query
{
    CFTypeRef result = NULL;
    
    [query setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [query setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [query setObject:@YES forKey:(__bridge id)kSecReturnRef];
    [query setObject:@NO forKey:(__bridge id)kSecReturnData];

    OSStatus sanityCheck = 1;
    sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &result);
    if (sanityCheck == noErr) {
        
    }
    return result;
}

+ (NSData *)readFromKeyChainInBits:(NSMutableDictionary *)query
{
    CFTypeRef result = nil;
    [query setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [query setObject:@YES forKey:(__bridge id)kSecReturnData];
    [query setObject:@NO forKey:(__bridge id)kSecReturnRef];
    OSStatus sanityCheck = 1;
    sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &result);
    if (sanityCheck == noErr) {
        NSData *data = CFBridgingRelease(result);                
        return data;
    }
    else
        return nil;
}

+ (NSString *) processRSAKeyExhangeWithDictionary:(NSDictionary *)params session:(AylaLanSession *)session
{
    NSString *random1 = [params objectForKey:@"random_1"];
    NSNumber *time1 = [params objectForKey:@"time_1"];
    NSString *sec = [params objectForKey:@"sec"];
    
    if(!sec||!random1||!time1) {
        saveToLog(@"%@, %@, %@:%d, %@:%d, %@:%d, %@", @"E", @"AylaSecurity", @"random1", random1?1:0, @"time1", time1?1:0, @"sec", sec?1:0, @"generateKeyRSAWithDictionary");
        return nil;
    }
    
    // Local key generation
    NSData *data = [NSData dataFromBase64String:sec];
    
    NSMutableDictionary *query = [NSMutableDictionary new];
    [query setObject:[NSData dataWithBytes:keyExchangeIdentifierPrivate length:sizeof(keyExchangeIdentifierPrivate)] forKey:(__bridge id)kSecAttrApplicationTag];
    [query setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    CFTypeRef ref = [AylaSecurity readFromKeyChainInCFType:query];
    
    unsigned char sharedSecretBuf[1024];
    size_t decryptedLength = 1024;
    OSStatus status = SecKeyDecrypt((SecKeyRef)ref, kSecPaddingNone, data.bytes, [data length], sharedSecretBuf, &decryptedLength);
    if(status != noErr) {
        saveToLog(@"%@, %@, %@, %@", @"E", @"AylaSecurity", @"failed to decrypt data", @"processRSAKeyExchangeWithDictionary");
        return nil;
    }
    long keyLength = SecKeyGetBlockSize((SecKeyRef)ref);
    
    CFRelease(ref);
    
    long dataLength = keyLength - 1;
    if(decryptedLength != dataLength || sharedSecretBuf[0] != 0x02) {
        saveToLog(@"%@, %@, %@:%zd, %@", @"E", @"AylaSecurity", @"decryptedData is invalid.Len", decryptedLength, @"generateKeyDHWithDictionary");
        return nil;
    }

    // One more step before padding
    unsigned char tmpSharedSecretBuf[1024];
    tmpSharedSecretBuf[0] = 0x00;
    memcpy(tmpSharedSecretBuf+1, sharedSecretBuf, decryptedLength);

    NSData *unpaddedSharedSecret = [AylaSecurity pkcsUnpadWithBuffer:tmpSharedSecretBuf andLength:decryptedLength+1];
    if(!unpaddedSharedSecret) {
        saveToLog(@"%@, %@, %@, %@", @"E", @"AylaSecurity", @"can't unpad decrypted data", @"processRSAKeyExchangeWithDictionary");
        return nil;
    }
    
    NSString *random2 = [AylaEncryption randomToken:16];
    NSNumber *time2 = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000000];
    NSString *respString = [AylaSecurity rsaKeyExchangeToModuleStringWithRandom2:random2 time2:time2];
    
    NSDictionary *type = [[NSDictionary alloc] initWithObjectsAndKeys:@"wifi_setup_rsa", @"type", unpaddedSharedSecret, @"data",nil];
    
    [session.sessionEncryption generateSessionkeys:type sRnd1:random1 nTime1:time1 sRnd2:random2 nTime2:time2];
    
    return respString;
}

+ (NSString *) rsaKeyExchangeToModuleStringWithRandom2:(NSString *)randomToken time2:(NSNumber *)curTime
{
    return [NSString stringWithFormat:@"{\"random_2\":\"%@\", \"time_2\":%@}", randomToken, curTime];
}

+ (NSString *)retrievePublicKeyInBase64
{
    NSMutableDictionary *query = [NSMutableDictionary new];
    [query setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [query setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [query setObject:[NSData dataWithBytes:keyExchangeIdentifierPublic length:sizeof(keyExchangeIdentifierPublic)] forKey:(__bridge id)kSecAttrApplicationTag];
    NSData *keyInBits = [AylaSecurity readFromKeyChainInBits:query];
    if(!keyInBits) {
        saveToLog(@"%@, %@, %@, %@", @"I", @"AylaSecurity", @"generate new key pair", @"retrievePublicKeyInBase64");
        [AylaSecurity generateSessionKeyPair:keySizeChoice];
    }
    return keyInBits? [keyInBits base64EncodedString]:nil;
}

+ (void) refreshSessionKeyPair
{
    [AylaSecurity generateSessionKeyPair:keySizeChoice];
}

/**
 * Simply check if there is a RSA key pair in key chain.
 * This method can not guarantee this key pair is valid.
 */
+ (BOOL) isRSAKeyPairAvailable
{
    NSMutableDictionary *query = [NSMutableDictionary new];
    [query setObject:[NSData dataWithBytes:keyExchangeIdentifierPrivate length:sizeof(keyExchangeIdentifierPrivate)] forKey:(__bridge id)kSecAttrApplicationTag];
    [query setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [query setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    SecKeyRef priKeyRef = (SecKeyRef)[AylaSecurity readFromKeyChainInCFType:query];
    
    [query setObject:[NSData dataWithBytes:keyExchangeIdentifierPublic length:sizeof(keyExchangeIdentifierPublic)] forKey:(__bridge id)kSecAttrApplicationTag];
    SecKeyRef pubKeyRef = (SecKeyRef)[AylaSecurity readFromKeyChainInCFType:query];
    
    BOOL result = (pubKeyRef && priKeyRef)? YES: NO;
    if(pubKeyRef) CFRelease(pubKeyRef);
    if(priKeyRef) CFRelease(priKeyRef);
    return result;
}

+ (void) generateSessionKeyPair:(IAML_SECURITY_KEY_SIZE)keySize
{
    keySizeChoice = keySize;
    if(keyStatus == IAML_SECURITY_KEY_STATUS_WORKING) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSData *privateTag = [[NSData alloc] initWithBytes:keyExchangeIdentifierPrivate length:sizeof(keyExchangeIdentifierPrivate)];
        NSData *publicTag = [[NSData alloc] initWithBytes:keyExchangeIdentifierPublic length:sizeof(keyExchangeIdentifierPublic)];
        NSDictionary *keyDict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInteger:keySize], @"keySize", @"rsa", @"keyType", publicTag, @"publicKeyTag", privateTag, @"privateKeyTag", nil];
        [AylaSecurity generateKeyPair:keyDict];
    });
}

+ (void)cleanCurrentSession
{
    keyExchangeWaitingBlock = nil;
}

/** DH Key Exchange would be deprecated
+ (NSString *) processDHKeyExhangeWithDictionary:(NSDictionary *)params
{
    NSString *random1 = [params objectForKey:@"random_1"];
    NSNumber *time1 = [params objectForKey:@"time_1"];
    NSString *p = [params objectForKey:@"p"];
    NSString *g = [params objectForKey:@"g"];
    NSString *A = [params objectForKey:@"A"];
    
    if(!p||!g||!random1||!A||!time1) {
        saveToLog(@"%@, %@, %@:%d, %@:%d, %@:%d, %@:%d, %@:%d, %@", @"E", @"AylaSecurity", @"p", p?1:0, @"g", g?1:0, @"random1", random1?1:0, @"time1", time1?1:0, @"A", A?1:0, @"generateKeyDHWithDictionary");
        return nil;
    }
    
    //local key generation
    DH *localKey = nil;
    localKey = DH_new();
    
    NSData *dataP = [NSData dataFromBase64String:p];
    NSData *dataG = [NSData dataFromBase64String:g];
    NSData *dataA = [NSData dataFromBase64String:A];
    
    const char * pPtr = [dataP bytes];
    const char * gPtr = [dataG bytes];
    const char * aPtr = [dataA bytes];
    
    localKey->p = BN_bin2bn((const unsigned char *)pPtr, [dataP length], NULL);
    localKey->g = BN_bin2bn((const unsigned char *)gPtr, [dataG length], NULL);

    BIGNUM *pubKeyA = BN_bin2bn((const unsigned char *)aPtr, [dataA length], NULL);
    
    int rc = DH_generate_key(localKey);
    if(!rc) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaSecurity", @"DH_key", @"can not be generated", @"generateKeyDHWithDictionary");
        return nil;
    }

    unsigned char tmpBuf[1024];
    int len = BN_bn2bin(localKey -> pub_key, tmpBuf);

    if(len <= 0) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaSecurity", @"DH_key", @"BN_bn2bin", @"generateKeyDHWithDictionary");
        return nil;
    }

    // Do key exchange
    NSData *pubKeyData = [[NSData alloc] initWithBytes:tmpBuf length:len];
    NSString *pubKeyInBase64 = [pubKeyData base64EncodedString];

    unsigned char sharedSecretBuf[1024];
    int sharedSecretLen = DH_compute_key(sharedSecretBuf, pubKeyA, localKey);
    NSData *sharedSecretData = [[NSData alloc] initWithBytes:sharedSecretBuf length:sharedSecretLen];

    NSString *random2 = [AylaEncryption randomToken:16];
    NSNumber *time2 = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000000];
    
    NSString *respString = [AylaSecurity dhKeyExchangeToModuleStringWithPubKey:pubKeyInBase64 random2:random2 time2:time2];
    
    NSLog(@"sharedSecret : %@", [AylaEncryption dataToHexString:sharedSecretData]);
    
    NSDictionary *type = [[NSDictionary alloc] initWithObjectsAndKeys:@"wifi_setup_dh", @"type", sharedSecretData, @"data",nil];
    [AylaEncryption generateSessionkeys:type sRnd1:random1 nTime1:time1 sRnd2:random2 nTime2:time2];
    return respString;
}

+ (NSString *) dhKeyExchangeToModuleStringWithPubKey:(NSString *)pubKeyBase64 random2:(NSString *)randomToken time2:(NSNumber *)curTime
{
    return [NSString stringWithFormat:@"{\"random_2\":\"%@\", \"time_2\":%@, \"B\": \"%@\"}",
             randomToken, curTime, pubKeyBase64];
}
*/
@end
