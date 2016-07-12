//
//  AylaSchedule.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 5/30/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaSchedule.h"
#import "AylaApiClient.h"
#import "AylaDeviceSupport.h"
#import "AylaScheduleActionSupport.h"
#import "AylaResponse.h"
#import "AylaError.h"
#import "AylaErrorSupport.h"
@interface AylaSchedule()
@property (nonatomic, copy) NSNumber *key; // owner device id
@end

@implementation AylaSchedule

@synthesize key = _key;
@synthesize name = _name;
@synthesize direction = _direction;
@synthesize active = _active;
@synthesize utc = _utc;
@synthesize displayName = _displayName;
@synthesize startDate = _startDate;
@synthesize endDate = _endDate;
@synthesize startTimeEachDay = _startTimeEachDay;
@synthesize endTimeEachDay = _endTimeEachDay;
@synthesize daysOfWeek = _daysOfWeek;
@synthesize daysOfMonth = _daysOfMonth;
@synthesize monthsOfYear = _monthsOfYear;
@synthesize dayOccurOfMonth = _dayOccurOfMonth;
@synthesize duration = _duration;
@synthesize interval = _interval;
@synthesize scheduleActions = _scheduleActions;


- (id)initScheduleWithDictionary:(NSDictionary *)scheduleDictionary
{
    self = [super init];
    if (self) {
        _key = [scheduleDictionary objectForKey:@"key"];
        _name = [scheduleDictionary objectForKey:@"name"];
        _active = [scheduleDictionary objectForKey:@"active"];
        _direction = [scheduleDictionary objectForKey: @"direction"];
        
        NSString *param = nil;
        param  = [scheduleDictionary objectForKey:@"display_name"];
        _displayName = param? param: nil;
        
        param  = [scheduleDictionary objectForKey:@"end_date"];
        _endDate = param == nil || [param isEqualToString:@""]? nil: param;
        
        param  = [scheduleDictionary objectForKey:@"start_date"];
        _startDate = param == nil || [param isEqualToString:@""]? nil: param;
        
        param  = [scheduleDictionary objectForKey:@"end_time_each_day"];
        _endTimeEachDay = param == nil || [param isEqualToString:@""]? nil: param;
        
        param  = [scheduleDictionary objectForKey:@"start_time_each_day"];
        _startTimeEachDay = param == nil || [param isEqualToString:@""]? nil: param;
        
        NSNumber *paramNum = [scheduleDictionary objectForKey:@"utc"];
        _utc = (paramNum == nil || [paramNum isEqual:[NSNull null]])? nil: paramNum;
        
        NSMutableArray *arr = nil;
        
        arr = [scheduleDictionary objectForKey:@"day_occur_of_month"];
        _dayOccurOfMonth = arr == (id)[NSNull null]? nil: arr;
        
        arr = [scheduleDictionary objectForKey:@"days_of_month"];
        _daysOfMonth = arr == (id)[NSNull null]? nil: arr;
        
        arr = [scheduleDictionary objectForKey:@"days_of_week"];
        _daysOfWeek = arr == (id)[NSNull null]? nil: arr;
        
        arr = [scheduleDictionary objectForKey:@"months_of_year"];
        _monthsOfYear = arr == (id)[NSNull null]? nil: arr;
        
        NSNumber *duration = [scheduleDictionary objectForKey:@"duration"];
        if(duration != nil &&
           duration != (id)[NSNull null]) {
            _duration = [duration copy];
        }
        NSNumber *interval = [scheduleDictionary objectForKey:@"interval"];
        if(interval != nil &&
           interval != (id)[NSNull null]) {
            _interval = [interval copy];
        }
        
        arr = [scheduleDictionary objectForKey:@"schedule_actions"];
        if([arr count]>0){
            _scheduleActions = [NSMutableArray new];
            for (NSDictionary *schedulActionDict in arr){
                AylaScheduleAction *scheduleAction = [[AylaScheduleAction alloc] initScheduleActionWithType:nil andDictionary:schedulActionDict];
                [_scheduleActions addObject:scheduleAction];
            }
        }
        else {
            _scheduleActions = nil;
        }
    }
    return self;
}


