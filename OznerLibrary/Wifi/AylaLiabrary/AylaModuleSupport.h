//
//  AylaModuleSupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 3/20/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaModule(Support)
- (id)   initModuleWithDictionary:(NSDictionary *)dictionary;

- (void) setNewDeviceTime:(NSNumber*)curTime
                  success:(void (^)(AylaResponse *response))successBlock
                  failure:(void (^)(AylaError *err))failureBlock;

- (void) getNewDeviceDetail:
                /*success:*/(void (^)(AylaResponse *response, AylaModule *device))successBlock
                failure:(void (^)(AylaError *err))failureBlock;

+ (void) getNewDeviceScanForAPs:
                /*success:*/(void (^)(AylaResponse *response, NSMutableArray *apList))successBlock
                failure:(void (^)(AylaError *err))failureBlock;

+ (void) connectNewDeviceToService:(NSString *)ssid
               password:(NSString *)password optionalParams:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *response))successBlock
               failure:(void (^)(AylaError *err))failureBlock;

+ (void) confirmNewDeviceToServiceConnection:
                /*success:*/(void (^)(AylaResponse *response, NSDictionary *result))successBlock
                failure:(void (^)(AylaError *err))failureBlock;

+ (void) getNewDeviceWiFiStatus:
                /*success:*/(void (^)(AylaResponse *response, AylaWiFiStatus *result))successBlock
                failure:(void (^)(AylaError *err))failureBlock;
@end
