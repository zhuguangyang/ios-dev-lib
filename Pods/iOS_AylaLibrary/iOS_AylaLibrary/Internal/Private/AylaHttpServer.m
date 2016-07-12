//
//  AylaHttpServer.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/8/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaHttpServer.h"
#import "HTTPConnection.h"
#import "HTTPDataResponse.h"
#import "HTTPMessage.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaLanModeSupport.h"
#import "AylaReachabilitySupport.h"
#import "AylaNotify.h"
#import "AylaEncryption.h"
#import "AylaSecurity.h"
#import "AylaSecuritySupport.h"
#import "AylaDeviceSupport.h"
#import "AylaSetupSupport.h"
#import "AylaCacheSupport.h"
#import "GCDAsyncSocket.h"
#import "AylaLanModule.h"
#import "AylaDefines_Internal.h"
#import "AylaErrorSupport.h"
#import "AylaLanMessage.h"
#import "AylaMessageResponse.h"

@implementation AylaHttpServer 

- (id)initWithPort:(int) portNum
{
    self = [super init];
    if(self){
        //[self setType: @"_http._tcp."];
        [self setPort: portNum];
        //[self setConnectionClass:[AylaHttpServerConnection class]];
    }
    return self;
}


- (BOOL)start:(NSError *__autoreleasing *)errPtr
{
    [super setType: @"_http._tcp."];
    [super setConnectionClass:[AylaHttpServerConnection class]];
    return [super start:errPtr];
}

@end



