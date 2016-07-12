//
//  AylaTrigger.m
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 7/5/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaTriggerSupport.h"
#import "AylaDeviceSupport.h"
#import "AylaErrorSupport.h"
#import "NSObject+AylaNetworks.h"
#import "NSString+AylaNetworks.h"
@class AylaProperty;

//====================================== PropertyTriggers ==================================
@interface AylaPropertyTrigger ()
@property (nonatomic, copy) NSNumber *key; // this property trigger key
@property (nonatomic, copy) NSNumber *propertKey; // asscociated property key
@end

@implementation AylaPropertyTrigger

// Properties for Trigger for create
@synthesize propertyNickname = _propertyNickname;
@synthesize deviceNickname = _deviceNickname;
@synthesize active = _active;

@synthesize triggerType = _triggerType;
@synthesize compareType = _compareType;
@synthesize value = _value;
@synthesize key = _key; // this property trigger key
@synthesize retrievedAt = _retrievedAt;

// Additional Properties for Trigger retrieve
@synthesize period = _period;
@synthesize baseType = _baseType;
@synthesize triggeredAt = _triggeredAt;
@synthesize propertKey = _propertyKey; // asscociated property key

@synthesize applicationTrigger = _applicationTrigger;
@synthesize applicationTriggers = _applicationTriggers;


- (NSString *)description
{
  return [NSString stringWithFormat:@"\n"
          "deviceNickname: %@\n"
          "propertyNickname: %@\n"
          "triggerType: %@\n"
          "compareType: %@\n"
          "value: %@\n"
          "active: %d\n"
          "retrievedAt: %@\n"
          "period: %@\n"
          "baseType: %@\n"
          "triggeredAt: %@\n"
          , _deviceNickname, _propertyNickname, _triggerType, _compareType, _value, _active,
          _retrievedAt, _period, _baseType, _triggeredAt];
}

- (id)init
{
    self = [super init];
    if(self) {
        //set active as YES by default
        self.active = YES;
    }
    return self;
}

//----------------------------------- Create Property Trigger --------------------------------------
+ (NSOperation *)createTrigger:(AylaProperty *)thisProperty propertyTrigger:(AylaPropertyTrigger *)propertyTrigger
                       success:(void (^)(AylaResponse *response, AylaPropertyTrigger *propertyTriggerCreated))successBlock
                       failure:(void (^)(AylaError *err))failureBlock
{
    // {"trigger":{"trigger_type":"compare_absolute", "compare_type":">=", "value":60 }}
    
    NSDictionary *parameters =[NSDictionary dictionaryWithObjectsAndKeys:
                               propertyTrigger.triggerType?:[NSNull null], @"trigger_type",
                               propertyTrigger.compareType?:[NSNull null], @"compare_type",
                               propertyTrigger.value?:[NSNull null], @"value",
                               propertyTrigger.deviceNickname?:[NSNull null], @"device_nickname",
                               propertyTrigger.propertyNickname?:[NSNull null],@"property_nickname",
                               @(propertyTrigger.active), @"active",
                               nil ];
    NSDictionary *params =[NSDictionary dictionaryWithObjectsAndKeys:
                           parameters, @"trigger", nil];
    
    NSString *propertyKeyStr = [thisProperty.key stringValue]; 
    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"properties/", propertyKeyStr, @"/triggers.json"];
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"PropertyTrigger", @"path", path, @"createPropertyTrigger");
    return [[AylaApiClient sharedDeviceServiceInstance] postPath:path
         parameters:params
            success:^(AylaHTTPOperation *operation, id propertyTriggerDict) {
              AylaPropertyTrigger *propertyTrigger = [[AylaPropertyTrigger alloc] initRetrievePropertyTriggerWithDictionary:propertyTriggerDict];
              saveToLog(@"%@, %@, %@:%@, %@", @"I", @"PropertyTrigger", @"propertyTrigger.key", propertyTrigger.key, @"createPropertyTrigger.postPath");
              successBlock(operation.response, propertyTrigger);
            }
            failure:^(AylaHTTPOperation *operation, AylaError *error) {
              saveToLog(@"%@, %@, %@, %@", @"E", @"PropertyTrigger", error.logDescription, @"createPropertyTrigger.postPath");
              
                if(operation.responseObject){
                    error.errorCode = AML_USER_INVALID_PARAMETERS;
                    error.errorInfo = operation.responseObject;
                }
                else{
                    error.errorCode = 1;
                    error.errorInfo = nil ;
                }
              failureBlock(error);
            }];                                         
}