- (NSDictionary *)buildScheduleDictionaryWithDevice:(AylaDevice *)device andScheduleActions:(NSMutableArray *)actions forUpdate:(BOOL) toUpdate
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    if(_dayOccurOfMonth)
        [params setObject:_dayOccurOfMonth forKey:@"day_occur_of_month"];
    if(_daysOfMonth)
        [params setObject:_daysOfMonth forKey:@"days_of_month"];
    if(_daysOfWeek)
        [params setObject:_daysOfWeek forKey:@"days_of_week"];
    if(_monthsOfYear)
        [params setObject:_monthsOfYear forKey:@"months_of_year"];

    if ( device != nil )
        [params setObject:[device.key stringValue] forKey:@"device_id"];
    [params setObject:_name forKey:@"name"];
    [params setObject:_active forKey:@"active"];
    [params setObject:_direction forKey:@"direction"];

    if(_utc)
        [params setObject:[NSNumber numberWithBool:_utc.boolValue] forKey:@"utc"];
    else
        [params setObject:[NSNumber numberWithBool:NO] forKey:@"utc"];
    
    if(_displayName)
        [params setObject:_displayName forKey:@"display_name"];
    if(_duration)
        [params setObject:_duration forKey:@"duration"];
    else
        [params setObject:@"0" forKey:@"duration"];
    
    if(_interval)
        [params setObject:_interval forKey:@"interval"];
    else
        [params setObject:@"0" forKey:@"interval"];

    if(_endDate)
        [params setObject:_endDate forKey:@"end_date"];
    else
        [params setObject:@"" forKey:@"end_date"];

    if(_startDate)
        [params setObject:_startDate forKey:@"start_date"];
    else
        [params setObject:@"" forKey:@"start_date"];
    
    if(_endTimeEachDay)
        [params setObject:_endTimeEachDay forKey:@"end_time_each_day"];
    else
        [params setObject:@"" forKey:@"end_time_each_day"];
    
    [params setObject:_startTimeEachDay forKey:@"start_time_each_day"];
    
    NSMutableArray *scheduleActionsArray = [NSMutableArray new];
    if(actions){
        _scheduleActions = actions;
        
        for (AylaScheduleAction *schdAction in actions) {
            NSDictionary *schdActionDict = [schdAction buildScheduleActionDictionary];
            [scheduleActionsArray addObject:schdActionDict];
        }
    }
    [params setObject:scheduleActionsArray forKey:@"schedule_actions"];
    return params;
}


