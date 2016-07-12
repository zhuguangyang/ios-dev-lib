//
//  AylaDatum.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 2/14/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaDatum.h"
#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaErrorSupport.h"
#import "AylaHTTPOperation.h"
@interface AylaDatum ()

@property (strong, readwrite, nonatomic) NSString *createdAt;
@property (strong, readwrite, nonatomic) NSString *updatedAt;

@end


@implementation AylaDatum

- (id)initWithDicitionary:(NSDictionary *)dict
{
    self = [super init];
    if(self) {
        NSDictionary *dictionary = [dict objectForKey:@"datum"];
        if(dictionary) {
            self.key = [dictionary objectForKey:@"key"];
            self.value = [dictionary objectForKey:@"value"];
            self.updatedAt = [dictionary objectForKey:@"updated_at"];
            self.createdAt = [dictionary objectForKey:@"created_at"];
        }
    }
    return self;
}

- (id)initWithKey:(NSString *)key andValue:(NSString *)value
{
    self = [super init];
    if(self) {
        self.key = key;
        self.value = value;
    }
    return self;
}

+ (NSOperation *)createWithObject:(id)object andDatum:(AylaDatum *)datum
          success:(void (^)(AylaResponse *resp, AylaDatum *data))successBlock
          failure:(void (^)(AylaError *error))failureBlock
{
    AylaApiClient *client;
    NSString *url;
    NSMutableDictionary *errors = [NSMutableDictionary new];

    if([object isKindOfClass:AylaDevice.class]) {
        
        // device mdata
        // https://ads-dev.aylanetworks.com/apiv1/dsns/<dsn>/data.json
        
        AylaDevice *device = object;
        
        if(!device ||
           !device.dsn) {
            [errors setObject:@"is invalid" forKey:@"device"];
        }
        client = [AylaApiClient sharedDeviceServiceInstance];
        url = [NSString stringWithFormat:@"dsns/%@/data.json", device.dsn];
        
    }
    else if ([object isKindOfClass:AylaUser.class]) {
        
        // user mdata
        // https://user.aylanetworks.com/api/v1/users/data.json
        
        client = [AylaApiClient sharedUserServiceInstance];
        url = [NSString stringWithFormat:@"api/v1/users/data.json"];
        
    }
    else {
        [errors setObject:@"is invalid" forKey:@"class"];
    }
    
    if(!datum.key ||
       datum.key == (id)[NSNull null] ||
       [datum.key isEqualToString:@""]) {
        [errors setObject:@"is invalid" forKey:@"key"];
    }
    
    if(!datum.value){
       [errors setObject:@"is invalid" forKey:@"value"];
    }
    
    if (errors.count > 0) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:Nil andErrorInfo:errors];
        failureBlock(error);
        return nil;
    }
    
    return [client postPath:url parameters:[self toServiceFormat:datum withKey:YES]
        success:^(AylaHTTPOperation *operation, id responseObject) {
            AylaDatum * created = [[AylaDatum alloc] initWithDicitionary:responseObject];
            successBlock(operation.response, created);
        } failure:^(AylaHTTPOperation *operation, AylaError *error) {
            failureBlock(error);
        }];
}

+ (NSOperation *)getWithObject:(id)object andKey:(NSString *)key
              success:(void (^)(AylaResponse *resp, AylaDatum *data))successBlock
              failure:(void (^)(AylaError *error))failureBlock
{
    AylaApiClient *client;
    NSString *url;
    NSMutableDictionary *errors = [NSMutableDictionary new];
    
    if([object isKindOfClass:AylaDevice.class]) {
        
        // device mdata
        // https://ads-dev.aylanetworks.com/apiv1/dsns/<dsn>/data/<key>.json
        
        AylaDevice *device = object;
        
        if(!device ||
           !device.dsn) {
            [errors setObject:@"is invalid" forKey:@"device"];
        }
        
        client = [AylaApiClient sharedDeviceServiceInstance];
        url = [NSString stringWithFormat:@"dsns/%@/data/%@.json", device.dsn, key];
        
    }
    else if ([object isKindOfClass:AylaUser.class]) {
        
        // user mdata
        // https://user.aylanetworks.com/api/v1/users/data.json
        
        client = [AylaApiClient sharedUserServiceInstance];
        url = [NSString stringWithFormat:@"api/v1/users/data/%@.json", key];
    }
    else {
        [errors setObject:@"is invalid" forKey:@"class"];
    }
    
    if (errors.count > 0) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:Nil andErrorInfo:errors];
        failureBlock(error);
        return nil;
    }
    
    return [client getPath:url parameters:nil success:^(AylaHTTPOperation *operation, id responseObject) {
        AylaDatum * aDatum = [[AylaDatum alloc] initWithDicitionary:responseObject];
        successBlock(operation.response, aDatum);
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        failureBlock(error);
    }];
}