//----------------------------------- Retrieve Property Triggers --------------------------------------
+ (NSOperation *)getTriggers:(AylaProperty *)property callParams:(NSDictionary *)callParams
                          success:(void (^)(AylaResponse *response, NSMutableArray *propertyTriggers))successBlock
                          failure:(void (^)(AylaError *err))failureBlock
{
  //properties/122/triggers.json
  NSString *path = [NSString stringWithFormat:@"%@%@%@", @"properties/", property.key, @"/triggers.json"];
  saveToLog(@"%@, %@, %@:%@, %@", @"I", @"PropertyTriggers", @"path", path, @"retrievePropertyTriggers");
  return [[AylaApiClient sharedDeviceServiceInstance] getPath:path
                  parameters:nil
                     success:^(AylaHTTPOperation *operation, id propertyTriggersDict) {
                       int count = 0;
                       NSMutableArray *propertyTriggers = [NSMutableArray array];
                       for (NSDictionary *propertyTriggerDictionary in propertyTriggersDict) {
                         AylaPropertyTrigger *propertyTrigger = [[AylaPropertyTrigger alloc] initRetrievePropertyTriggerWithDictionary:propertyTriggerDictionary];
                         [propertyTriggers addObject:propertyTrigger];
                         count++;
                       }
                       saveToLog(@"%@, %@, %@%d, %@", @"I", @"PropertyTrigger", @"count:", count, @"retrievePropertyTriggers.getPath");
                       successBlock(operation.response, propertyTriggers);
                     }
                     failure:^(AylaHTTPOperation *operation, AylaError *error) {
                       saveToLog(@"%@, %@, %@, %@", @"E", @"PropertyTriggers", error.logDescription, @"retrievepropertyTriggers.getPath");
                       failureBlock(error);
                     }];            
}

- (id)initRetrievePropertyTriggerWithDictionary:(NSDictionary *)propertyTriggerDictionary
{
  self = [super init];
  if (self) {
    NSArray *propertyTrigger = [propertyTriggerDictionary objectForKey:@"trigger"];
    
    if (propertyTrigger) {
      _compareType = ([propertyTrigger valueForKeyPath:@"compare_type"] != [NSNull null]) ? [propertyTrigger valueForKeyPath:@"compare_type"] : @"";
      _period = ([propertyTrigger valueForKeyPath:@"period"] != [NSNull null]) ? [propertyTrigger valueForKeyPath:@"period"] : @"";
      _triggerType = ([propertyTrigger valueForKeyPath:@"trigger_type"] != [NSNull null]) ? [propertyTrigger valueForKeyPath:@"trigger_type"] : @"";
      _baseType = ([propertyTrigger valueForKeyPath:@"base_type"] != [NSNull null]) ? [propertyTrigger valueForKeyPath:@"base_type"] : @"";
      _value = [propertyTrigger valueForKeyPath:@"value"];
      _triggeredAt = ([propertyTrigger valueForKeyPath:@"triggered_at"] != [NSNull null]) ? [propertyTrigger valueForKeyPath:@"triggered_at"] : @"";
      _key = [propertyTrigger valueForKeyPath:@"key"];
      _active = [propertyTrigger valueForKeyPath:@"active"] != [NSNull null]?
                [(NSNumber *)[propertyTrigger valueForKeyPath:@"active"] boolValue]: NO;
        
      _propertyKey = [[propertyTrigger valueForKeyPath:@"property_key"] nilIfNull];
      _retrievedAt = [NSDate date];
      _deviceNickname = [[propertyTrigger valueForKeyPath:@"device_nickname"] nilIfNull];
      _propertyNickname = [[propertyTrigger valueForKeyPath:@"property_nickname"] nilIfNull];
    } else {
      saveToLog(@"%@, %@, %@:%@, %@", @"E", @"PropertyTriggers", @"propertyTrigger", @"nil", @"retrievePropertyTriggers.initCreatePropertyTriggerWithDictionary");
    }
  }
  return self;
}

