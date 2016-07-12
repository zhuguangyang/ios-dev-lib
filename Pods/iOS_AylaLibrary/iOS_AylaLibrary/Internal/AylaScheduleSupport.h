//
//  AylaScheduleSupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 6/11/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaSchedule(Support)
@property (nonatomic, copy) NSNumber *key; // owner device id

- (NSOperation *) getAll:(AylaDevice *)device
        success:(void (^)(AylaResponse *response, NSMutableArray *schedules))successBlock
        failure:(void (^)(AylaError *err))failureBlock;

- (NSOperation *) getByName:(NSString *)name device:(AylaDevice *)device
           success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
           failure:(void (^)(AylaError *err))failureBlock;

@end
