//
//  AylaTriggerSupport.h
//  MDAiosdemo
//
//  Created by Yipei Wang on 5/9/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaApplicationTrigger(Support)

+ (NSOperation *) createTrigger:(AylaPropertyTrigger *)propertyTrigger applicationTrigger:(AylaApplicationTrigger *)applicationTrigger
               success:(void (^)(AylaResponse *response, AylaApplicationTrigger *ApplicationTriggerCreated))successBlock
               failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) getTriggers:(AylaPropertyTrigger *)propertyTrigger callParams:(NSDictionary *)callParams
             success:(void (^)(AylaResponse *response, NSMutableArray *applicationTrigger))successBlock
             failure:(void (^)(AylaError *err))failureBlock;


+ (NSOperation *) updateTrigger:(AylaPropertyTrigger *)propertyTrigger applicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                       success:(void (^)(AylaResponse *response, AylaApplicationTrigger *updatedApplicationTrigger))successBlock
                       failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) destroyTrigger:(AylaApplicationTrigger *)applicationTrigger
                success:(void (^)(AylaResponse *response))successBlock
                failure:(void (^)(AylaError *err))failureBlock;

@end