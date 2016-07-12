//
//  AylaScheduleActionSupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 7/8/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaScheduleAction (Support)
@property (nonatomic, copy) NSNumber *key;
@property (nonatomic, copy) NSNumber *scheduleId;

- (id) initScheduleActionWithType:(NSString *)type andDictionary:(NSDictionary *)scheduleActiondictionary;
- (NSDictionary *) buildScheduleActionDictionary;

- (NSOperation *)create:(AylaSchedule *)schedule
       success:(void (^)(AylaResponse *response, AylaScheduleAction *scheduleAction)) successBlock
       failure:(void (^)(AylaError *err)) failureBlock;

- (NSOperation *)update:(NSDictionary *)callParams
       success:(void (^)(AylaResponse *response, AylaScheduleAction *scheduleAction))successBlock
       failure:(void (^)(AylaError *err))failureBlock;

- (NSOperation *)delete:(NSDictionary *)callParams
        success:(void (^)(AylaResponse *response))successBlock
        failure:(void (^)(AylaError *err))failureBlock;
@end