- (void)createWithDevice:(AylaDevice *)device Name:(NSString *)name andActions:(NSMutableArray *)actions
                 success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
                 failure:(void (^)(AylaError *err)) failureBlock;
{
    _name = name;
    NSString *path = [NSString stringWithFormat:@"devices/%@/schedules.json", [device.key stringValue]];

    NSMutableDictionary *errors =[NSMutableDictionary new];
    if (_name == nil) {
        [errors setObject:@"can't be blank" forKey:@"name"];
    }
    if (_startTimeEachDay == nil) {
        [errors setObject:@"can't be blank" forKey:@"startTimeEachDay"];
    }
    if (_direction == nil) {
        [errors setObject:@"can't be blank" forKey:@"direction"];
    }
    if ([_scheduleActions count] > DEFAULT_MAX_SCHEDULE_ACTIONS) {
        [errors setObject:@"too many actions" forKey:@"allocation"];
    }
    
    if ([errors count]>0) {
        AylaError *err = [AylaError new];
        err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.nativeErrorInfo = nil; err.errorInfo = errors;
        err.httpStatusCode = 0;
        failureBlock(err);
        return;
    }

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [params setObject:[device.key copy] forKey:@"device_id"];
    [params setObject:_name forKey:@"name"];
    [params setObject:_active forKey:@"active"];
    [params setObject:_direction forKey:@"direction"];
    
    if(_displayName)
        [params setObject:_displayName forKey:@"display_name"];
    
    if(_dayOccurOfMonth)
        [params setObject:_dayOccurOfMonth forKey:@"day_occur_of_month"];
    if(_daysOfMonth)
        [params setObject:_daysOfMonth forKey:@"days_of_month"];
    if(_daysOfWeek)
        [params setObject:_daysOfWeek forKey:@"days_of_week"];
    if(_monthsOfYear)
        [params setObject:_monthsOfYear forKey:@"months_of_year"];
    
    if(_duration)
        [params setObject:_duration forKey:@"duration"];
    if(_interval)
        [params setObject:_interval forKey:@"interval"];
    
    if(_endDate)
        [params setObject:_endDate forKey:@"end_date"];
    if(_startDate)
        [params setObject:_startDate forKey:@"start_date"];
    if(_endTimeEachDay)
        [params setObject:_endTimeEachDay forKey:@"end_time_each_day"];
    if(_utc)
        [params setObject:_utc forKey:@"utc"];
    
    [params setObject:_startTimeEachDay forKey:@"start_time_each_day"];
    
    NSMutableArray *scheduleActionsArray = [NSMutableArray new];
    if(actions){
        _scheduleActions = actions;
        
        for (AylaScheduleAction *schdAction in actions) {
            NSDictionary *schdActionDict = [schdAction buildScheduleActionDictionary];
            [scheduleActionsArray addObject:schdActionDict];
        }
    }
    [params setObject:scheduleActionsArray forKey:@"schedule_actions"];
    
    NSDictionary *sendParams = [[NSDictionary alloc] initWithObjectsAndKeys:params, @"schedule", nil];
    [[AylaApiClient sharedDeviceServiceInstance] postPath: path parameters: sendParams
                success:^(AylaHTTPOperation *operation, id response) {
                    NSDictionary *resp = (NSDictionary *)response;
                    NSDictionary *schd = [resp objectForKey:@"schedule"];
                    _key = [[schd objectForKey:@"key"] copy];
                    _daysOfWeek = [[schd objectForKey:@"days_of_week"] copy];
                    _daysOfMonth = [[schd objectForKey:@"days_of_month"] copy];
                    _monthsOfYear = [[schd objectForKey:@"months_of_year"] copy];
                    id dayOccurOfMonth = [schd objectForKey:@"day_occur_of_month"];
                    if (dayOccurOfMonth!=nil && dayOccurOfMonth != [NSNull null]) {
                        _dayOccurOfMonth = [dayOccurOfMonth copy];
                    }
                    saveToLog(@"%@, %@, %@:%ld, %@:%@, %@", @"I", @"Schedule",
                              @"statusCode", (long)operation.response.httpStatusCode, @"success", @"null", @"schedule.create");
                    
                    successBlock(operation.response, self);
                }
                failure:^(AylaHTTPOperation *operation, AylaError *error) {
                    
                    saveToLog(@"%@, %@, %@:%ld, %@:%@, %@", @"E", @"Schedule",
                              @"httpStatusCode", (long)operation.response.httpStatusCode, @"response", operation.responseObject, @"schedule.create");
                    NSMutableDictionary *errList;
                    if(operation.responseObject){
                        error.errorCode = AML_USER_INVALID_PARAMETERS;
                        NSDictionary *errors = [operation.responseObject objectForKey:@"errors"];
                        NSArray *arr;
                        errList = [[NSMutableDictionary alloc] init];
                        
                        for(NSString* key in errors){
                            arr = [errors objectForKey:key];
                            [errList setObject:[arr objectAtIndex:0] forKey:key];
                        }
                        error.nativeErrorInfo = nil;
                        error.errorInfo = errList;
                    }
                    else{
                        error.errorCode = 1;
                        error.errorInfo = nil;
                    }
                    failureBlock(error);
                }
     ];
}

