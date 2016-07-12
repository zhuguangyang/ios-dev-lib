//
//  AylaScheduleAction.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 5/30/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaScheduleAction.h"
#import "AylaApiClient.h"
#import "AylaScheduleSupport.h"
#import "AylaErrorSupport.h"

@interface AylaScheduleAction()
@property (nonatomic, copy) NSNumber *key;
@property (nonatomic, copy) NSNumber *scheduleId;
@end

@implementation AylaScheduleAction
@synthesize type = _type;
@synthesize name = _name;
@synthesize value = _value;
@synthesize baseType = _baseType;
@synthesize inRange = _inRange;
@synthesize atStart = _atStart;
@synthesize atEnd = _atEnd;
@synthesize active = _active;
@synthesize key = _key;

@synthesize scheduleId = _scheduleId;

- (id) initScheduleActionWithType:(NSString *)type andDictionary:(NSDictionary *)scheduleActiondictionary
{
    self = [super init];
    if (self) {
        _baseType = [scheduleActiondictionary objectForKey:@"base_type"];
        
        if([_baseType isEqualToString:@"boolean"] ||
           [_baseType isEqualToString:@"integer"] ||
           [_baseType isEqualToString:@"decimal"]) {
            _value = [[scheduleActiondictionary objectForKey:@"value"] stringValue];
        }
        else
            _value = [scheduleActiondictionary objectForKey:@"value"];
        _key = [scheduleActiondictionary objectForKey:@"key"];
        _type = type;
        _active = [scheduleActiondictionary objectForKey:@"active"];
        _name = [scheduleActiondictionary objectForKey:@"name"];
        
        NSNumber *param;
        param = [scheduleActiondictionary objectForKey:@"in_range"];
        _inRange = param? param: nil;
        
        param = [scheduleActiondictionary objectForKey:@"at_start"];
        _atStart = param? param: nil;
        
        param = [scheduleActiondictionary objectForKey:@"at_end"];
        _atEnd = param? param: nil;
    }
    return self;
}

- (NSDictionary *)buildScheduleActionDictionary
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setObject:_baseType forKey:@"base_type"];
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    
    if([_baseType isEqualToString:@"boolean"])
        [params setObject:[NSNumber numberWithInt:[_value isEqualToString:@"1" ]?1:0 ] forKey:@"value"];
    else if([_baseType isEqualToString:@"integer"]){
        NSNumber *num = [f numberFromString:_value];
        [params setObject:[NSNumber numberWithInt:[num intValue]] forKey:@"value"];
    }
    else if([_baseType isEqualToString:@"decimal"]){
        NSNumber *num = [f numberFromString:_value];
        [params setObject:num forKey:@"value"];
    }
    else {
        [params setObject:_value forKey:@"value"];
    }
    
    if(_type)
        [params setObject:_type forKey:@"type"];
    
    [params setObject:_name forKey:@"name"];
    
    if(_active)
        [params setObject:_active forKey:@"active"];
    else
        [params setObject:[NSNumber numberWithBool:YES] forKey:@"active"];
    if(_inRange)
        [params setObject:_inRange forKey:@"in_range"];
    else
        [params setObject:[NSNumber numberWithBool:NO] forKey:@"in_range"];
    if(_atStart)
        [params setObject:_atStart forKey:@"at_start"];
    else
        [params setObject:[NSNumber numberWithBool:NO] forKey:@"at_start"];
    if(_atEnd)
        [params setObject:_atEnd forKey:@"at_end"];
    else
        [params setObject:[NSNumber numberWithBool:NO] forKey:@"at_end"];
    
    if(_key!=nil)
        [params setObject: _key forKey:@"key"];
    
    return params;
}