@implementation AylaHttpServerConnection

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig
{
    self = [super initWithAsyncSocket:newSocket configuration:aConfig];
    self.hostIp = [newSocket connectedHost];
    return self;
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	// Add support for POST/PUT/DELETE
	if ([method isEqualToString:@"POST"])
	{
        /*
        if ([path isEqualToString:@"/local_reg/post.html"])
		{
			return requestContentLength < 50;
		}
        */
        return true;
	}
	else if ([method isEqualToString:@"PUT"])
	{
        return true;
	}
    else if ([method isEqualToString:@"DELETE"])
	{
        return true;
	}
    
    return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
	// Inform HTTP server that we expect a body to accompany a POST request
	if([method isEqualToString:@"POST"])
		return YES;
	return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    //get lan ip from path
    NSString *lanIp = self.hostIp;
    AylaDevice *sender = [AylaLanMode deviceWithLanIp:lanIp];
    AylaLanSession *session = sender.lanModule.session;
    AylaEncryption *encryption = session.sessionEncryption;
    
    AylaLogI(@"httpServer", 0, @"%@:%@, %@", @"sender", sender.dsn, AYLA_THIS_METHOD);
    // Print out url for each incoming request - DEBUG level only
    AylaLogD(@"httpServer", 0, @"%@, %@:%@, %@", method, @"url", path, AYLA_THIS_METHOD);
    
    if(!sender || !sender.lanModule.session) {
        NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
        AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:400 headerParam:headerDict dataParam:nil];
        AylaLogE(@"httpServer", 0, @"%@:%ld, %@:%@, %@", @"httpCode", (long)resp.status, @"err", @"NoSenderSessionFound", @"httpResponseForMethod.devWithUrlStr");
        return resp;
    }
        
	if ([method isEqualToString:@"POST"]) {
        
		NSData *postData = [request body];
        if ([path rangeOfString:@"local_lan/key_exchange.json"].location != NSNotFound) {
            
            [session stopTimer];
            [session setSessionState:KEY_EXCHANGE];
            
            // do key exchange
            NSError *jerr;
            id responseJSON = [NSJSONSerialization JSONObjectWithData:postData options:NSJSONReadingMutableContainers error:&jerr];
            if(responseJSON == NULL){
                 NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                 AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:400 headerParam:headerDict dataParam:nil];
                 AylaLogE(@"httpServer", 0, @"%@:%ld, %@:%ld, %@", @"httpCode", (long)resp.status, @"jerr", (long)jerr.code, @"httpResponseForMethod.Json");
                [session  startTimer];
                return resp;
            }
            
            NSDictionary *jsonDict = responseJSON;
            NSDictionary *info = [jsonDict objectForKey:@"key_exchange"];
            
            NSString *localRnd = [AylaEncryption randomToken:16];
            NSNumber *curTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]*1000000];
            
            //Check key exchange mechanism
            BOOL isKeyExchangeRequiredByModule = NO;
            if(![info objectForKey:@"key_id"]){
                isKeyExchangeRequiredByModule = YES;
            }
            
            if(isKeyExchangeRequiredByModule) {

                NSString *respStr = [AylaSecurity processRSAKeyExhangeWithDictionary:info session:session];
                if(!respStr) {
                    NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                    AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:400 headerParam:headerDict dataParam:nil];
                    AylaLogE(@"httpServer", 0, @"%@:%ld, %@", @"httpCode", (long)resp.status, @"httpResponseForMethod.key_exchange_rsa");
                    [session startTimer];
                    return resp;
                }
                
                NSData *respData = [respStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:200 headerParam:headerDict dataParam:respData];
                AylaLogI(@"httpServer", 0, @"%@:%ld, %@:%@", @"httpCode", (long)resp.status, @"resp", respStr);
                
                //ready to start wifi setup, currently only RSA key exchange supported
                [AylaSetup securityType:AylaSetupSecurityTypeRSA];
                [session setSessionState: UP];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if([AylaSetup continueBlock]) {
                        [AylaSetup continueBlock](YES);
                    }
                });
                
                [session  startTimer];
                return resp;
            }
            else {
                
                [encryption setVersion:[info valueForKey:@"ver"]];
                [encryption setProto1:[info valueForKey:@"proto"]];
                [encryption setKeyId1:[info valueForKey:@"key_id"]];
                
                AylaLogI(@"httpServer", 0, @"%@, %@:%@, %@:%@, %@:%@, %@",@"keyInfo", @"ver", encryption.version, @"proto", encryption.proto1 , @"key_id", encryption.keyId1, @"httpResponseForMethod.key_exchange");
                
                if([encryption.version intValue]!= 1){
                    NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                    AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:426 headerParam:headerDict dataParam:nil];
                    AylaLogE(@"httpServer", 0, @"%@:%ld, %@:%@, %@", @"httpCode", (long)resp.status, @"version", @"!= 1", @"httpResponseForMethod.key_exchange");

                    if([session inSetupMode]) {
                        [AylaSecurity startKeyExchange:session returnBlock:nil];
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSDictionary *returnNotify = [AylaNotify initNotifyDictionaryWithType:AML_NOTIFY_TYPE_SESSION dsn:sender.dsn status:400 description:nil values:nil];
                            [AylaNotify returnNotify:returnNotify];
                        });
                        [AylaReachability setDeviceReachability:AML_REACHABILITY_LAN_MODE_DISABLED];
                    }
                    [session  startTimer];
                    return resp;
                }
                
                NSNumber *lanIpKeyId = session.module.lanConfig.lanipKeyId;
                if(!lanIpKeyId || ![encryption.keyId1 isEqualToNumber:lanIpKeyId]){
                    
                    [AylaCache save:AML_CACHE_LAN_CONFIG withIdentifier:[sender dsn] andObject:nil];
                    
                    NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                    AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:412 headerParam:headerDict dataParam:nil];
                    AylaLogE(@"httpServer",0, @"%@:%ld, %@:%@, %@", @"httpCode", (long)resp.status, @"KeyId", @"can't match", @"httpResponseForMethod.key_exchange");
                
                    //set lanKeyIdToInvalid
                    //[[[AylaLanMode device] lanModeConfig] setLanipKeyId:[NSNumber numberWithInt:-1]];
                    
                    if([session inSetupMode]) {
                        [AylaSecurity startKeyExchange:session returnBlock:nil];
                        [session startTimer];
                    }
                    else {
                        [session updateSessionState:ERROR withCode:AylaLanModeErrorCodeUnmatchedKeyInfo httpStatusCode:412 sendNotify:YES];
                        [AylaReachability setDeviceReachability:AML_REACHABILITY_LAN_MODE_DISABLED];
                    
                        session.module.lanConfig = nil;
                        [session startTimer];
                    }
                    [session setSessionState:ERROR];
                    return resp;
                }
                if([[encryption proto1] intValue]!= 1){
                    NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                    AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:426 headerParam:headerDict dataParam:nil];
                    AylaLogE(@"httpServer", 0, @"%@:%ld, %@:%@, %@", @"httpCode", (long)resp.status, @"proto", @"!= 1", @"httpResponseForMethod.key_exchange");
                    
                    if([session inSetupMode]) {
                        [AylaSecurity startKeyExchange:session returnBlock:nil];
                        [session startTimer];
                    }
                    else {
                        [session updateSessionState:ERROR withCode:AylaLanModeErrorCodeUnmatchedKeyInfo httpStatusCode:426 sendNotify:YES];
                        [AylaReachability setDeviceReachability:AML_REACHABILITY_LAN_MODE_DISABLED];

                        [session startTimer];
                    }
                    
                    return resp;
                }
                
                [encryption generateSessionkeys:nil sRnd1:[info valueForKey:@"random_1"] nTime1:[info valueForKey:@"time_1"]
                                                        sRnd2:localRnd nTime2:curTime];
                
                NSString *respStr = [NSString stringWithFormat:@"{\"random_2\":\"%@\",\"time_2\":%@}", localRnd, curTime];            
                NSData *respData = [respStr dataUsingEncoding:NSUTF8StringEncoding];            
                
                [session setSessionState: UP];
                NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:200 headerParam:headerDict dataParam:respData];
                
                AylaLogI(@"httpServer", 0, @"%@:%d, %@:%@, %@", @"httpCode", 200, @"resp", respStr, @"httpResponseForMethod.key_exchange");
                
                if([session inSetupMode]) {
                    [AylaSetup securityType:AylaSetupSecurityTypeToken];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if([AylaSetup continueBlock]) {
                            [AylaSetup continueBlock](YES);
                        }
                    });
                    [session startTimer];
                }
                else {
                    [session.module deliverLanMessageWithType:AML_NOTIFY_TYPE_SESSION httpStatusCode:200 key:nil values:nil];
                    [session startTimer];
                }
                [AylaReachability setDeviceReachability:AML_REACHABILITY_REACHABLE];
                return resp;
            }
        }
        else {
            NSError *jerr;
            
            id responseJSON = [NSJSONSerialization JSONObjectWithData:postData options:NSJSONReadingMutableContainers error:&jerr];
            if(responseJSON == NULL){
                
                NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:400 headerParam:headerDict dataParam:nil];
                AylaLogE(@"httpServer", 0, @"%@:%ld, %@:%ld, %@", @"httpCode", (long)resp.status, @"jerr", (long)jerr.code, @"httpResponseForMethod.Json");
                return resp;
            }
            
            NSDictionary *jsonDict = responseJSON;
            NSString *sign = [jsonDict valueForKeyPath:@"sign"];
            NSString *enc = [jsonDict valueForKeyPath:@"enc"];
            
            NSData *decodedSign = [AylaEncryption base64Decode:sign];
            NSData *decodedEnc = [AylaEncryption base64Decode:enc];
            
            NSString *decryptedEnc = [encryption lanModeDecryptInStream:decodedEnc];
            if(decryptedEnc == nil){
                [session  stopTimer];
                NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:400 headerParam:headerDict dataParam:nil];
                AylaLogE(@"httpServer", 0, @"%@:%@, %@", @"decryption", @"can't be completed", @"httpResponseForMethod.post");
                
                [session startTimer];
                [session extendLanModeSession:POST_LOCAL_REGISTRATION haveDataToSend:false];
                return resp;
            }
            
            NSData *calcSign = [AylaEncryption hmacForKeyAndData:[encryption devSignKey] data:[decryptedEnc dataUsingEncoding:NSUTF8StringEncoding]];
            if(![decodedSign isEqualToData:calcSign]){
                
                NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:401 headerParam:headerDict dataParam:nil];
                AylaLogE(@"httpServer", 0, @"%@:%@, %@", @"signature", @"is invalid", @"httpResponseForMethod.post");
                
                return resp;
            }
            
            id encapJSON = [NSJSONSerialization JSONObjectWithData:[decryptedEnc dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&jerr];
            if(encapJSON == NULL){
                
                NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
                AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:400 headerParam:headerDict dataParam:nil];
                AylaLogE(@"httpServer", 0, @"%@:%@, %@, %@:%d, %@", @"JSON", @"is invalid", decryptedEnc, @"httpCode", 400, @"httpResponseForMethod.post");

                return resp;
            }
            
            AylaDevice *device = sender;
            int respStatusCode = 200;
            [session stopTimer];
            
            if(!device) {
                AylaLogW(@"httpServer", 0, @"%@:%@, %@", @"device", @"is null", @"httpResponseForMethod.post");
                respStatusCode = 404;
            }
            else {
                jsonDict = encapJSON;
                AylaLanMessage *message = [[AylaLanMessage alloc] initWithMethod:AylaMessageMethodPOST urlString:path contents:jsonDict contextHandler:session];
                // Print out lan message - Debug level only
                AylaLogD(@"httpServer", 0, @"message:%@", message.contents);
                AylaMessageResponse *msgResponse = [sender didReceiveMessage:message];
                respStatusCode = (int)msgResponse.httpStatusCode;
            }
            
            NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
            AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:respStatusCode headerParam:headerDict dataParam:nil];
            
            [session setSessionState: UP];
            [session startTimer];
            
            AylaLogI(@"httpServer", 0, @"%@:%d, %@", @"httpCode", respStatusCode, @"httpResponseForMethod.post");
            return resp;
        }
    }
    else if ([method isEqualToString:@"GET"]) {
        
        int statusCode = 200;
        NSString *send = nil;

        AylaLanMessage *message = [[AylaLanMessage alloc] initWithMethod:AylaMessageMethodGET urlString:path contents:nil contextHandler:session];
        AylaMessageResponse *msgResp = [sender didReceiveMessage:message];
        AylaLanCommandEntity *command = msgResp.responseObject;
        
        if(command) {
            NSString *msg = [AylaLanCommandEntity encapsulateLanCommandWithCommandType:[command baseType] seqNo:[session nextSequenceNum] messageString:[command jsonString]];
            send = [encryption encryptEncapsulateSignWithPlaintext:msg sign:[encryption appSignKey]];
            statusCode = (int)msgResp.httpStatusCode;
            AylaLogI(@"httpServer", 0, @"%@:%d %@", @"statusCode", statusCode, @"httpResponseForMethod.commands");
            // Print out lan command - Debug level only
            AylaLogD(@"httpServer", 0, @"command:%@", command.jsonString);
        }
        else {
            NSString *msg = [AylaLanCommandEntity encapsulateLanCommandWithCommandType:AYLA_LAN_UNDEFINED seqNo:[session nextSequenceNum] messageString:@"{}"];
            send = [encryption encryptEncapsulateSignWithPlaintext:msg sign:[encryption appSignKey]];
            if([encryption appSignKey] == nil)
                statusCode = 400;
            else{
                statusCode = (int)msgResp.httpStatusCode;
            }
            AylaLogI(@"httpServer", 0, @"%@:%d, %@:%@, %@", @"httpCode", statusCode, @"resp", @"no content", @"httpResponseForMethod.commands");
        }
        
        NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
        NSData *respData = send!=nil?[send dataUsingEncoding:NSUTF8StringEncoding]:[@"[]" dataUsingEncoding:NSUTF8StringEncoding];
        
        AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:statusCode headerParam:headerDict dataParam:respData];
        return resp;
    }
    else{
        AylaLogE(@"httpServer", 0, @"%@:%d, %@:%d, %@", @"httpCode", 404, @"lanModeState", [sender lanModeState], @"httpResponseForMethod.commands");
        NSData *respData = [@"<html><head><head><body><h1>Unknown command</h1></body></html>" dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *headerDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"json/application", @"Content-Type", nil];
        AylaHttpResponce *resp = [[AylaHttpResponce alloc] initWithData:404 headerParam:headerDict dataParam:respData];
        return resp;
    }
    

	return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	// If we supported large uploads,
	// we might use this method to create/open files, allocate memory, etc.
}