- (NSOperation *)getAll:(AylaDevice *)device
       success:(void (^)(AylaResponse *response, NSMutableArray *schedules))successBlock
       failure:(void (^)(AylaError *err))failureBlock
{
    NSString *path = [NSString stringWithFormat:@"devices/%@/schedules.json",[device.key copy]];
    return [[AylaApiClient sharedDeviceServiceInstance] getPath:path parameters:nil
              success:^(AylaHTTPOperation *operation, id response) {

                  NSArray *respArr = (NSArray *)response;
                  saveToLog(@"%@, %@, %@:%lu, %@:%@ %@", @"I", @"Schedule",
                            @"count", (unsigned long)[respArr count], @"success",@"null", @"schedule.getAll");
                  NSMutableArray *schedules = [NSMutableArray new];
                  for (NSDictionary *scheduleDict in respArr) {
                      AylaSchedule *schd = [[AylaSchedule alloc] initScheduleWithDictionary:[scheduleDict objectForKey:@"schedule"]];
                      [schedules addObject:schd];
                  }
                  successBlock(operation.response, schedules);
              }
              failure:^(AylaHTTPOperation *operation, AylaError *error) {
                  saveToLog(@"%@, %@, %@, %@", @"E", @"Schedule",
                            error.logDescription, @"schedule.getAll");
                  failureBlock(error);
              }
     ];
}