+ (NSOperation *)updateTrigger:(AylaProperty *)thisProperty propertyTrigger:(AylaPropertyTrigger *)propertyTrigger
                       success:(void (^)(AylaResponse *response, AylaPropertyTrigger *propertyTriggerCreated))successBlock
                       failure:(void (^)(AylaError *err))failureBlock
{
    // {"trigger":{"trigger_type":"compare_absolute", "compare_type":">=", "value":60 }}
    NSDictionary *parameters =[NSDictionary dictionaryWithObjectsAndKeys:
                               propertyTrigger.triggerType?:[NSNull null], @"trigger_type",
                               propertyTrigger.compareType?:[NSNull null], @"compare_type",
                               propertyTrigger.value?:[NSNull null], @"value",
                               propertyTrigger.deviceNickname?:[NSNull null], @"device_nickname",
                               propertyTrigger.propertyNickname?:[NSNull null], @"property_nickname",
                               @(propertyTrigger.active), @"active",
                               nil ];
    NSDictionary *params =[NSDictionary dictionaryWithObjectsAndKeys:
                           parameters, @"trigger", nil];
    
    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"triggers/", propertyTrigger.key, @".json"];
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"PropertyTrigger", @"path", path, @"updatePropertyTrigger");
    return [[AylaApiClient sharedDeviceServiceInstance] putPath:path
                  parameters:params
                     success:^(AylaHTTPOperation *operation, id propertyTriggerDict) {
                         AylaPropertyTrigger *propertyTrigger = [[AylaPropertyTrigger alloc] initRetrievePropertyTriggerWithDictionary:propertyTriggerDict];
                         saveToLog(@"%@, %@, %@:%@, %@", @"I", @"PropertyTrigger", @"propertyTrigger.key", propertyTrigger.key, @"updatePropertyTrigger.putPath");
                         successBlock(operation.response, propertyTrigger);
                     }
                     failure:^(AylaHTTPOperation *operation, AylaError *error) {
                         saveToLog(@"%@, %@, %@, %@", @"E", @"PropertyTrigger", error.logDescription, @"updatePropertyTrigger.putPath");
                         if(operation.responseObject){
                             error.errorCode = AML_USER_INVALID_PARAMETERS;
                             error.errorInfo = operation.responseObject;
                         }
                         else{
                             error.errorCode = 1;
                             error.errorInfo = nil ;
                         }
                         failureBlock(error);
                     }];                                         
}


//----------------------------------- Destroy Property Trigger --------------------------------------
+ (NSOperation *)destroyTrigger:(AylaPropertyTrigger *)propertyTrigger
                        success:(void (^)(AylaResponse *response))successBlock
                        failure:(void (^)(AylaError *err))failureBlock
{
  NSString *propertyTriggerKeyStr = [propertyTrigger.key stringValue];
  NSString *path = [NSString stringWithFormat:@"%@%@%@", @"triggers/", propertyTriggerKeyStr, @".json"];
  saveToLog(@"%@, %@, %@:%@, %@", @"I", @"PropertyTrigger", @"path", path, @"destroyTrigger");
  return [[AylaApiClient sharedDeviceServiceInstance] deletePath:path
                         parameters:nil
                            success:^(AylaHTTPOperation *operation, id propertyTriggerDict) {
                              saveToLog(@"%@, %@, %@, %@", @"I", @"PropertyTrigger", @"none", @"destroyTrigger.deletePath");
                              successBlock(operation.response);
                            }
                            failure:^(AylaHTTPOperation *operation, AylaError *error) {
                              saveToLog(@"%@, %@, %@, %@", @"E", @"PropertyTrigger", error.logDescription, @"destroyTrigger.deletePath");
                              failureBlock(error);
                            }];                                         
 }