- (void)processBodyData:(NSData *)postDataChunk
{
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	
	BOOL result = [request appendData:postDataChunk];
	if (!result)
	{
        AylaLogW(@"httpServer", 0, @"%@, %@", @"Couldn't append bytes", @"processBodyData");
	}
}

@end



@implementation AylaHttpResponce : HTTPDataResponse

int status;
NSDictionary * headers;


- (id)initWithData:(int)httpStatus headerParam:(NSDictionary *)headerParam dataParam:(NSData *)dataParam
{
	if((self = [super init]))
	{
		offset = 0;
		data = dataParam;
        if(headerParam!=nil)
            headers = headerParam;
        else
            headers = nil;
        status = httpStatus;
	}
	return self;
}

/**
 * Status code for response.
 * Allows for responses such as redirect (301), etc.
 **/
- (NSInteger)status
{
    return status;
}

/**
 * If you want to add any extra HTTP headers to the response,
 * simply return them in a dictionary in this method.
 **/
- (NSDictionary *)httpHeaders
{
    return headers;
};

/**
 * If you don't know the content-length in advance,
 * implement this method in your custom response class and return YES.
 *
 * Important: You should read the discussion at the bottom of this header.
 **/
//- (BOOL)isChunked;

/**
 * This method is called from the HTTPConnection class when the connection is closed,
 * or when the connection is finished with the response.
 * If your response is asynchronous, you should implement this method so you know not to
 * invoke any methods on the HTTPConnection after this method is called (as the connection may be deallocated).
 **/
//- (void)connectionDidClose;


@end