- (NSOperation *)getByName:(NSString *)name device:(AylaDevice *)device
           success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
           failure:(void (^)(AylaError *err))failureBlock
{
    NSString *path = [NSString stringWithFormat:@"devices/%@/schedules/find_by_name.json?name=%@", device.key, [name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return [[AylaApiClient sharedDeviceServiceInstance] getPath:path parameters:nil
             success:^(AylaHTTPOperation *operation, id response) {
                 NSDictionary *respDict = (NSDictionary *)response;
                 NSDictionary *dict = [respDict objectForKey:@"schedule"];
                 
                 successBlock(operation.response, [[AylaSchedule alloc] initScheduleWithDictionary:dict]);
             }
             failure:^(AylaHTTPOperation *operation, AylaError *error) {
                 
                 saveToLog(@"%@, %@, %@, %@", @"E", @"Schedule",
                           error.logDescription, @"schedule.getByName");
                 failureBlock(error);
             }
     ];
}

- (NSOperation *)update:(AylaDevice *)device
       success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
       failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableDictionary *errors =[NSMutableDictionary new];
    if (_name == nil) {
        [errors setObject:@"can't be blank" forKey:@"name"];
    }
    if (_startTimeEachDay == nil) {
        [errors setObject:@"can't be blank" forKey:@"startTimeEachDay"];
    }
    if (_direction == nil) {
        [errors setObject:@"can't be blank" forKey:@"direction"];
    }
    if ([_scheduleActions count] > DEFAULT_MAX_SCHEDULE_ACTIONS) {
        [errors setObject:@"too many actions" forKey:@"allocation"];
    }
    
    if ([errors count]>0) {
        AylaError *err = [AylaError new];
        err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.nativeErrorInfo = nil; err.errorInfo = errors;
        err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    
    bool doUpdate = YES;
    if (_scheduleActions != nil && [_scheduleActions count]>0) {
        AylaScheduleAction *action = [_scheduleActions objectAtIndex:0];
        if(action.key == nil) {
            doUpdate = NO;
        }
    }
    
    if (doUpdate) {
        NSDictionary *scheduleDict = [self buildScheduleDictionaryWithDevice:device andScheduleActions:self.scheduleActions forUpdate:YES];
        NSDictionary *sendParams = [[NSDictionary alloc] initWithObjectsAndKeys:scheduleDict, @"schedule", nil];
        NSString *path = [NSString stringWithFormat:@"devices/%@/schedules/%@.json", device.key, self.key];
        return [[AylaApiClient sharedDeviceServiceInstance] putPath:path parameters: sendParams
                     success:^(AylaHTTPOperation *operation, id response) {
                         NSDictionary *resp = (NSDictionary *)response;
                         NSDictionary *dict = [resp objectForKey:@"schedule"];

                         successBlock(operation.response, [[AylaSchedule alloc] initScheduleWithDictionary:dict]);
                     }
                     failure:^(AylaHTTPOperation *operation, AylaError *error) {
                         
                         saveToLog(@"%@, %@, %@, %@", @"E", @"Schedule",
                                   error.logDescription, @"schedule.update");
                         NSMutableDictionary *errList;
                         if(operation.responseObject){
                             error.errorCode = AML_USER_INVALID_PARAMETERS;
                             NSDictionary *errors = operation.responseObject;
                             NSArray *arr;
                             errList = [[NSMutableDictionary alloc] init];
                             
                             for(NSString* key in errors){
                                 arr = [errors objectForKey:key];
                                 [errList setObject:[arr objectAtIndex:0] forKey:key];
                             }
                             error.nativeErrorInfo = nil;
                             error.errorInfo = errList;
                         }
                         else{
                             error.errorCode = 1;
                             error.errorInfo = nil;
                         }
                         failureBlock(error);
                     }
         ];
    }
    else {
        // To support dynamic schedules
        NSMutableArray *actions = [_scheduleActions copy];
        long totalCount = [actions count];
        __block long actionCounter = 0;
        _scheduleActions = nil;
        
        for(AylaScheduleAction *action in actions) {
            
            [self createAction:action success:^(AylaResponse *response, AylaScheduleAction *scheduleAction) {
                    actionCounter++;
                    if(actionCounter == totalCount) {
                        actionCounter ++ ;
                        double delayInSeconds = 1.0;
                        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                            NSDictionary *scheduleDict = [self buildScheduleDictionaryWithDevice:device andScheduleActions:nil forUpdate:YES];
                            NSDictionary *sendParams = [[NSDictionary alloc] initWithObjectsAndKeys:scheduleDict, @"schedule", nil];
                            NSString *path = [NSString stringWithFormat:@"devices/%@/schedules/%@.json", device.key, self.key];
                            [[AylaApiClient sharedDeviceServiceInstance] putPath:path parameters: sendParams
                                             success:^(AylaHTTPOperation *operation, id response) {
                                                 NSDictionary *resp = (NSDictionary *)response;
                                                 NSDictionary *dict = [resp objectForKey:@"schedule"];

                                                 successBlock(operation.response, [[AylaSchedule alloc] initScheduleWithDictionary:dict]);
                                             }
                                             failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                 saveToLog(@"%@, %@, %@, %@", @"E", @"Schedule",
                                                           error.logDescription, @"schedule.update");

                                                 NSMutableDictionary *errList;
                                                 if(operation.responseObject){
                                                     error.errorCode = AML_USER_INVALID_PARAMETERS;
                                                     NSDictionary *errors = operation.responseObject;
                                                     NSArray *arr;
                                                     errList = [[NSMutableDictionary alloc] init];
                                                     
                                                     for(NSString* key in errors){
                                                         arr = [errors objectForKey:key];
                                                         [errList setObject:[arr objectAtIndex:0] forKey:key];
                                                     }
                                                     error.errorInfo = errList;
                                                 }
                                                 else{
                                                     error.errorCode = 1;
                                                     error.errorInfo = nil;
                                                 }
                                                 failureBlock(error);
                                             }
                             ];
                        });
                    }
                } failure:^(AylaError *err) {
                    if (actionCounter < totalCount) {
                        actionCounter = totalCount;
                        failureBlock(err);
                    }
                }];
        }
    }
    return nil;
}