- (NSOperation *)create:(AylaSchedule *)schedule
       success:(void (^)(AylaResponse *response, AylaScheduleAction *scheduleAction)) successBlock
       failure:(void (^)(AylaError *err)) failureBlock
{
    if (schedule == nil || schedule.key == nil) {
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.httpStatusCode = 0; err.nativeErrorInfo = 0;
        err.errorInfo = nil;
        failureBlock(err);
        return nil;
    }
    
    NSMutableDictionary *errors =[NSMutableDictionary new];
    if (_name == nil) {
        [errors setObject:@"can't be blank" forKey:@"name"];
    }
    if (_type == nil) {
        [errors setObject:@"can't be blank" forKey:@"type"];
    }
    if (_baseType == nil) {
        [errors setObject:@"can't be blank" forKey:@"baseType"];
    }
    else if( [@"boolean string integer decimal" rangeOfString:_baseType].location == NSNotFound) {
        [errors setObject:@"doesn't support" forKey:@"baseType"];
    }
    if (_value == nil) {
        [errors setObject:@"can't be blank" forKey:@"value"];
    }
    
    if ([errors count]>0) {
        AylaError *err = [AylaError new];
        err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.nativeErrorInfo = nil; err.errorInfo = errors;
        err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    
    NSDictionary *sendParams = [[NSDictionary alloc] initWithObjectsAndKeys:[self buildScheduleActionDictionary], @"schedule_action", nil];
    NSString *path = [NSString stringWithFormat:@"schedules/%@/schedule_actions.json", schedule.key];
    return
    [[AylaApiClient sharedDeviceServiceInstance] postPath:path parameters: sendParams
              success:^(AylaHTTPOperation *operation, id response) {
                  NSDictionary *resp = (NSDictionary *)response;
                  NSDictionary *schd = [resp objectForKey:@"schedule_action"];
                  _key = [schd objectForKey:@"key"];
                  _active = [schd objectForKey:@"active"];
                  _scheduleId = [schd objectForKey:@"schedule_id"];
                                        
                  id value = [schd objectForKey:@"value"];
                  if(value == [NSNull null]) _value = nil;
                  _value  = [value isKindOfClass:[NSNumber class]]? [value stringValue]:[value copy];

                  saveToLog(@"%@, %@, %@:%ld, %@:%@, %@", @"I", @"Schedule",
                            @"statusCode", (long)operation.response.httpStatusCode, @"success", @"null", @"schedule.create");
                  successBlock(operation.response, self);
              }
              failure:^(AylaHTTPOperation *operation, AylaError *error) {
                  
                  saveToLog(@"%@, %@, %@, %@", @"E", @"Schedule",
                            error.logDescription, @"schedule.create");
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


- (NSOperation *)update:(NSDictionary *)callParams
       success:(void (^)(AylaResponse *response, AylaScheduleAction *scheduleAction))successBlock
       failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableDictionary *errors =[NSMutableDictionary new];
    if (_name == nil) {
        [errors setObject:@"can't be blank" forKey:@"name"];
    }
    /*
    if (_type == nil) {
        [errors setObject:@"can't be blank" forKey:@"type"];
    }
    */
    if (_baseType == nil) {
        [errors setObject:@"can't be blank" forKey:@"baseType"];
    }
    else if( [@"boolean string integer decimal" rangeOfString:_baseType].location == NSNotFound ) {
        [errors setObject:@"doesn't support" forKey:@"baseType"];
    }
    if (_value == nil) {
        [errors setObject:@"can't be blank" forKey:@"value"];
    }
    
    if ([errors count]>0) {
        AylaError *err = [AylaError new];
        err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.nativeErrorInfo = nil; err.errorInfo = errors;
        err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }

    NSDictionary *generatedActionDict = [self buildScheduleActionDictionary];
    NSDictionary *sendParams = [[NSDictionary alloc] initWithObjectsAndKeys:generatedActionDict, @"schedule_action", nil];
    
    NSString *path = [NSString stringWithFormat:@"schedule_actions/%@.json", self.key];
    return [[AylaApiClient sharedDeviceServiceInstance] putPath:path parameters:sendParams
                success:^(AylaHTTPOperation *operation, id response) {
                    saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"I", @"Schedule",
                              @"statusCode", (long)operation.response.httpStatusCode, @"success",@"null", @"scheduleActions.update");

                    successBlock(operation.response, self);
                }
                failure:^(AylaHTTPOperation *operation, AylaError *error) {
                    
                    saveToLog(@"%@, %@, %@, %@", @"E", @"Schedule",
                              error.logDescription, @"scheduleActions.update");
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
                        error.errorInfo =  errList;
                    }
                    else{
                        error.errorCode = 1;
                        error.errorInfo = nil;
                    }
                    failureBlock(error);
                }
     ];
}


- (NSOperation *)delete:(NSDictionary *)callParams
       success:(void (^)(AylaResponse *response))successBlock
       failure:(void (^)(AylaError *err))failureBlock
{
    if (self.key == nil) {
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.httpStatusCode = 0; err.nativeErrorInfo = 0;
        err.errorInfo = nil;
        failureBlock(err);
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"schedule_actions/%@.json", self.key];
    return
    [[AylaApiClient sharedDeviceServiceInstance] deletePath:path parameters:nil
                    success:^(AylaHTTPOperation *operation, id response) {
                        saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"I", @"Schedule",
                                  @"statusCode", (long)operation.response.httpStatusCode, @"success",@"null", @"scheduleActions.delete");

                        successBlock(operation.response);
                    }
                    failure:^(AylaHTTPOperation *operation, AylaError *error) {
                        
                        saveToLog(@"%@, %@, %@, %@", @"E", @"Schedule",
                                  error.logDescription, @"scheduleActions.delete");
                        NSMutableDictionary *errList;
                        if(operation.responseObject){
                            error.errorCode = AML_USER_INVALID_PARAMETERS;
                            NSDictionary *resp = operation.responseObject;
                            NSDictionary *errors = [resp objectForKey:@"errors"];
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

//------------------------------helpful methods---------------------------------
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaScheduleAction *_copy = copy;
        _copy.type = [_type copy];
        _copy.name = [_name copy];
        _copy.value = [_value copy];
        _copy.baseType = [_baseType copy];
        _copy.inRange = [_inRange copy];
        _copy.atStart = [_atStart copy];
        _copy.atEnd = [_atEnd copy];
        _copy.active = [_active copy];
        _copy.key = [_key copy];
    }
    return copy;
}

@end