//----------------------------- Property Application Triggers ----------------------
- (NSOperation *)createSmsApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
               success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerCreated))successBlock
               failure:(void (^)(AylaError *err))failureBlock
{
  applicationTrigger.appName = @"sms";
  return [AylaApplicationTrigger createTrigger:self applicationTrigger:applicationTrigger
    success:^(AylaResponse *response, AylaApplicationTrigger *applicationTriggerCreated)
    {
     _applicationTrigger = applicationTriggerCreated;
     successBlock(response, applicationTriggerCreated);
    }
    failure:^(AylaError *err)
    {
     failureBlock (err);
    }
   ];
}

//----------------------------- Property Application Triggers ----------------------
- (NSOperation *)createEmailApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                  success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerCreated))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
  applicationTrigger.appName = @"email";
  return [AylaApplicationTrigger createTrigger:self applicationTrigger:applicationTrigger
    success:^(AylaResponse *response, AylaApplicationTrigger *applicationTriggerCreated)
    {
     _applicationTrigger = applicationTriggerCreated;
     successBlock(response, applicationTriggerCreated);
    }
    failure:^(AylaError *err)
     {
       failureBlock (err);
     }
   ];
}

- (NSOperation *)createPushApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                              success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerCreated))successBlock
                              failure:(void (^)(AylaError *err))failureBlock
{
    applicationTrigger.appName = @"push_ios";
    return [AylaApplicationTrigger createTrigger:self applicationTrigger:applicationTrigger
        success:^(AylaResponse *response, AylaApplicationTrigger *applicationTriggerCreated)
        {
            _applicationTrigger = applicationTriggerCreated;
            successBlock(response, applicationTriggerCreated);
        }
        failure:^(AylaError *err)
        {
            failureBlock (err);
        }
    ];
}

- (NSOperation *)getApplicationTriggers:(NSDictionary *)callParams
             success:(void (^)(AylaResponse *response, NSMutableArray *applicationTriggers))successBlock
             failure:(void (^)(AylaError *err))failureBlock
{
  return [AylaApplicationTrigger getTriggers: self callParams:callParams
    success:^(AylaResponse *response, NSMutableArray *applicationTriggers)
    {
      _applicationTriggers= applicationTriggers;
      successBlock(response, applicationTriggers);
    }
    failure:^(AylaError *err)
    {
      failureBlock (err);
    }
  ];
}


- (NSOperation *) updateSmsApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                                      success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerUpdated))successBlock
                                      failure:(void (^)(AylaError *err))failureBlock;
{
    applicationTrigger.appName = @"sms";
    return [self updateApplicationTrigger:applicationTrigger success:successBlock failure:failureBlock];
}

- (NSOperation *) updateEmailApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                                        success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerUpdated))successBlock
                                        failure:(void (^)(AylaError *err))failureBlock
{
    applicationTrigger.appName = @"email";
    return [self updateApplicationTrigger:applicationTrigger success:successBlock failure:failureBlock];
}

- (NSOperation *) updatePushApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                                       success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerUpdated))successBlock
                                       failure:(void (^)(AylaError *err))failureBlock
{
    applicationTrigger.appName = applicationTrigger.appName? applicationTrigger.appName: @"push_ios";
    return [self updateApplicationTrigger:applicationTrigger success:successBlock failure:failureBlock];
}

- (NSOperation *) updateApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                                   success:(void (^)(AylaResponse *response, AylaApplicationTrigger *updatedApplicationTrigger))successBlock
                                   failure:(void (^)(AylaError *err))failureBlock
{
  return [AylaApplicationTrigger updateTrigger:self applicationTrigger:applicationTrigger
    success:^(AylaResponse *response, AylaApplicationTrigger *updatedApplicationTrigger)
    {
        successBlock(response, updatedApplicationTrigger);
    }
    failure:^(AylaError *err)
    {
        failureBlock (err);
    }];
}