- (NSOperation *) getAllActions:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *response, NSArray *scheduleActions))successBlock
               failure:(void (^)(AylaError *err))failureBlock
{
    NSString *path = [NSString stringWithFormat:@"schedules/%@/schedule_actions.json", _key];
    return [[AylaApiClient sharedDeviceServiceInstance] getPath:path parameters: nil
             success:^(AylaHTTPOperation *operation, id response) {
                 NSArray *actionsArray = (NSArray *)response;
                 if([actionsArray count] == 0) {

                     successBlock(operation.response, actionsArray);
                 }
                 else {
                     NSMutableArray *newActions = [NSMutableArray new];
                     for(NSDictionary *dict in actionsArray) {
                         NSDictionary *info = [dict objectForKey:@"schedule_action"];
                         AylaScheduleAction *action = [[AylaScheduleAction alloc] initScheduleActionWithType:nil andDictionary:info];
                         [newActions addObject:action];
                     }
                     _scheduleActions = newActions;

                     successBlock(operation.response, newActions);
                 }
             }
             failure:^(AylaHTTPOperation *operation, AylaError *error) {
                 saveToLog(@"%@, %@, %@, %@", @"E", @"Schedule",
                           error.logDescription, @"schedule.getAllActions");
                 failureBlock(error);
             }
     ];
}


- (NSOperation *) getActionsByName:(NSString *)name
                  success:(void (^)(AylaResponse *response, NSArray *scheduleActions))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    NSString *path = [NSString stringWithFormat:@"schedules/%@/schedule_actions/find_by_name.json?name=%@", _key, name];
    return [[AylaApiClient sharedDeviceServiceInstance] getPath:path parameters: nil
                                                 success:^(AylaHTTPOperation *operation, id response) {
                                                     NSArray *actionsArray = (NSArray *)response;
                                                     if([actionsArray count] == 0) {
                                                         successBlock(operation.response, actionsArray);
                                                     }
                                                     else {
                                                         NSMutableArray *newActions = [NSMutableArray new];
                                                         for(NSDictionary *dict in actionsArray) {
                                                             NSDictionary *info = [dict objectForKey:@"schedule_action"];
                                                             AylaScheduleAction *action = [[AylaScheduleAction alloc] initScheduleActionWithType:nil andDictionary:info];
                                                             [newActions addObject:action];
                                                         }
                                                         _scheduleActions = newActions;

                                                         successBlock(operation.response, newActions);
                                                     }
                                                 }
                                                 failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                     saveToLog(@"%@, %@, %@, %@", @"E", @"Schedule",
                                                              error.logDescription, @"schedule.getActionsByName");
                                                     failureBlock(error);
                                                 }
     ];

}



- (NSOperation *)createAction:(AylaScheduleAction *)scheduleAction
             success:(void (^)(AylaResponse *response, AylaScheduleAction *scheduleAction))successBlock
             failure:(void (^)(AylaError *err))failureBlock
{
    return [scheduleAction create:self success:^(AylaResponse *response, AylaScheduleAction *createdScheduleAction) {
        // Add schdule action to schedule instance
        if(_scheduleActions == nil){
            _scheduleActions = [NSMutableArray new];
        }
        [_scheduleActions addObject:createdScheduleAction];
        successBlock(response, createdScheduleAction);
    } failure:^(AylaError *err) {
        failureBlock(err);
    }];
}


- (NSOperation *)deleteAction:(AylaScheduleAction *)scheduleAction
             success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
             failure:(void (^)(AylaError *err))failureBlock
{
    return [scheduleAction delete:nil
        success:^(AylaResponse *response){
            NSUInteger index = 0;
            for(AylaScheduleAction *act in self.scheduleActions){
                if([act.key intValue] == [scheduleAction.key intValue]) {
                    [self.scheduleActions removeObjectAtIndex:index];
                    break;
                }
                index++;
            }
            successBlock(response, self);
        }
        failure:^(AylaError *err) {
            failureBlock(err);
        }];
}