+ (NSOperation *)getWithObject:(id)object andParams:(NSDictionary *)callParams
                       success:(void (^)(AylaResponse *resp, NSArray *datums))successBlock
                       failure:(void (^)(AylaError *error))failureBlock
{
    AylaApiClient *client;
    NSString *url;
    NSMutableDictionary *errors = [NSMutableDictionary new];
    
    if([object isKindOfClass:AylaDevice.class]) {
        // NOT SUPPORTED BY SERVICE
        // device mdata
        // https://ads-dev.aylanetworks.com/apiv1/dsns/<dsn>/data/<key>.json
        
        AylaDevice *device = object;
        
        if(!device ||
           !device.dsn) {
            [errors setObject:@"is invalid" forKey:@"device"];
        }
        
        client = [AylaApiClient sharedDeviceServiceInstance];
        //url = [NSString stringWithFormat:@"dsns/%@/data/%@.json", device.dsn, key];
        
    }
    else if ([object isKindOfClass:AylaUser.class]) {
        
        // user mdata
        // https://user.aylanetworks.com/api/v1/users/data.json
        
        client = [AylaApiClient sharedUserServiceInstance];
        url = @"api/v1/users/data.json";
        
    }
    else {
        [errors setObject:@"is invalid" forKey:@"class"];
    }
    
    if (errors.count > 0) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:Nil andErrorInfo:errors];
        failureBlock(error);
        return nil;
    }
    
    NSDictionary *params = nil;
    if([callParams objectForKey:@"filters"]) {
        
        NSArray *keys = [callParams objectForKey:@"filters"];
        
        if((keys.count == 1) &&
           [[keys objectAtIndex:0] rangeOfString:@"%"].location!= NSNotFound) {
            
            params = @{@"keys": [keys objectAtIndex:0]};
        }
        else {
            params = @{@"keys": keys};
        }
    }
    
    return [client getPath:url parameters:params success:^(AylaHTTPOperation *operation, id responseObject) {
        NSMutableArray *datums = [NSMutableArray new];
        for(NSDictionary *aDatumInDict in responseObject) {
            AylaDatum * aDatum = [[AylaDatum alloc] initWithDicitionary:aDatumInDict];
            [datums addObject:aDatum];
        }
        successBlock(operation.response, datums);
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        failureBlock(error);
    }];
}

+ (NSOperation *)updateWithObject:(id)object andDatum:(AylaDatum *)datum
                 success:(void (^)(AylaResponse *resp, AylaDatum *data))successBlock
                 failure:(void (^)(AylaError *error))failureBlock
{
    AylaApiClient *client;
    NSString *url;
    NSMutableDictionary *errors = [NSMutableDictionary new];
    
    if([object isKindOfClass:AylaDevice.class]) {
        
        // device mdata
        // https://ads-dev.aylanetworks.com/apiv1/dsns/<dsn>/data/<key>.json
        
        AylaDevice *device = object;
        if(!device ||
           !device.dsn) {
            [errors setObject:@"is invalid" forKey:@"device"];
        }
        
        client = [AylaApiClient sharedDeviceServiceInstance];
        url = [NSString stringWithFormat:@"dsns/%@/data/%@.json", device.dsn, datum.key];
        
    }
    else if ([object isKindOfClass:AylaUser.class]) {
        
        // user mdata
        // https://user.aylanetworks.com/api/v1/users/data/akey.json
        
        client = [AylaApiClient sharedUserServiceInstance];
        url = [NSString stringWithFormat:@"api/v1/users/data/%@.json", datum.key];
        
    }
    else {
        [errors setObject:@"is invalid" forKey:@"class"];
    }
    
    if(!datum.key ||
       datum.key == (id)[NSNull null] ||
       [datum.key isEqualToString:@""]) {
        [errors setObject:@"is invalid" forKey:@"key"];
    }
    
    if(!datum.value){
        [errors setObject:@"is invalid" forKey:@"value"];
    }
    
    if (errors.count > 0) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:Nil andErrorInfo:errors];
        failureBlock(error);
        return nil;
    }
    
    return [client putPath:url
                parameters:[AylaDatum toServiceFormat:datum withKey:NO]
                success:^(AylaHTTPOperation *operation, id responseObject) {
                    AylaDatum * aDatum = [[AylaDatum alloc] initWithDicitionary:responseObject];
                    successBlock(operation.response, aDatum);
                } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                    failureBlock(error);
                }];
}


+ (NSOperation *)deleteWithObject:(id)object andDatum:(AylaDatum *)datum
                 success:(void (^)(AylaResponse *resp))successBlock
                 failure:(void (^)(AylaError *error))failureBlock
{
    AylaApiClient *client;
    NSString *url;
    NSMutableDictionary *errors = [NSMutableDictionary new];
    
    if([object isKindOfClass:AylaDevice.class]) {
        
        // device mdata
        // https://ads-dev.aylanetworks.com/apiv1/dsns/<key>/data/<key>.json
        
        AylaDevice *device = object;
        if(!device ||
           !device.dsn) {
            [errors setObject:@"is invalid" forKey:@"device"];
        }
        
        client = [AylaApiClient sharedDeviceServiceInstance];
        url = [NSString stringWithFormat:@"dsns/%@/data/%@.json", device.dsn, datum.key];
        
    }
    else if ([object isKindOfClass:AylaUser.class]) {
        
        // user mdata
        // https://user.aylanetworks.com/api/v1/users/data/akey.json
        
        client = [AylaApiClient sharedUserServiceInstance];
        url = [NSString stringWithFormat:@"api/v1/users/data/%@.json", datum.key];
        
    }
    else {
        [errors setObject:@"is invalid" forKey:@"class"];
    }
    
    if(!datum.key ||
       datum.key == (id)[NSNull null] ||
       [datum.key isEqualToString:@""]) {
        [errors setObject:@"is invalid" forKey:@"key"];
    }
    
    if(!datum.value){
        [errors setObject:@"is invalid" forKey:@"value"];
    }
    
    if (errors.count > 0) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:Nil andErrorInfo:errors];
        failureBlock(error);
        return nil;
    }
    
    return [client deletePath:url
                parameters:nil
                   success:^(AylaHTTPOperation *operation, id responseObject) {
                       successBlock(operation.response);
                   } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                       failureBlock(error);
                   }];

}

+ (NSDictionary *)toServiceFormat:(AylaDatum *)datum withKey:(BOOL)withKey
{
    NSDictionary *dict = withKey?
                            @{
                              @"key": datum.key,
                              @"value": datum.value
                            } :
                            @{
                              @"value": datum.value
                            };
    return @{
             @"datum": dict
             };
}

@end