- (NSOperation *)destroyApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                success:(void (^)(AylaResponse *response))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
  return [AylaApplicationTrigger destroyTrigger:applicationTrigger
    success:^(AylaResponse *response)
     {
       successBlock(response);
     }
    failure:^(AylaError *err)
     {
       failureBlock (err);
     }
  ];
}

//-------------------- helper methods
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaPropertyTrigger *_copy = copy;
        _copy.baseType = [_baseType copy];
        _copy.triggerType = [_triggerType copy];
        _copy.compareType = [_compareType copy];
        _copy.retrievedAt = [_retrievedAt copy];
        _copy.key = [_key copy];
        _copy.value = [_value copy];
        _copy.period = [_period copy];
        _copy.triggeredAt = [_triggeredAt copy];
        _copy.propertKey = [_propertyKey copy];
        _copy.applicationTrigger = [_applicationTrigger copy];
        _copy.applicationTriggers = [_applicationTriggers copy];
    }
    return copy;
}

@end

//====================================== Application Triggers ==================================
@interface AylaApplicationTrigger ()
@property (nonatomic, copy) NSNumber *key;

@property (nonatomic, copy) NSString *param1;
@property (nonatomic, copy) NSString *param2;
@property (nonatomic, copy) NSString *param3;

@end

@implementation AylaApplicationTrigger

@synthesize appName = _appName;
@synthesize contactId = _contactId;
@synthesize userName = _userName;
@synthesize param1 = _param1;
@synthesize param2 = _param2;
@synthesize param3 = _param3;
@synthesize retrievedAt = _retrievedAt;
@synthesize key = _key;

@synthesize countryCode = _countryCode;
@synthesize phoneNumber = _phoneNumber;
@synthesize message = _message;

@synthesize emailAddress = _emailAddress;
@synthesize emailTemplateId = _emailTemplateId;
@synthesize emailSubject = _emailSubject;
@synthesize emailBodyHtml = _emailBodyHtml;

@synthesize registrationId =_registrationId;
@synthesize applicationId = _applicationId;
@synthesize pushSound = _pushSound;
@synthesize pushData = _pushData;


- (void)setCountryCode:(NSString *)countryCode {
    _countryCode = [countryCode stringByStrippingLeadingZeroes];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"\n" 
          "appName: %@\n"
          "contactId: %@\n"
          "emailAddress: %@\n"
          "countryCode: %@\n"
          "phoneNumber: %@\n"
          "message: %@\n"
          "userName: %@\n"
          //"param1: %@\n"
          //"param2: %@\n"
          //"param3: %@\n" 
          "retrievedAt: %@\n"
          , _appName, _contactId, _emailAddress, _countryCode, _phoneNumber, _message, _userName, _retrievedAt]; //_param1, _param2, _param3,
}

+ (NSOperation *)createTrigger:(AylaPropertyTrigger *)propertyTrigger applicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                  success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerCreated))successBlock
                          failure:(void (^)(AylaError *err))failureBlock
{
    NSDictionary *paramsDictionary =
    [AylaApplicationTrigger getParamDictionaryFromApplicationTrigger:applicationTrigger];
  
    if(!paramsDictionary) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"ApplicationTrigger", @"appName", applicationTrigger.appName, @"createTrigger: Unknown application");
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.httpStatusCode = 422; err.errorInfo = nil; err.nativeErrorInfo = nil;
        failureBlock(err);
        return nil;
    }

    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"triggers/", propertyTrigger.key, @"/trigger_apps.json"];
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApplicationTrigger", @"path", path, @"createTrigger");
    return [[AylaApiClient sharedAppTriggerServiceInstance] postPath:path
      parameters:paramsDictionary
      success:^(AylaHTTPOperation *operation, id applicationTriggerDict) {
        AylaApplicationTrigger *applicationTrigger = [[AylaApplicationTrigger alloc] initApplicationTriggerWithDictionary:applicationTriggerDict];
        
        saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApplicationTrigger", @"applicationTrigger.key", applicationTrigger.key, @"createTrigger.postPath");
        
        successBlock(operation.response, applicationTrigger);
      }
      failure:^(AylaHTTPOperation *operation, AylaError *error) {
        saveToLog(@"%@, %@, %@, %@", @"E", @"ApplicationTrigger", error.logDescription, @"createTrigger.postPath");
        
          if(operation.responseObject){
              error.errorCode = AML_USER_INVALID_PARAMETERS;
              error.errorInfo = operation.responseObject;
          }
          else{
              error.errorCode = 1;
              error.errorInfo = nil ;
          }
        failureBlock(error);
      }
    ];
}