- (NSOperation *)updateAction:(AylaScheduleAction *)scheduleAction
              success:(void (^)(AylaResponse *response, AylaScheduleAction *scheduleAction))successBlock
              failure:(void (^)(AylaError *err))failureBlock
{
    return [scheduleAction update:nil success:^(AylaResponse *response, AylaScheduleAction *updatedScheduleAction) {
            successBlock(response, updatedScheduleAction);
        } failure:^(AylaError *err) {
            failureBlock(err);
        }];
}

- (void)delete:(NSDictionary *)callParams
        success:(void (^)(AylaResponse *response))successBlock
        failure:(void (^)(AylaError *err))failureBlock
{
    NSString *path = [NSString stringWithFormat:@"schedules/%@.json", self.key];
    [[AylaApiClient sharedDeviceServiceInstance] deletePath: path parameters: nil
              success:^(AylaHTTPOperation *operation, id response) {
                  saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"I", @"Schedule",
                            @"statusCode", (long)operation.response.httpStatusCode, @"success",@"null", @"schedule.delete");

                  successBlock(operation.response);
              }
              failure:^(AylaHTTPOperation *operation, AylaError *error) {
                  saveToLog(@"%@, %@, %@, %@", @"E", @"User",
                            error.logDescription, @"schedule.delete");
                  NSMutableDictionary *errList;
                  if(operation.responseObject){
                      error.errorCode = AML_USER_INVALID_PARAMETERS;
                      NSDictionary *errors = [operation.responseObject objectForKey:@"errors"];
                      NSArray *arr;
                      errList = [[NSMutableDictionary alloc] init];
                      
                      for(NSString* key in errors){
                          arr = [errors objectForKey:key];
                          [errList setObject:[arr objectAtIndex:0] forKey:key];
                      }
                      error.nativeErrorInfo = nil;
                      error.errorInfo = errList;
                  }
                  else{
                      error.errorCode = 1;
                      error.errorInfo = nil;
                  }
                  failureBlock(error);
              }
     ];
}


- (NSOperation *)clear:(NSDictionary *)callParams
       success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
       failure:(void (^)(AylaError *err))failureBlock
{
    NSString *path = [NSString stringWithFormat:@"schedules/%@/clear.json", self.key];
    return [[AylaApiClient sharedDeviceServiceInstance] putPath:path parameters:nil
                    success:^(AylaHTTPOperation *operation, id response) {
                        saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"I", @"Schedule",
                                  @"statusCode", (long)operation.response.httpStatusCode, @"success",@"null", @"schedule.clear");
                        self.scheduleActions = nil;
                        successBlock(operation.response, self);
                    }
                    failure:^(AylaHTTPOperation *operation, AylaError *error) {
                        saveToLog(@"%@, %@, %@, %@", @"E", @"Schedule",
                                  error.logDescription, @"schedule.delete");
                        failureBlock(error);
                    }
     ];
}



//-------------------------Helper methods -------------------------------------
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaSchedule *_copy = copy;
        _copy.key = [_key copy];
        _copy.name = [_name copy];
        _copy.direction = [_direction copy];
        _copy.active = [_active copy];
        _copy.utc = [_utc copy];
        _copy.displayName = [_displayName copy];
        _copy.startDate = [_startDate copy];
        _copy.endDate = [_endDate copy];
        _copy.startTimeEachDay = [_startTimeEachDay copy];
        _copy.endTimeEachDay = [_endTimeEachDay copy];
        _copy.dayOccurOfMonth = [_dayOccurOfMonth copy];
        _copy.daysOfMonth = [_daysOfMonth copy];
        _copy.daysOfWeek = [_daysOfWeek copy];
        _copy.monthsOfYear = [_monthsOfYear copy];
        _copy.duration = [_duration copy];
        _copy.interval = [_interval copy];
        _copy.scheduleActions = [_scheduleActions copy];
    }
    return copy;
}


@end
