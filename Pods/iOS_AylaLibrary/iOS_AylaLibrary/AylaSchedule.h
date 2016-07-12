//
//  AylaSchedule.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 5/30/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaNetworks.h"
@class AylaDevice;
@class AylaScheduleAction;
@interface AylaSchedule : NSObject
@property (nonatomic, copy) NSString *name; // name of the schedule
@property (nonatomic, copy) NSString *direction; //input:to_device, output:from_device, required
@property (nonatomic, copy) NSNumber *active; // true/active by default, optional
@property (nonatomic, copy) NSNumber *utc; // true/utc tz by default, optional
@property (nonatomic, copy) NSString *displayName; // display name of the schedule

@property (nonatomic, copy) NSString *startDate; // yyyy-mm-dd inclusive, optional
@property (nonatomic, copy) NSString *endDate; // yyyy-mm-dd exclusive, optional
@property (nonatomic, copy) NSString *startTimeEachDay; // HH:mm:ss inclusive
@property (nonatomic, copy) NSString *endTimeEachDay; // HH:mm:ss exclusive, optional

@property (nonatomic, copy) NSArray *daysOfWeek; // 1-7 inclusive, 1 == Sunday, optional
@property (nonatomic, copy) NSArray *daysOfMonth; // 1-32 inclusive, 32 == last day of the month: 28, 29, 30, or 31, optional
@property (nonatomic, copy) NSArray *monthsOfYear; // 1-12 inclusive, 1 == January, optional
@property (nonatomic, copy) NSArray *dayOccurOfMonth; // 1-7 inclusive, 7 == last occurrence of the day in the month, optional

@property (nonatomic, copy) NSNumber *duration; // seconds, default == 0, optional
@property (nonatomic, copy) NSNumber *interval; // seconds, default == 0, optional

@property (nonatomic, copy) NSMutableArray *scheduleActions;

// only for testing -----------------------
- (void) createWithDevice:(AylaDevice *)device Name:(NSString *)name andActions:(NSMutableArray *)actions
                success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
                failure:(void (^)(AylaError *err))failureBlock;
- (void) delete:(NSDictionary *)callParams
                success:(void (^)(AylaResponse *response))successBlock
                failure:(void (^)(AylaError *err))failureBlock;
//------------------------------------------

- (NSOperation *) update:(AylaDevice *)device
            success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
            failure:(void (^)(AylaError *err))failureBlock;

- (NSOperation *) clear:(NSDictionary *)callParams
            success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
            failure:(void (^)(AylaError *err))failureBlock;

//TBD
- (NSOperation *) getAllActions:(NSDictionary *)callParams
            success:(void (^)(AylaResponse *response, NSArray *scheduleActions))successBlock
            failure:(void (^)(AylaError *err))failureBlock;

//TBD
- (NSOperation *) getActionsByName:(NSString *)name
               success:(void (^)(AylaResponse *response, NSArray *scheduleActions))successBlock
               failure:(void (^)(AylaError *err))failureBlock;

/**
 * The deleteAction method will destroy the Schedule Action associated with the Schedule object. Consider letting the device.updateSchedule method
 * delete Schedule Actions), or using the Full Template Scheduling model where action.active is set to false instead of being deleted. 
 * @param scheduleAction is the Shedule Action to be deleted.
 * @param success would be called with this assiciated Schedule when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) deleteAction:(AylaScheduleAction *)scheduleAction
             success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
             failure:(void (^)(AylaError *err))failureBlock;

/**
 * The createAction method will create a Schedule Action that is associated with the Schedule object. Consider letting the device.updateSchedule method
 * create Schedule Actions by passing in newly allocated scheduleAction object(s), or using the Full Template Scheduling model where actions are pre-defined.
 * @param scheduleAction is the Shedule Action to be created.
 * @param success would be called with the created Schedule Action when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) createAction:(AylaScheduleAction *)scheduleAction
             success:(void (^)(AylaResponse *response, AylaScheduleAction *scheduleAction))successBlock
             failure:(void (^)(AylaError *err))failureBlock;

/**
 * The updateAction method will update a Schedule Action that is associated with the Schedule object. Consider letting the device.updateSchedule method 
 * update Schedule Actions by passing in existing scheduleAction object(s), or using the Full Template Scheduling model.
 * @param scheduleAction is the Shedule Action set to desired values .
 * @param success would be called with updated Schedule Action when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) updateAction:(AylaScheduleAction *)scheduleAction
              success:(void (^)(AylaResponse *response, AylaScheduleAction *scheduleAction))successBlock
              failure:(void (^)(AylaError *err))failureBlock;

@end