- (id)initApplicationTriggerWithDictionary:(NSDictionary *)applicationTriggerDictionary
{
  self = [super init];
  if (self) {
    NSArray *applicationTrigger = [applicationTriggerDictionary objectForKey:@"trigger_app"];
    
    if (applicationTrigger) {
      _appName = [[applicationTrigger valueForKeyPath:@"name"] nilIfNull];
      _userName = [[applicationTrigger valueForKeyPath:@"username"] nilIfNull];
      _param1 = [[applicationTrigger valueForKeyPath:@"param1"] nilIfNull];
      _param2 = [[applicationTrigger valueForKeyPath:@"param2"] nilIfNull];
      _param3 = [[applicationTrigger valueForKeyPath:@"param3"] nilIfNull];
      _key = [applicationTrigger valueForKeyPath:@"key"];
      _retrievedAt = [NSDate date];
      _contactId = [[applicationTrigger valueForKeyPath:@"contact_id"] nilIfNull];
        
      if ([_appName isEqualToString:@"sms"]) {
        // {"trigger_app": {"name":"sms", "param1":"1", "param2":"4085551111", "param3":"Hi. Pushbutton event"}}
        _countryCode = [_param1 stringByStrippingLeadingZeroes];
        _phoneNumber = _param2;
        _message = _param3;
      } else if ([_appName isEqualToString:@"email"]) {
        // {"trigger_app":{"name":"email","username":"Dave","param1":"emailAddress", "param3":"Hi. Pushbutton event"}}
        _emailAddress = _param1;
        _message = _param3;
        _emailTemplateId = [[applicationTrigger valueForKeyPath:@"email_template_id"] nilIfNull];
        _emailSubject = [[applicationTrigger valueForKeyPath:@"email_subject"] nilIfNull];
        _emailBodyHtml = [[applicationTrigger valueForKeyPath:@"email_body_html"] nilIfNull];
      } else if([_appName isEqualToString:@"push_ios"]) {
        _applicationId = _param2;
        _registrationId = _param1;
        _message = _param3;
        _pushSound = [[applicationTrigger valueForKeyPath:@"push_sound"] nilIfNull];
        _pushData = [[applicationTrigger valueForKeyPath:@"push_mdata"] nilIfNull];
      }
      else {
        saveToLog(@"%@, %@, %@:%@ %@", @"E", @"ApplicationTrigger", @"appName", _appName, @"initApplicationTriggerWithDictionary.getPath: Unknown application"); 
      }
    } else {
      saveToLog(@"%@, %@, %@:%@, %@", @"E", @"PropertyTriggers", @"applicationTrigger", @"nil", @"retrievePropertyTriggers.initCreatePropertyTriggerWithDictionary");
    }
  }
  return self;
}

