//
//  AylaDatum.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 2/14/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AylaResponse;
@class AylaError;
@interface AylaDatum : NSObject

@property (copy, nonatomic) NSString *key;
@property (strong, nonatomic) NSString *value;

@property (strong, readonly, nonatomic) NSString *createdAt;
@property (strong, readonly, nonatomic) NSString *updatedAt;

- (id)initWithKey:(NSString *)key andValue:(id)value;

+ (NSOperation *)createWithObject:(id)object andDatum:(AylaDatum *)datum
                          success:(void (^)(AylaResponse *resp, AylaDatum *data))successBlock
                          failure:(void (^)(AylaError *error))failureBlock;

+ (NSOperation *)getWithObject:(id)object andKey:(NSString *)key
                 success:(void (^)(AylaResponse *resp, AylaDatum *data))successBlock
                 failure:(void (^)(AylaError *error))failureBlock;

+ (NSOperation *)getWithObject:(id)object andParams:(NSDictionary *)callParams
                       success:(void (^)(AylaResponse *resp, NSArray *datums))successBlock
                       failure:(void (^)(AylaError *error))failureBlock;

+ (NSOperation *)updateWithObject:(id)object andDatum:(AylaDatum *)datum
                 success:(void (^)(AylaResponse *resp, AylaDatum *data))successBlock
                 failure:(void (^)(AylaError *error))failureBlock;

+ (NSOperation *)deleteWithObject:(id)object andDatum:(AylaDatum *)datum
                 success:(void (^)(AylaResponse *resp))successBlock
                 failure:(void (^)(AylaError *error))failureBlock;

@end
