//
//  AylaScheduleAction.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 5/30/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaNetworks.h"

@class AylaSchedule;
@interface AylaScheduleAction : NSObject
@property (nonatomic, copy) NSString *type; // "SchedulePropertyAction", required
@property (nonatomic, copy) NSString *name; // associated property name, required
@property (nonatomic, copy) NSString *value; // value to set when fired, required
@property (nonatomic, copy) NSString *baseType; // string, integer, boolean, decimal, required

@property (nonatomic, copy) NSNumber *inRange; // true == fire action if time is in the range specified, false == fire on start/end date/time only, optional
@property (nonatomic, copy) NSNumber *atStart; // true == fire action if time is at the start of the range specified by the schedule, optional
@property (nonatomic, copy) NSNumber *atEnd; // true == fire action if time is at the end of the range specified by the schedule, optional
@property (nonatomic, copy) NSNumber *active; // true if this action is used in determining a firing action, optional

@end