+ (NSOperation *)getTriggers:(AylaPropertyTrigger *)propertyTrigger callParams:(NSDictionary *)callParams
             success:(void (^)(AylaResponse *response, NSMutableArray *applicationTrigger))successBlock
             failure:(void (^)(AylaError *err))failureBlock;
{
  NSString *path = [NSString stringWithFormat:@"%@%@%@", @"triggers/", propertyTrigger.key, @"/trigger_apps.json"];
  saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApplicationTriggers", @"path", path, @"getTriggers.getPath");
  return [[AylaApiClient sharedDeviceServiceInstance]
     getPath:path
     parameters:nil
     success:^(AylaHTTPOperation *operation, id applicationTriggersDict) {
       int count = 0;
       NSMutableArray *applicationTriggers = [NSMutableArray array];
       for (NSDictionary *applicationTriggerDictionary in applicationTriggersDict) {
         AylaApplicationTrigger *applicationTrigger = [[AylaApplicationTrigger alloc] initApplicationTriggerWithDictionary:applicationTriggerDictionary];
         [applicationTriggers addObject:applicationTrigger];
         count++;
       }
       saveToLog(@"%@, %@, %@%d, %@", @"I", @"ApplicationTrigger", @"count:", count, @"getApplicationTriggers.getPath");
       successBlock(operation.response, applicationTriggers);
     }
     failure:^(AylaHTTPOperation *operation, AylaError *error) {
       saveToLog(@"%@, %@, %@, %@", @"E", @"ApplicationTriggers", error.logDescription, @"getTriggers.getPath");
       failureBlock(error);
   }];            
}

+ (NSOperation *)updateTrigger:(AylaPropertyTrigger *)propertyTrigger applicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                                   success:(void (^)(AylaResponse *response, AylaApplicationTrigger *updatedApplicationTrigger))successBlock
                                   failure:(void (^)(AylaError *err))failureBlock
{
    NSDictionary *paramsDictionary =
    [AylaApplicationTrigger getParamDictionaryFromApplicationTrigger:applicationTrigger];
    
    if(!paramsDictionary) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"ApplicationTrigger", @"appName", applicationTrigger.appName, @"updateTrigger: Unknown application");
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.httpStatusCode = 422; err.errorInfo = nil; err.nativeErrorInfo = nil;
        failureBlock(err);
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"trigger_apps/", applicationTrigger.key, @".json"];
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApplicationTrigger", @"path", path, @"updateTrigger");
    return [[AylaApiClient sharedAppTriggerServiceInstance] putPath:path
              parameters:paramsDictionary
                 success:^(AylaHTTPOperation *operation, id applicationTriggerDict) {
                     AylaApplicationTrigger *applicationTrigger = [[AylaApplicationTrigger alloc] initApplicationTriggerWithDictionary:applicationTriggerDict];
                     
                     saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApplicationTrigger", @"applicationTrigger.key", applicationTrigger.key, @"updateTrigger.putPath");
                     
                     successBlock(operation.response, applicationTrigger);
                 }
                 failure:^(AylaHTTPOperation *operation, AylaError *error) {
                     saveToLog(@"%@, %@, %@, %@", @"E", @"ApplicationTrigger", error.logDescription, @"updateTrigger.putPath");
                     
                     if(operation.responseObject){
                         error.errorCode = AML_USER_INVALID_PARAMETERS;
                         error.errorInfo = operation.responseObject;
                     }
                     else{
                         error.errorCode = 1;
                         error.errorInfo = nil ;
                     }
                     failureBlock(error);
                 }
            ];
}

