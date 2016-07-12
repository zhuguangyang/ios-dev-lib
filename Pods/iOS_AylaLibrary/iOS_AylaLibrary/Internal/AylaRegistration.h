//
//  AylaRegistration.h
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 8/29/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AylaDeviceGateway;
@interface AylaRegistration : NSObject

+ (void) registerNewDevice:(AylaDevice *)targetDevice
                   success:(void (^)(AylaResponse *response, AylaDevice *registeredDevice))successBlock
                   failure:(void (^)(AylaError *err))failureBlock;

+ (void) getRegistrationCandidateWithDsn:(NSString *)targetDsn andRegistrationType:(NSString *)targetRegType
                                 params:(NSDictionary *)callParams
                                success:(void (^)(AylaDevice *regCandidate))successBlock
                                failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) getRegistrationCandidatesWithDsn:(NSString *)targetDsn andRegistrationType:(NSString *)targetRegType
                                  params:(NSDictionary *)callParams
                                 success:(void (^)(AylaResponse *resp, NSArray *candidates))successBlock
                                 failure:(void (^)(AylaError *err))failureBlock;

+ (void) getModuleRegistrationToken:(NSString *)params
                            success:(void (^)(NSString *regToken))successBlock
                            failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) openRegistrationWindow:(AylaDeviceGateway *)gateway params:(NSDictionary *)callParams
                                 success:(void (^)(AylaResponse *response))successBlock
                                 failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) closeRegistrationWindow:(AylaDeviceGateway *)gateway params:(NSDictionary *)callParams
                                  success:(void (^)(AylaResponse *response))successBlock
                                  failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) registerDevice:(NSString *)dsn regToken:(NSString *)regToken setupToken:(NSString*) setupToken
                success:(void (^)(AylaResponse *response, AylaDevice *registeredDevice))successBlock
                failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) unregisterDevice:(AylaDevice *)device callParams:(NSDictionary *)callParams
                  success:(void (^)(AylaResponse *response))successBlock
                  failure:(void (^)(AylaError *err))failureBlock;
@end