+ (NSDictionary *)getParamDictionaryFromApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
{
    NSDictionary *parameters;
    NSDictionary *paramsDictionary;
    if ([applicationTrigger.appName isEqualToString:@"sms"]) {
        // {"trigger_app": {"name":"sms", "param1":"1", "param2":"4085551111", "param3":"Hi. Pushbutton event"}}
        parameters =[NSDictionary dictionaryWithObjectsAndKeys:
                     applicationTrigger.appName, @"name",
                     applicationTrigger.contactId?:[NSNull null], @"contact_id",
                     applicationTrigger.countryCode?:[NSNull null], @"param1",
                     applicationTrigger.phoneNumber?:[NSNull null], @"param2",
                     applicationTrigger.message?:[NSNull null], @"param3",
                     nil ];
        paramsDictionary =[NSDictionary dictionaryWithObjectsAndKeys:
                           parameters, @"trigger_app", nil];
    } else if ([applicationTrigger.appName isEqualToString:@"email"]) {
        // {"trigger_app":{"name":"email","username":"Dave","param1":"emailAddress"}}
        parameters =[NSDictionary dictionaryWithObjectsAndKeys:
                     applicationTrigger.appName, @"name",
                     applicationTrigger.contactId?:[NSNull null], @"contact_id",
                     applicationTrigger.userName?:[NSNull null], @"username",
                     applicationTrigger.emailAddress?:[NSNull null], @"param1",
                     applicationTrigger.message?:[NSNull null], @"param3",
                     applicationTrigger.emailTemplateId?:[NSNull null],
                     @"email_template_id",
                     applicationTrigger.emailSubject?:[NSNull null],
                     @"email_subject",
                     applicationTrigger.emailBodyHtml?:[NSNull null],
                     @"email_body_html",
                     nil];
        paramsDictionary =[NSDictionary dictionaryWithObjectsAndKeys:
                           parameters, @"trigger_app", nil];
    } else if ([applicationTrigger.appName isEqualToString:@"push_ios"]) {
        parameters =[NSDictionary dictionaryWithObjectsAndKeys:
                     applicationTrigger.appName, @"name",
                     applicationTrigger.contactId?:[NSNull null], @"contact_id",
                     applicationTrigger.registrationId?:[NSNull null], @"param1",
                     applicationTrigger.applicationId?:[NSNull null], @"param2",
                     applicationTrigger.message?:[NSNull null], @"param3",
                     applicationTrigger.pushSound?:[NSNull null], @"push_sound",
                     applicationTrigger.pushData?:[NSNull null], @"push_mdata",
                     nil];
        paramsDictionary =[NSDictionary dictionaryWithObjectsAndKeys:
                           parameters, @"trigger_app", nil];
    }
    return paramsDictionary;
}


+ (NSOperation *)destroyTrigger:(AylaApplicationTrigger *)applicationTrigger
                success:(void (^)(AylaResponse *response))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
  NSString *path = [NSString stringWithFormat:@"%@%@%@", @"trigger_apps/", applicationTrigger.key, @".json"];
  saveToLog(@"%@, %@, %@:%@, %@", @"I", @"ApplicationTrigger", @"path", path, @"destroyTrigger");
  return [[AylaApiClient sharedDeviceServiceInstance] deletePath:path
    parameters:nil
    success:^(AylaHTTPOperation *operation, id applicationTriggerDict) {
     saveToLog(@"%@, %@, %@, %@", @"I", @"ApplicationTrigger", @"none", @"destroyTrigger.deletePath");
     successBlock(operation.response);
    }
    failure:^(AylaHTTPOperation *operation, AylaError *error) {
      saveToLog(@"%@, %@, %@, %@", @"E", @"ApplicationTrigger", error.logDescription, @"destroyTrigger.deletePath");
      failureBlock(error);
    }
  ];                                         
}


//-------------------- helper methods
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaApplicationTrigger *_copy = copy;
        _copy.appName = [_appName copy];
        _copy.contactId = [_contactId copy];
        _copy.userName = [_userName copy];
        _copy.param1 = [_param1 copy];
        _copy.param2 = [_param2 copy];
        _copy.param3 = [_param3 copy];
        _copy.retrievedAt = [_retrievedAt copy];
        _copy.key = [_key copy];
        _copy.countryCode = [_countryCode copy];
        _copy.phoneNumber = [_phoneNumber copy];
        _copy.message = [_message copy];
        
        _copy.applicationId = [_applicationId copy];
        _copy.registrationId = [_registrationId copy];
        _copy.pushSound = [_pushSound copy];
        _copy.pushData = [_pushData copy];
        
        _copy.emailAddress = [_emailAddress copy];
        _copy.emailTemplateId = [_emailTemplateId copy];
        _copy.emailSubject = [_emailSubject copy];
        _copy.emailBodyHtml = [_emailBodyHtml copy];
    }
    return copy;
}

@end

