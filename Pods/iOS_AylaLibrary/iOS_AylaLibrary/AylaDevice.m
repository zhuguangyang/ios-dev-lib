//
//  AylaDevice.m
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 5/30/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaDeviceSupport.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaLanModeSupport.h"
#import "AylaNotify.h"
#import "AylaTimer.h"
#import "AylaReachabilitySupport.h"
#import "AylaScheduleSupport.h"
#import "AylaRegistration.h"
#import "AylaResponse.h"
#import "AylaError.h"
#import "AylaErrorSupport.h"
#import "AylaCacheSupport.h"
#import "AylaSecuritySupport.h"
#import "AylaDeviceNotificationSupport.h"
#import "AylaGrantSupport.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceGatewaySupport.h"
#import "AylaDeviceNode.h"
#import "NSObject+AylaNetworks.h"
#import "AylaLanOperation.h"
#import "AylaHTTPOperation.h"
#import "AylaConnectionOperationSupport.h"
#import "AylaDeviceManager.h"
#import "AylaDefines_Internal.h"
#import "AylaLanMessage.h"
#import "AylaMessageResponse.h"
#import "NSString+AylaNetworks.h"
#import "AylaLanSession+Message.h"
#import "AylaRequestAck.h"
#import "AylaBatchRequest.h"
#import "AylaBatchResponse.h"
@implementation AylaLanModeConfig : NSObject
@synthesize lanipKey = _lanipKey;
@synthesize lanipKeyId = _lanipKeyId;
@synthesize keepAlive = _keepAlive;
@synthesize status = _status;

- (id)initAylaLanModeConfigWithDictionary:(NSDictionary *)dictionary
{    
    self = [super init];
    if(self){
        _lanipKey= [dictionary valueForKeyPath:@"lanip_key"];
        _lanipKeyId = [dictionary valueForKeyPath:@"lanip_key_id"];
        _keepAlive = [dictionary valueForKeyPath:@"keep_alive"];
        _status = [dictionary valueForKeyPath:@"status"];
    }
    return self;
}

- (BOOL)isEnabled
{
    return [_status isEqualToString:@"enable"];
}

- (BOOL)isValid
{
    return [self isEnabled] && (_lanipKey>0) && (_lanipKeyId>0);
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_lanipKey forKey:@"lanipKey"];
    [encoder encodeObject:_lanipKeyId forKey:@"lanipKeyId"];
    [encoder encodeObject:_keepAlive forKey:@"keepAlive"];
    [encoder encodeObject:_status forKey:@"status"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    _lanipKey = [decoder decodeObjectForKey:@"lanipKey"];
    _lanipKeyId = [decoder decodeObjectForKey:@"lanipKeyId"];
    _keepAlive = [decoder decodeObjectForKey:@"keepAlive"];
    _status = [decoder decodeObjectForKey:@"status"];
    return self;
}
@end;


@interface AylaDevice ()
@property (nonatomic, strong) AylaLanModule *lanModule;
@property (nonatomic, strong) AylaLanModeConfig *lanModeConfig;
@property (nonatomic, copy) NSMutableArray *features;
@property (nonatomic, copy) NSNumber *key;         //Device key number
@property (nonatomic, strong, readwrite) NSString *connectionStatus;

@property (nonatomic, weak) AylaDevice *managedCopy;

@end

@implementation AylaDevice

// API Client Instance method
// Device methods
@synthesize productName = _productName;
@synthesize model = _model;
@synthesize dsn = _dsn;
@synthesize oemModel = _oemModel;
@synthesize connectedAt = _connectedAt;
@synthesize key= _key;
@synthesize mac = _mac;
@synthesize lanIp = _lanIp;
@synthesize features = _features;

@synthesize hasProperties = _hasProperties;
@synthesize ip = _ip;
@synthesize swVersion = _swVersion;
@synthesize productClass = _productClass;
@synthesize lanEnabled = _lanEnabled;

@synthesize connectionStatus = _connectionStatus;
@synthesize templateId = _templateId;
@synthesize lat = _lat;
@synthesize lng = _lng;
@synthesize userId = _userId;
@synthesize moduleUpdatedAt = _moduleUpdatedAt;

@synthesize retrievedAt = _retrievedAt;
@synthesize properties = _properties;
@synthesize property = _property;
@synthesize lanModeConfig = _lanModeConfig;

@synthesize schedules = _schedules;
@synthesize schedule = _schedule;

@synthesize registrationType = _registrationType;
@synthesize registrationToken = _registrationToken;
@synthesize setupToken = _setupToken;

- (NSString *)description
{
  return [NSString stringWithFormat:@"\n" 
          "productName: %@\n"
          "model: %@\n"
          "dsn: %@\n"
          "oemModel: %@\n"
          "connectedAt: %@\n"
          "mac: %@\n"
          "lanIp: %@\n"
          "retrievedAt: %@\n"
          , _productName, _model, _dsn, _oemModel, _connectedAt, _mac, _lanIp,
          _retrievedAt];
}

// ---------------------- Retrieve Devices ---------------------------

static NSString * const kAylaDeviceType = @"device_type";
static NSString * const kAylaGatewayType = @"gateway_type";
static NSString * const kAylaNodeType = @"node_type";

+ (NSOperation *)getDevices: (NSDictionary *)callParams
                success:(void (^)(AylaResponse *response, NSArray *devices))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    NSString *path = [NSString stringWithFormat:@"%@", @"devices.json"];
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"path", path, @"getDevices");
  
    if([AylaReachability isInternetReachable]){
        
        // [AylaReachability determineServiceReachabilityWithBlock:^(int reachable){
        NSArray *devices = nil;
        
        if([AylaSystemUtils slowConnection].boolValue &&
           [[[AylaDeviceManager sharedManager] devices] count] > 0){

            // Get copy of device list
            devices = [[AylaDeviceManager sharedManager] copyOfBufferedDeviceList];
            AylaResponse *resp = [AylaResponse new];
            resp.httpStatusCode = AML_ERROR_ASYNC_OK_NON_AUTH_INFO;
            successBlock(resp, devices);
        }
        else {
            if([AylaReachability getConnectivity] == AML_REACHABILITY_REACHABLE){
               return [[AylaApiClient sharedDeviceServiceInstance] getPath:path
                      parameters:nil
                         success:^(AylaHTTPOperation *operation, id responseObject) {
                             NSMutableArray *devices = [NSMutableArray arrayWithCapacity:[(NSArray *)responseObject count]];
                             NSMutableArray *gateways = [NSMutableArray array];

                             for (NSDictionary *deviceDictionary in responseObject) {
                                 AylaDevice *device = [AylaDevice deviceFromDeviceDictionary:deviceDictionary];
                                 saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"key", device.key, @"getDevices.getPath");
                                 [devices addObject:device];
                                 if([device isKindOfClass:[AylaDeviceGateway class]]) {
                                    [gateways addObject:device];
                                 }
                             }
                             
                             //Organize device / gateway list.
                             saveToLog(@"%@, %@, %@:%lu, %@", @"Ixxx", @"Devices", @"i", (unsigned long)devices.count, @"getDevices.getPath");
                             
                             //nodes update for gateways
                             for(AylaDeviceGateway *gateway in gateways) {
                                 [gateway updateNodesFromGlobalDeviceList:devices];
                             }
                             
                             [[AylaDeviceManager sharedManager] updateDevicesWithArray:devices options:AylaDeviceManagerUpdateOptionSkipTopLevelNodes|AylaDeviceManagerUpdateOptionIncludeNodeListInGateway|AylaDeviceManagerUpdateOptionSaveToCache];
                             
                             successBlock(operation.response, devices);
                         }
                         failure:^(AylaHTTPOperation *operation, AylaError *error) {
                             saveToLog(@"%@, %@, %@ ,%@", @"E", @"Devices", error.logDescription, @"getDevices.getPath");
                             failureBlock(error);
                         }];
            }
            else{
                // When service is not reachable
                saveToLog(@"%@, %@, %@:%d, %@", @"I", @"Devices", @"serviceReachability", [AylaReachability getConnectivity], @"getDevices.getPath");
                [AylaReachability determineServiceReachabilityWithBlock:nil];
                devices = [AylaLanMode isEnabled]? [[AylaDeviceManager sharedManager] copyOfBufferedDeviceList]: [AylaCache get:AML_CACHE_DEVICE];
                if(devices) {
                    saveToLog(@"%@, %@, %@:%ld, %@", @"I", @"Devices", @"203", (unsigned long)devices.count, @"getDevices.getPath");
                    AylaResponse *resp = [AylaResponse new];
                    resp.httpStatusCode = AML_ERROR_ASYNC_OK_NON_AUTH_INFO;
                    successBlock(resp, devices);
                }
                else {
                    AylaError *err = [AylaError new];
                    err.errorCode = AML_ERROR_NO_CONNECTIVITY; err.nativeErrorInfo = nil;
                    err.httpStatusCode = 0; err.errorInfo = nil;
                    failureBlock(err);
                }
            }
        }
    }
    else{
        saveToLog(@"%@, %@, %@:%d, %@", @"E", @"Devices", @"internetReachability", [AylaReachability isInternetReachable], @"getDevices.getPath");
        AylaError *err = [AylaError new];
        err.errorCode = AML_ERROR_NO_CONNECTIVITY; err.nativeErrorInfo = nil;
        err.httpStatusCode = 0; err.errorInfo = nil;
        failureBlock(err);
    }
    return nil;
}

+ (NSOperation *) getDeviceDetailWithDSN:(NSString *)dsn
                                 success:(void (^)(AylaResponse *response, AylaDevice *device))successBlock
                                 failure:(void (^)(AylaError *err))failureBlock
{
    if (![dsn nilIfNull]) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                            httpCode:0
                                         nativeError:nil
                                        andErrorInfo:@{
                                                       NSStringFromSelector(@selector(dsn)): @"is invalid."
                                                       }];
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        failureBlock(error);
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"dsns/", dsn, @".json"];
    return [[AylaApiClient sharedDeviceServiceInstance] getPath:path
                                                     parameters:nil
                                                        success:^(AylaHTTPOperation *operation, id responseObject) {
                                                            AylaDevice *device = [AylaDevice deviceFromDeviceDictionary:responseObject];
                                                            saveToLog(@"%@, %@, %@, %@", @"I", @"dsn", device.dsn, @"getDeviceDetailWithDSN");
                                                            [[AylaDeviceManager sharedManager] updateDevice:device];
                                                            successBlock(operation.response, device);
                                                        }
                                                        failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                            saveToLog(@"%@, %@, %@ ,%@", @"E", @"Devices", error.logDescription, @"getDeviceDetailWithDSN");
                                                            failureBlock(error);
                                                        }];
}

/*
 * Setup devices(wifi/gatetway/node) based on device list
 */
+ (void)setupDevices:(NSArray *)devices {
    for(AylaDevice *device in devices) {
        if([device isKindOfClass:[AylaDeviceGateway class]]) {
            AylaDeviceGateway *gateway = (AylaDeviceGateway *)device;
            [gateway updateNodesFromGlobalDeviceList:devices];
        }
    }
}

+ (instancetype)deviceFromDeviceDictionary:(NSDictionary *)deviceDictionary
{
    NSDictionary *deviceAttributes = [deviceDictionary objectForKey:@"device"];
    NSString *deviceType = [deviceAttributes objectForKey:kAylaDeviceType];
    Class deviceClass = [AylaDevice deviceClassFromDeviceType:deviceType andDeviceDictionary:deviceDictionary];
    return [[deviceClass alloc] initDeviceWithDictionary:deviceDictionary];
}

+ (Class) deviceClassFromDeviceDictionary:(NSDictionary *)dictionary
{
    return [AylaDevice class];
}

- (id)initDeviceWithDictionary:(NSDictionary *)deviceDictionary
{
  self = [super init];
  if (self) {
    if ([deviceDictionary objectForKey:@"device"]) {
        [self updateWithDictionary:deviceDictionary];
    } else {
      saveToLog(@"%@, %@, %@:%@, %@", @"E", @"Devices", @"device", @"nil", @"getDevices.initDevicesWithDictionary");
    }
  }
  return self;
}

- (void)updateWithDictionary:(NSDictionary *)deviceDictionary
{
    NSDictionary * device = [deviceDictionary objectForKey:@"device"];
    self.productName = ([device valueForKeyPath:@"product_name"] != [NSNull null]) ? [device valueForKeyPath:@"product_name"] : @"";
    self.model = ([device valueForKeyPath:@"model"] != [NSNull null]) ? [device valueForKeyPath:@"model"] : @"";
    self.dsn = ([device valueForKeyPath:@"dsn"] != [NSNull null]) ? [device valueForKeyPath:@"dsn"] : @"";
    self.oemModel = ([device valueForKeyPath:@"oem_model"] != [NSNull null]) ? [device valueForKeyPath:@"oem_model"] : @"";
    self.deviceType = ([device valueForKeyPath:kAylaDeviceType] != [NSNull null])? [device valueForKeyPath:kAylaDeviceType]: nil;
    self.connectedAt = ([device valueForKeyPath:@"connected_at"] != [NSNull null]) ? [device valueForKeyPath:@"connected_at"] : @"";
    self.key = [device valueForKeyPath:@"key"];
    self.mac = ([device valueForKeyPath:@"mac"] != [NSNull null]) ? [device valueForKeyPath:@"mac"] : @"";
    self.lanIp = ([device valueForKeyPath:@"lan_ip"] != [NSNull null]) ? [device valueForKeyPath:@"lan_ip"] : @"";
    self.retrievedAt = [NSDate date];
    self.features = ([device valueForKeyPath:@"features"] != [NSNull null]) ? [device valueForKeyPath:@"features"] : nil;
    
    self.ip = ([device valueForKeyPath:@"ip"] != [NSNull null]) ? [device valueForKeyPath:@"ip"] : @"";
    self.hasProperties = ([device valueForKeyPath:@"has_properties"] != [NSNull null]) ? [device valueForKeyPath:@"has_properties"] : nil;
    self.productClass = ([device valueForKeyPath:@"product_class"] != [NSNull null]) ? [device valueForKeyPath:@"product_class"] : @"";
    self.ssid = ([device valueForKeyPath:@"ssid"] != [NSNull null]) ? [device valueForKeyPath:@"ssid"] : @"";
    self.swVersion = ([device valueForKeyPath:@"sw_version"] != [NSNull null]) ? [device valueForKeyPath:@"sw_version"] : @"";
    self.lanEnabled = ([device valueForKeyPath:@"lan_enabled"] != [NSNull null]) ? [device valueForKeyPath:@"lan_enabled"] : nil;
    
    _connectionStatus = [device valueForKey:@"connection_status"] && ([device valueForKey:@"connection_status"] != [NSNull null])? [device valueForKey:@"connection_status"]:@"";
    _templateId = [device valueForKey:@"template_id"] && ([device valueForKey:@"template_id"] != [NSNull null])? [device valueForKey:@"template_id"]:nil;
    _lat = [device valueForKey:@"lat"] && ([device valueForKey:@"lat"] != [NSNull null])? [device valueForKey:@"lat"]:@"";
    _lng = [device valueForKey:@"lng"] && ([device valueForKey:@"lng"] != [NSNull null])? [device valueForKey:@"lng"]:@"";
    _userId = [device valueForKey:@"user_id"] && ([device valueForKey:@"user_id"] !=[NSNull null])? [device valueForKey:@"user_id"]:nil;
    _moduleUpdatedAt = [device valueForKey:@"module_updated_at"] && ([device valueForKey:@"module_updated_at"] != [NSNull null])?[device valueForKey:@"module_updated_at"]: @"";
    
    if([device objectForKey:@"grant"]) {
        self.grant = [[AylaGrant alloc] initWithDictionary:device[@"grant"]];
    }
}


// --------------------------- Retrive Device ----------------------------
//
// Used to update/refresh a device object from the Ayla Cloud Service
//

- (NSOperation *)getDeviceDetail:(NSDictionary *)callParams
        success:(void (^)(AylaResponse *reponse, AylaDevice *deviceUpdated))successBlock
        failure:(void (^)(AylaError *err))failureBlock
{
  NSString *path = [NSString stringWithFormat:@"%@%@%@", @"devices/", self.key, @".json"];
  saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"path", path, @"getDeviceDetail");
  return [[AylaApiClient sharedDeviceServiceInstance] getPath:path
     parameters:nil
        success:^(AylaHTTPOperation *operation, id responseObject) {
          AylaDevice *updatedDevice = [[AylaDevice alloc] initDeviceWithDictionary:responseObject];
          saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"key", updatedDevice.key, @"getDeviceDetail.getPath");
          
          successBlock(operation.response, updatedDevice);
        }
        failure:^(AylaHTTPOperation *operation, AylaError *error) {
          saveToLog(@"%@, %@, %@, %@", @"E", @"Devices", error.logDescription, @"getDeviceDetail.getPath");
          failureBlock(error);
        }];
}


- (NSOperation *)update:(NSDictionary *)callParams
        success:(void (^)(AylaResponse *response, AylaDevice *deviceUpdated))successBlock
        failure:(void (^)(AylaError *err))failureBlock
{
    if (gblAuthToken == nil) {
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_NO_AUTH_TOKEN;
        err.nativeErrorInfo = nil; err.errorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    
    if (callParams==nil || [callParams objectForKey:@"product_name"] == nil) {
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.nativeErrorInfo = nil; err.errorInfo = nil; err.httpStatusCode = 0;
        NSDictionary *resp = [[NSDictionary alloc] initWithObjectsAndKeys:@"only support to change product_name", @"base", nil];
        err.errorInfo = resp;
        failureBlock(err);
        return nil;
    }
    
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[[callParams objectForKey:@"product_name"] copy], @"product_name", nil];
    NSDictionary *sendParam = [[NSDictionary alloc] initWithObjectsAndKeys:params, @"device", nil];
    
    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"devices/", self.key, @".json"];
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"path", path, @"update");
    return [[AylaApiClient sharedDeviceServiceInstance] putPath:path
              parameters:sendParam
                 success:^(AylaHTTPOperation *operation, id responseObject) {
                     saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"key", self.key, @"update.putPath");
                     [self setProductName:[params objectForKey:@"product_name"]];
                     NSMutableArray *devices = [AylaCache get:AML_CACHE_DEVICE];

                     if (devices != nil) {
                         for (AylaDevice *dev in devices) {
                             if([dev.dsn isEqualToString:self.dsn]){
                                 dev.productName = self.productName;
                                 break;
                             }
                         }
                         [AylaCache save:AML_CACHE_DEVICE withObject:devices];
                     }
                    successBlock(operation.response, self);
                 }
                 failure:^(AylaHTTPOperation *operation, AylaError *error) {
                     saveToLog(@"%@, %@, %@, %@", @"E", @"Devices", error.logDescription, @"getDeviceDetail.getPath");
                     failureBlock(error);
                 }];
}



- (NSOperation *)getProperties:(NSDictionary *)callParams
    success:(void (^)(AylaResponse *response, NSArray *properties))successBlock
    failure:(void (^)(AylaError *err))failureBlock
{
  return [AylaProperty getProperties:self callParams:callParams
       success:^(AylaResponse *response, NSArray *properties) {
         if(_properties == nil)
            _properties = [[NSMutableDictionary alloc] init];
         for(AylaProperty *property in properties){
            [_properties setValue:property forKey:property.name];
         }
         successBlock(response, properties);
       }
       failure:^(AylaError *err) {
         failureBlock(err);
       }
   ];
}

// --------------------------- Register/Unregister Pass Through ------------------------

+ (void)registerNewDevice:(AylaDevice *)device
      success:(void (^)(AylaResponse *response, AylaDevice *registeredDevice))successBlock
      failure:(void (^)(AylaError *err))failureBlock
{
  [AylaRegistration registerNewDevice:device
    success:^(AylaResponse *response, AylaDevice *registeredDevice) {
      [AylaCache clearAll];
      successBlock(response, registeredDevice);
    }
    failure:^(AylaError *err) {
      failureBlock(err);
    }
  ];
}
  
- (NSOperation *)unregisterDevice:(NSDictionary *)callParams
      success:(void (^)(AylaResponse *response))successBlock
      failure:(void (^)(AylaError *))failureBlock
{
  return [AylaRegistration unregisterDevice:self callParams:callParams
    success:^(AylaResponse *response) {
      successBlock(response);
    }
    failure:^(AylaError *err) {
      failureBlock(err);
    }
  ];
}

//------------------------------------ Reset -------------------------------------

- (NSOperation *)factoryReset:(NSDictionary *)callParams
                      success:(void (^)(AylaResponse *response))successBlock
                      failure:(void (^)(AylaError *err))failureBlock
{
    if(!self.key) {
        NSDictionary *errors = @{@"device": @"is invalid."};
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:errors];
        failureBlock(error);
        return nil;
    }
    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"devices/", self.key, @"/cmds/factory_reset.json"];
    return
    [[AylaApiClient sharedDeviceServiceInstance] putPath:path
        parameters:nil
        success:^(AylaHTTPOperation *operation, id responseObject) {
            saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Devices", @"dsn", self.dsn, @"factoryReset");
            [AylaCache clear:AML_CACHE_PROPERTY withParams:@{kAylaCacheParamDeviceDsn: self.dsn}];
            successBlock(operation.response);
        }
        failure:^(AylaHTTPOperation *operation, AylaError *error) {
            saveToLog(@"%@, %@, %@, %@", @"E", @"Devices", error.logDescription, @"factoryReset");
            failureBlock(error);
        }];
}

//---------------------------------Schedules------------------------------------

- (void)createSchedule:(AylaSchedule *)schedule
               success:(void (^)(AylaResponse *response, AylaSchedule *createdSchedule))successBlock
               failure:(void (^)(AylaError *err))failureBlock
{
    [schedule createWithDevice:self Name:schedule.name andActions:schedule.scheduleActions
        success:^(AylaResponse *response, AylaSchedule *newSchedule) {
            successBlock(response, newSchedule);
        } failure:^(AylaError *err) {
            failureBlock(err);
        }];
}

- (NSOperation *)getAllSchedules:(NSDictionary *)callParams
                success:(void (^)(AylaResponse *response, NSArray *schedules))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    if(_schedule == nil) {
        _schedule = [[AylaSchedule alloc] init];
    }
    
    return [_schedule getAll:self success:^(AylaResponse *response, NSArray *schedules) {
            successBlock(response, schedules);
        } failure:^(AylaError *err) {
            failureBlock(err);
        }];
}

- (NSOperation *)getScheduleByName:(NSString *)scheduleName
                  success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    if(_schedule == nil) {
        _schedule = [[AylaSchedule alloc] init];
    }
    
    return [_schedule getByName:scheduleName device:self success:^(AylaResponse *response, AylaSchedule *schedule) {
            successBlock(response, schedule);
        } failure:^(AylaError *err) {
            failureBlock(err);
        }];

}

- (NSOperation *)updateSchedule:(AylaSchedule *)schedule
                  success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    if(_schedule == nil) {
        _schedule = [[AylaSchedule alloc] init];
    }
    return [schedule update:self success:^(AylaResponse *response, AylaSchedule *updatedSchedule) {
            successBlock(response, updatedSchedule);
        } failure:^(AylaError *err) {
            failureBlock(err);
        }];
}

- (NSOperation *)clearSchedule:(AylaSchedule *)schedule
              success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
              failure:(void (^)(AylaError *err))failureBlock
{
    return [schedule clear:nil success:^(AylaResponse *response, AylaSchedule *clearedSchedule) {
            successBlock(response, clearedSchedule);
        } failure:^(AylaError *err) {
            failureBlock(err);
        }];
}


//------------------------------- Device Notification ----------------------------------------

- (NSOperation *)getNotifications:(NSDictionary *)params
                        success:(void (^)(AylaResponse *response, NSMutableArray *deviceNotifications))successBlock
                        failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaDeviceNotification getNotificationsWithDevice:self params:params success:successBlock failure:failureBlock];
}

- (NSOperation *)createNotification:(AylaDeviceNotification *)deviceNotification
                                  success:(void (^)(AylaResponse *response, AylaDeviceNotification *createdDeviceNotification))successBlock
                                  failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaDeviceNotification createNotification:deviceNotification withDevice:self success:successBlock failure:failureBlock];
}

- (NSOperation *)updateNotification:(AylaDeviceNotification *)deviceNotification
                                  success:(void (^)(AylaResponse *response, AylaDeviceNotification *updatedDeviceNotification))successBlock
                                  failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaDeviceNotification updateNotification:deviceNotification success:successBlock failure:failureBlock];
}

- (NSOperation *)destroyNotification:(AylaDeviceNotification *)deviceNotification
                                   success:(void (^)(AylaResponse *response))successBlock
                                   failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaDeviceNotification destroyNotification:deviceNotification withDevice:self success:successBlock failure:failureBlock];
}

//------------------------------- Time Zone Support ----------------------------------------

- (NSOperation *) getTimeZoneLocation:(NSDictionary *)callParams
                     success:(void (^)(AylaResponse *response, AylaTimeZone *timeZone))successBlock
                     failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaTimeZone getTimeZoneWithDevice:self
            success:^(AylaResponse *response, AylaTimeZone *devTimeZone) {
                successBlock(response, devTimeZone);
            } failure:^(AylaError *err) {
                failureBlock(err);
            }];
}


- (NSOperation *) updateTimeZoneLocation:(AylaTimeZone *)timeZone
                        success:(void (^)(AylaResponse *response, AylaTimeZone *updatedTimeZone))successBlock
                        failure:(void (^)(AylaError *err))failureBlock
{
    return [timeZone updateTimeZoneWithDevice:self
        success:^(AylaResponse *response, AylaTimeZone *updatedTimeZone) {
            successBlock(response, updatedTimeZone);
        } failure:^(AylaError *err) {
            failureBlock(err);
        }];
}



//--------------------------------- Datum -----------------------------------
- (NSOperation *) createDatum:(AylaDatum *)datum
                      success:(void (^)(AylaResponse *response, AylaDatum *newDatum))successBlock
                      failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaDatum createWithObject:self andDatum:datum success:successBlock failure:failureBlock];
}

- (NSOperation *)getDatumWithKey:(NSString *)key
                         success:(void (^)(AylaResponse *response, AylaDatum *datum))successBlock
                         failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaDatum getWithObject:self andKey:key success:successBlock failure:failureBlock];
}

- (NSOperation *) updateDatum:(AylaDatum *)datum
                      success:(void (^)(AylaResponse *response, AylaDatum *updatedDatum))successBlock
                      failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaDatum updateWithObject:self andDatum:datum success:successBlock failure:failureBlock];
}

- (NSOperation *)deleteDatum:(AylaDatum *)datum
                     success:(void (^)(AylaResponse *response))successBlock
                     failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaDatum deleteWithObject:self andDatum:datum success:successBlock failure:failureBlock];
}


//--------------------------------- Share -----------------------------------

static const NSString *shareAttrResourceId = @"resource_id";
static const NSString *shareAttrResourceName = @"resource_name";
- (NSOperation *)createShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *resp, AylaShare *share))successBlock
                     failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaShare create:share object:self success:successBlock failure:failureBlock];
}

- (NSOperation *)getSharesWithSuccess:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                   failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaShare get:self callParams:nil success:successBlock failure:failureBlock];
}

+ (NSOperation *)getAllSharesWithSuccess:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                                 failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaShare get:nil callParams:@{kAylaShareParamResourceName: kAylaShareResourceNameDevice} success:successBlock failure:failureBlock];
}

- (NSOperation *)getReceivedSharesWithSuccess:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                                      failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaShare getReceives:self callParams:nil success:successBlock failure:failureBlock];
}

+ (NSOperation *)getAllReceivedSharesWithSuccess:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                                 failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaShare getReceives:nil callParams:@{kAylaShareParamResourceName: kAylaShareResourceNameDevice} success:successBlock failure:failureBlock];
}

- (NSOperation *)getShareWithId:(NSString *)id
                    success:(void (^)(AylaResponse *resp, AylaShare *share))successBlock
                    failure:(void (^)(AylaError *error))failureBlock;
{
    return [AylaShare getWithId:id success:successBlock failure:failureBlock];
}

- (NSOperation *)updateShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *resp, AylaShare *updatedShare))successBlock
                     failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaShare update:share success:successBlock failure:failureBlock];
}

- (NSOperation *)deleteShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *response)) successBlock
                     failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaShare delete:share success:successBlock failure:failureBlock];
}


//--------------------------------- Grant -----------------------------------
- (BOOL)amOwner
{
    return self.grant? YES: NO;
}

//---------------------------------NewDeviceConnected-----------------------------------

+ (void)getNewDeviceConnected: (NSString *)dsn
            setupToken:(NSString *) setupToken
            success:(void (^)(AylaResponse *resp, NSDictionary *response))successBlock
            failure:(void (^)(AylaHTTPOperation *operation, AylaError *err))failureBlock
{    
    static AylaApiClient *tmpClientInstance;
    tmpClientInstance = DEFAULT_SECURE_SETUP == NO? [AylaApiClient sharedNonSecureDeviceServiceInstance]:[AylaApiClient sharedDeviceServiceInstance];
    NSString *path = [[NSString alloc] initWithFormat:@"devices/connected.json?dsn=%@&setup_token=%@", dsn, setupToken];    
    [tmpClientInstance getPath:path parameters:nil
           success:^(AylaHTTPOperation *operation, id responseObject){
               successBlock(operation.response, responseObject);
           }
           failure:^(AylaHTTPOperation *operation, AylaError *error){
               saveToLog(@"%@, %@, %@:%ld, %@", @"E", @"confirmConnection", @"Failed", (long)error.nativeErrorInfo.code , @"confirmNewDeviceToServiceConnection.getPath");
               NSNumber *errNum = [[NSNumber alloc] initWithInt:AML_GET_NEW_DEVICE_CONNECTED];
               NSDictionary *description = [[NSDictionary alloc] initWithObjectsAndKeys:errNum, @"subTaskFailed", nil];
               error.errorCode = 1;
               error.errorInfo = description;
               failureBlock(operation, error);
           }
     ];
}

//-----------------------------------------------------------------------------------
//------------------------------------ Lan Mode -------------------------------------

- (void)lanModeEnable
{
    [self lanModeEnableWithType:AylaLanModeSessionTypeNormal];
}

- (void)lanModeDisable
{
    AylaDevice *device = [self managedCopy];
    [device resetNotifyOustandingCounter];
    [device.lanModule lanModeDisable];
    return;
}

- (void)lanModeEnableWithType:(AylaLanModeSessionType)type
{
    //initialize LanMode
    [[AylaDeviceManager sharedManager] addDevice:self skipUpdate:YES];
    
    //Get lan buffered copy
    AylaDevice *device = [self managedCopy];
    
    if(!device.lanModule) {
        device.lanModule = [[AylaLanModule alloc] initWithDevice:device];
    }
    
    [device.lanModule lanModeEnableWithType:type];
}

- (enum lanModeSession)lanModeState
{
    AylaDevice *lanDevice = [self managedCopy];
    return lanDevice.lanModule.session.sessionState;
}

- (void) notifyAcknowledge
{
    _notifyOutstandingCounter --;
}

- (void)incrementNotifyOutstandingCounter
{
    _notifyOutstandingCounter ++;
}

- (void)decrementNotifyOutstandingCounter
{
    _notifyOutstandingCounter --;
}

- (void)resetNotifyOustandingCounter
{
    _notifyOutstandingCounter = 0;
}

- (BOOL)hasMoreNotifyOutstanding
{
    return _notifyOutstandingCounter > 0;
}

//------------------------ @Override methods to support Lan Mode --------------------------

- (BOOL)isLanModeActive
{
    AylaDevice *lanDevice = [self lanModeDelegate];
    if(lanDevice &&
       [lanDevice properties] &&
       lanDevice.lanModule &&
       lanDevice.lanModule.session.sessionState == UP
       ) {
        return YES;
    }
    return NO;
}


- (BOOL)initPropertiesFromCache
{
    // Currently only use stored properties info to set default, would be deprecated later
    NSMutableArray *arr = [AylaCache get:AML_CACHE_PROPERTY withIdentifier:self.dsn];
    
    // the properties have already been cached read it, otherwise go back to original steps
    if(arr!=nil){
        if(!self.properties) {
            self.properties = [NSMutableDictionary new];
        }
        
        for(AylaProperty *property in arr){
            [self.properties setValue:property forKey:[property.name copy]];
            [property updateDatapointFromProperty];
        }
        return YES;
    }
    return NO;
}

- (AylaDevice *)lanModeEdptFromDsn:(NSString *)dsn
{
    return [dsn isEqualToString:self.dsn]? self: nil;
}

//representative in lan mode communication
- (AylaDevice *)lanModeDelegate
{
    return [self managedCopy];
}

/**
 *  Return name in property representitive in lan mode for input endpoint property name
 *  @note Return AYLA_EMPTY_STRING if representitive is not required for this endpoint property.
 */
- (NSString *)lanModePropertyNameFromEdptPropertyName:(NSString *)name
{
    return name;
}

//-----------------------------------------------------------------------------------------

+ (void)cancelAllOutstandingRequests
{
    if([[AylaLanMode device] lanIp])
        [[[AylaApiClient sharedConnectedDeviceInstance:[[AylaLanMode device] lanIp]] operationQueue] cancelAllOperations];
}

- (void)updateDevicesCacheLanIp:(NSString *)discoveredLanIp
{
    NSMutableArray *devices = [AylaCache get:AML_CACHE_DEVICE];

    if (devices!=nil && [devices count]>0 ){
        for(AylaDevice *dev in devices){
            if([dev.dsn isEqualToString:self.dsn]){
                [dev setLanIp:discoveredLanIp];
            }
        }
        [AylaCache save:AML_CACHE_DEVICE withObject:devices];
    }
}

- (BOOL)isLanModeEnabled
{
    if(self.lanModeConfig != nil && [self.lanModeConfig.status isEqualToString:@"enable"] && [self.lanModeConfig.lanipKeyId intValue]!= -1){
        //saveToLog(@"%@, %@, %@, %d, %@", @"I", @"AylaDevice", @"isLanModeEnabled?", true , @"isLanModeEnabled");
        return true;
    }
    else{
        saveToLog(@"%@, %@, %@, %d, %@", @"I", @"AylaDevice", @"isLanModeEnabled?", false , @"isLanModeEnabled");
        return false;
    }
}


//------------------ Get lan mode key info from the device service --------------

- (NSInteger)lanModeWillSendCmdEntity:(AylaLanCommandEntity *)entity
{
    if(entity && entity.baseType == AYLA_LAN_PROPERTY){
        //Sending AYLA_LAN_PROPERTY to device
        //Skip immediate response for cmds with type AylaMessageTypeDatapointUpdateWithAck
        if(entity.tag == AylaMessageTypeDatapointUpdateWithAck) {
            return AML_ERROR_ASYNC_OK;
        }
        
        AylaLanSession *session = self.lanModule.session;
        NSString *strId = [NSString stringWithFormat:@"%d", entity.cmdId];
        AylaLanCommandEntity *command =  [session getOutstandingCommand:strId];
        [session removeOutstandingCommand:strId];
        
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        AylaLanCommandRespBlock respBlock = command.respBlock;
        if(respBlock && ![command isCancelled]) {
            NSDictionary *re = [[NSDictionary alloc] initWithObjectsAndKeys:@"success", @"status",nil];
            command.respBlock(command, re, AML_ERROR_ASYNC_OK, nil);
        }
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
    }
    return 200;
}

- (NSInteger)updateWithPropertyName:(NSString *)propertyName andValue:(NSString *)value
{
    return [self updateWithPropertyName:propertyName value:value params:nil];
}

- (NSInteger)updateWithPropertyName:(NSString *)propertyName value:(NSString *)value params:(NSDictionary *)params
{
    AylaProperty *property = [self findProperty:propertyName];
    if(!property) {
        saveToLog(@"%@, %@, %@:%@, %@, %@", @"E", @"AylaDevice", @"propertyName", propertyName, @"not found", @"updateWithPropertyName");
        return 404;
    }
    [property updateWithValue:value params:params];
    [property lanModeEnable:self];
    return 200;
}

- (NSUInteger)lanModeUpdateWithPropertyName:(NSString *)propertyName value:(id)value message:(AylaLanMessage *)message params:(NSDictionary *)params
{
    NSInteger propertyUpdateStatus = [self updateWithPropertyName:propertyName value:value params:params];
    if([message isCallback]) {
        AylaLanSession *session = (AylaLanSession *)message.contextHandler;
        NSUInteger cmdId = message.cmdId;
        NSInteger status = message.status;
        AylaLanCommandEntity *command = [session getOutstandingCommand:[@(cmdId) stringValue]];
        
        if(!command){
            saveToLog(@"%@, %@, %@:%@, %ld, %@", @"I", @"lanUpdate", @"noReturnBlockForCommandResp-Discard", propertyName, (long)status, @"lanModeUpdateWithPropertyName");
        }
        else {
            [session invokeOperationForMessage:message];
        }
    }
    else if(propertyUpdateStatus >= 200 && propertyUpdateStatus < 300){
        saveToLog(@"%@, %@, %@, %@, %@", @"I", @"lanUpdate", @"statusFromDevice", @"update received", @"lanUpdateWithPropertyName");
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
            [self incrementNotifyOutstandingCounter];
            NSDictionary *returnNotify = [AylaNotify initNotifyDictionaryWithType:AML_NOTIFY_TYPE_PROPERTY dsn:self.dsn status:200 description:nil values:[NSArray arrayWithObject:propertyName]];
            [AylaNotify returnNotify:returnNotify];
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
    }
    else {
        saveToLog(@"%@, %@, %@:%ld, %@", @"E", @"lanUpdate", @"statusFromDevice", (long)propertyUpdateStatus, @"lanModeUpdateWithPropertyName");
    }
    
    return AML_ERROR_ASYNC_OK;
}

- (NSString *)lanModeToDeviceUpdateWithCmdId:(__unused int)cmdId property:(AylaProperty *)property valueString:(NSString *)valueString
{
    NSString *jsonString = nil;
    NSString *escapedValueString = [property.baseType isEqualToString:@"string"]? [NSString stringWithFormat:@"\"%@\"", [AylaSystemUtils jsonEscapedStringFromString:valueString]]: valueString;
    NSMutableString *optionalParamsInString = [NSMutableString new];
    if(property.ackEnabled) {
        [optionalParamsInString appendFormat:@",\"%@\":\"%d\"", @"id", cmdId];
    }
    jsonString = [NSString stringWithFormat:@"{\"property\": {\"name\": \"%@\",\"value\":%@,\"base_type\":\"%@\"%@}}",
                  property.name,
                  escapedValueString,
                  property.baseType,
                  optionalParamsInString];
    return jsonString;
}

- (NSString *)lanModeToDeviceCmdWithCmdId:(int)cmdId messageType:(AylaMessageType)messageType requestMethod:(NSString *)method sourceLink:(NSString *)sourceLink uri:(NSString *)uri data:(NSString *)data
{
    return [AylaLanMode buildToDeviceCommand:method cmdId:cmdId resourse:sourceLink data:data uri:uri];
}

- (AylaProperty*)findProperty:(NSString *)propertyName
{
    AylaProperty *property = [self.properties valueForKeyPath:propertyName];
    return property;
}

- (void)didEnableLanMode
{
    //Nothing to be set in AylaDevice
}

- (void)didDisableLanMode
{
    //Nothing to be set in AylaDevice
}

- (AylaMessageResponse *)didReceiveMessage:(AylaMessage *)message
{
    AylaMessageResponse *resp = nil;
    switch (message.source) {
        case AylaMessageSourceLAN:
            resp = [self handleLanMessage:(AylaLanMessage *)message];
            break;
        default:
            break;
    }
    
    if(!resp) {
        resp = [AylaMessageResponse responseOfMessage:message httpStatusCode:AML_ERROR_ASYNC_OK];
    }
    return resp;
}

- (AylaMessageResponse *)handleLanMessage:(AylaLanMessage *)message
{
    AylaMessageResponse * resp = [AylaMessageResponse new];
    resp.httpStatusCode = 200;
    AylaLanMessage *lanMsg = (AylaLanMessage *)message;
    if(lanMsg.method == AylaMessageMethodPOST) {
        if(lanMsg.type == AylaMessageTypeDatapointUpdate) {
            NSDictionary *data = [lanMsg.contents objectForKey:kAylaLanMessageParamData];
            NSString *name = data[kAylaLanMessageParamName];
            NSString *value = [NSString stringWithFormat:@"%@", data[kAylaLanMessageParamValue]];
            resp.httpStatusCode = [self lanModeUpdateWithPropertyName:name value:value message:message params:data];
        }
        else if (lanMsg.type == AylaMessageTypeDatapointAck) {
            NSDictionary *data = [lanMsg.contents objectForKey:kAylaLanMessageParamData];
            NSString *idInString = [data objectForKey:kAylaLanMessageParamId];
            AylaLanSession *session = message.contextHandler;
            AylaLanCommandEntity *command = [session getOutstandingCommand:idInString];

            if(!command){
                saveToLog(@"%@, %@, %@, %@, %@", @"I", @"AylaDevice", @"noReturnBlockForCommandResp-Discard", @(AylaMessageTypeDatapointAck), @"handleLanMessage");
            }
            
            [session removeOutstandingCommand:idInString];
            [command invokeRespBlockWithResponse:message.contents status:AML_ERROR_ASYNC_OK error:nil onMainQueue:YES];
            resp = [AylaMessageResponse responseOfMessage:message httpStatusCode:AML_ERROR_ASYNC_OK];
        }
        else if([message isCallback]){
            AylaLanSession *session = message.contextHandler;
            if(session) {
                resp = [session invokeOperationForMessage:message];
            }
            else {
                saveToLog(@"%@, %@, %@, %@, %@", @"W", @"AylaDevice", @"session", @"isNull", @"handleLanMessage");
            }
        }
    } else
    if(lanMsg.method == AylaMessageMethodGET) {
        if(lanMsg.type == AylaMessageTypeCommands) {
            AylaLanSession *session = message.contextHandler;
            AylaLanCommandEntity *command = [session deQueueTillNextValidCommand];
            resp.responseObject = command;
            resp.httpStatusCode = [session nextInQueue]? 206:200;
            [self lanModeWillSendCmdEntity:command];
        }
        else if([message isCallback]){
            AylaLanSession *session = message.contextHandler;
            if(session) {
                resp = [session invokeOperationForMessage:message];
            }
            else {
                saveToLog(@"%@, %@, %@, %@, %@", @"W", @"AylaDevice", @"session", @"isNull", @"handleLanMessage");
            }
        }
    }
    
    return resp;
}

//--------------------caching helper methods----------------------

- (void)updateWithCopy:(AylaDevice *)device
{
    if([self.dsn isEqualToString:device.dsn] &&
       [self hash] != [device hash]) {
        self.key = device.key?:self.key;
        self.productName = device.productName;
        self.lanIp = device.lanIp;
        self.connectedAt = device.connectedAt;
        self.swVersion = device.swVersion;
        self.ssid = device.ssid;
        self.productClass = device.productClass;
        self.model = device.model;
    }
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_productName forKey:@"productName"];
    [encoder encodeObject:_model forKey:@"model"];
    [encoder encodeObject:_dsn forKey:@"dsn"];
    [encoder encodeObject:_oemModel forKey:@"oemModel"];
    [encoder encodeObject:_deviceType forKey:kAylaDeviceType];
    [encoder encodeObject:_connectedAt forKey:@"connectedAt"];
    [encoder encodeObject:_mac forKey:@"mac"];
    [encoder encodeObject:_lanIp forKey:@"lanIp"];
    [encoder encodeObject:_ip forKey:@"ip"];
    //[encoder encodeObject:_hasProperties forKey:@"hasProperties"];
    [encoder encodeObject:_productClass  forKey:@"productClass"];
    [encoder encodeObject:_ssid forKey:@"ssid"];
    [encoder encodeObject:_swVersion forKey:@"swVersion"];
    //[encoder encodeObject:_lanEnabled forKey:@"lanEnabled"];
    [encoder encodeObject:_features forKey:@"features"];
    
    [encoder encodeObject:_key forKey:@"key"];
    [encoder encodeObject:_registrationType forKey:@"registrationType"];
    [encoder encodeObject:_setupToken forKey:@"setupToken"];
    //[encoder encodeObject:_properties forKey:@"properties"];
    //[encoder encodeObject:_lanModeConfig forKey:@"lanModeConfig"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    _productName = [decoder decodeObjectForKey:@"productName"];
    _model = [decoder decodeObjectForKey:@"model"];
    _dsn = [decoder decodeObjectForKey:@"dsn"];
    _oemModel = [decoder decodeObjectForKey:@"oemModel"];
    _deviceType = [decoder decodeObjectForKey:kAylaDeviceType];
    _connectedAt = [decoder decodeObjectForKey:@"connectedAt"];
    _mac = [decoder decodeObjectForKey:@"mac"];
    _lanIp= [decoder decodeObjectForKey:@"lanIp"];
    _key= [decoder decodeObjectForKey:@"key"];
    _registrationType = [decoder decodeObjectForKey:@"registrationType"];
    _setupToken = [decoder decodeObjectForKey:@"setupToken"];
    _ip = [decoder decodeObjectForKey:@"ip"];
    _productClass = [decoder decodeObjectForKey:@"productClass"];
    _ssid = [decoder decodeObjectForKey:@"ssid"];
    _swVersion = [decoder decodeObjectForKey:@"swVersion"];
    _features = [decoder decodeObjectForKey:@"features"];
    
    //_hasProperties = [decoder decodeObjectForKey:@"hasProperties"];
    //_lanEnabled = [decoder decodeObjectForKey:@"lanEnabled"];
    
    //_properties = [decoder decodeObjectForKey:@"properties"];
    //_lanModeConfig = [decoder decodeObjectForKey:@"lanModeConfig"];
    return self;
}

- (NSUInteger)hash
{
    return [self.key hash] ^ [self.productName hash] ^ [self.lanIp hash] ^ [self.swVersion hash];
}

//------------------------------helpful methods---------------------------------

+ (Class)deviceClassFromDeviceType:(NSString *)deviceType andDeviceDictionary:(NSDictionary *)deviceDictionary
{
    static Class AylaDeviceClassGateway;
    static Class AylaDeviceClassNode;
    static Class AylaDeviceClass;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AylaDeviceClass = [AylaDevice deviceClassFromClassName:kAylaDeviceClassName];
        AylaDeviceClassGateway = [AylaDevice deviceClassFromClassName:kAylaDeviceClassNameGateway];
        AylaDeviceClassNode = [AylaDevice deviceClassFromClassName:kAylaDeviceClassNameNode];
    });
    
    if(!deviceType ||
       [deviceType isEqualToString:kAylaDeviceTypeWifi]) {
        return AylaDeviceClass;
    }
    else if (AylaDeviceClassGateway &&
             [deviceType isEqualToString:kAylaDeviceTypeGateway]) {
        return [AylaDeviceGateway deviceClassFromDeviceDictionary:deviceDictionary];
    }
    else if(AylaDeviceClassNode &&
            [deviceType isEqualToString:kAylaDeviceTypeNode]) {
        return [AylaDeviceNode deviceClassFromDeviceDictionary:deviceDictionary];
    }
    return AylaDeviceClass;
}

+ (Class)deviceClassFromClassName:(NSString *)className
{
    return [AylaSystemUtils classFromClassName:className];
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaDevice *_copy = copy;
        _copy.productName = [_productName copy];
        _copy.model = [_model copy];
        _copy.dsn = [_dsn copy];
        _copy.oemModel = [_oemModel copy];
        _copy.deviceType = [_deviceType copy];
        _copy.connectedAt = [_connectedAt copy];
        _copy.mac = [_mac copy];
        _copy.lanIp = [_lanIp copy];
        _copy.key = [_key copy];
        _copy.registrationType = [_registrationType copy];
        _copy.setupToken = [_setupToken copy];
        _copy.ip = [_ip copy];
        _copy.productClass = [_productClass copy];
        _copy.ssid = [_ssid copy];
        _copy.swVersion = [_swVersion copy];
        _copy.properties = [_properties copy];
        _copy.property = [_property copy];
        _copy.features = [_features copy];
        _copy.lanModule = [[AylaLanModule alloc] initWithDevice:_copy];
    }
    return copy;
}

- (AylaDevice *)managedCopy
{
    AylaDevice *copy = _managedCopy;
    if(!copy) {
        copy = _managedCopy = [AylaLanMode deviceWithDsn:self.dsn recursiveCheck:YES];
    }
    
#ifdef DEBUG
    AylaDevice *dev = [[AylaDeviceManager sharedManager] deviceWithDsn:self.dsn recursiveCheck:YES];
    if(dev != copy) {
        NSLog(@"DEBUG, E, -managedCopy, dev and copy are different!");
    }
#endif
    return copy;
}

@end // AylaDevice
//===================================== Properties =================================


@interface AylaProperty ()
@property (nonatomic, copy) NSNumber *key;
@property (nonatomic, copy) NSNumber *deviceKey;
@property (nonatomic, copy, readwrite) NSString *type;

// Datapoint Ack
@property (nonatomic, assign) BOOL ackEnabled;
@property (nonatomic, copy, readwrite) NSDate *ackedAt;
@property (nonatomic, assign, readwrite) NSInteger ackStatus;
@property (nonatomic, assign, readwrite) NSInteger ackMessage;

- (id) initDevicePropertyWithDictionary:(NSDictionary *)propertyDictionary;
@end

static const NSInteger AylaPropertyParamDefaultPollingRetries = 5;
static const NSUInteger AylaPropertyParamDefaultPollingTimeInterval = 3;

@implementation AylaProperty
// Device Property Methods
@synthesize baseType = _baseType;
@synthesize value = _value;
@synthesize dataUpdatedAt = _dataUpdatedAt;
@synthesize deviceKey = _deviceKey;
@synthesize name = _name;
@synthesize key = _key;
@synthesize direction = _direction;
@synthesize retrievedAt = _retrievedAt;
@synthesize displayName = _displayName;

@synthesize datapoint = _datapoint;
@synthesize datapoints = _datapoints;

@synthesize propertyTrigger = _propertyTrigger;
@synthesize propertyTriggers = _propertyTriggers;

@synthesize metadata = _metadata;

//@override
- (void)setDatapoints:(NSMutableArray *)datapoints
{
    _datapoints = datapoints;
}
- (void)setDatapoint:(AylaDatapoint *)datapoint
{
    _datapoint = datapoint;
}


- (NSString *)description
{
  return [NSString stringWithFormat:@"\n" 
          "baseType: %@\n"
          "datapoint.sValue: %@\n"
          "datapoint.nValue: %@\n"
          "name: %@\n"
          "direction: %@\n" 
          "retrievedAt: %@\n"
          , _baseType, _datapoint.sValue, _datapoint.nValue, _name, _direction,  _retrievedAt]; 
}


static NSString *lastDsn = nil;
+ (void)setLastDsn:(NSString *)dsn
{
    lastDsn = dsn;
}

+ (NSArray *)propertyArrayFromDevice:(AylaDevice *)device names:(NSArray *)names needCopy:(BOOL)needCopy
{
    NSMutableArray *array = [NSMutableArray new];
    NSDictionary *propDictionary = device.properties;
    for(NSString *name in names) {
        AylaProperty *property = [propDictionary objectForKey:name];
        if(property) [array addObject: needCopy? [property copy]: property];
    }
    return array;
}
// ---------------------- Retrieve Properties ---------------------------
+ (NSOperation *)getProperties:(AylaDevice *)device callParams:(NSDictionary *)callParams
                success:(void (^)(AylaResponse *response, NSArray *properties))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    if(device.dsn == nil){
        dispatch_async(dispatch_get_main_queue(), ^{
            AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS; err.nativeErrorInfo = nil;
            err.httpStatusCode = 0; err.errorInfo = nil;
            failureBlock(err);
        });
        return nil;
    }
    
//  [AylaReachability determineDeviceReachabilityWithBlock:^(int reachable) {
    
    AylaDevice *lanDevice = [device managedCopy];
    AylaDevice *sender = [lanDevice lanModeDelegate];
    AylaLanSession *session = sender.lanModule.session;
    
    if([AylaSystemUtils notifyOutstandingEnabled].boolValue &&
       [lanDevice hasMoreNotifyOutstanding]) {
  
        [lanDevice decrementNotifyOutstandingCounter];
        NSDictionary *properties = lanDevice.properties;
 
        NSArray *names = callParams[@"names"]?:properties.allKeys;
        NSArray *propArray = [AylaProperty propertyArrayFromDevice:lanDevice names:names needCopy:NO];
        AylaLogI(@"Properties", 0, @"%@:%ld, %@", @"readInMemory", (unsigned long)propArray.count, @"getProperties.mem");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AylaResponse *resp = [AylaResponse new];
            resp.httpStatusCode = AML_ERROR_ASYNC_OK;
            successBlock(resp, propArray);
        });
    }
    else{
        //version 3.x.x, check if all requested properties have been registerd at lan mode
        BOOL isPropertiesCached = YES;
        
        __block NSDictionary *properties = lanDevice.properties;
        NSArray *names = callParams[@"names"];

        if([names nilIfNull]) {
            NSAssert([names isKindOfClass:[NSArray class]], @"Input names has to be an array.");
            NSArray *propArray = [AylaProperty propertyArrayFromDevice:lanDevice names:names needCopy:NO];
            isPropertiesCached = (propArray && (propArray.count == names.count))? YES: NO;
        }
        
        if(!isPropertiesCached) {
            AylaLogI(@"Properties", 0, @"%@:%@, %@", @"isCached", @"NO", @"getProperties");
        }
        
    //[AylaReachability determineDeviceReachabilityWithBlock:^(int reachable) {
            if([lanDevice isLanModeActive] &&
               isPropertiesCached){
                
                if(![names nilIfNull]) {
                    //no user input names found
                    names = [lanDevice.properties allKeys];
                }
                
                NSMutableArray *commands = [NSMutableArray array];
                
                __block long count = [names count];
                __block int responseStatus = AML_ERROR_ASYNC_OK;

                for(NSString *pName in names){
                    
                    AylaProperty *prop = [properties objectForKey:pName];
                    if(prop){
                        if([AML_LANMODE_IGNORE_BASETYPES rangeOfString:[prop baseType]].location != NSNotFound){
                            AylaLogW(@"Properties", 0, @"name:%@, Skipped:%@, %@", prop.name, @"IgnoreBaseType-LAN", @"getProperties.lan");
                            count--;
                            continue;
                        }
                        
                        int cmdId = [session nextCommandOutstandingId];
                        NSString *source = [NSString stringWithFormat:@"property.json?name=%@", pName];
                        NSString *cmd = [lanDevice lanModeToDeviceCmdWithCmdId:cmdId messageType:AylaMessageTypePropertyGet requestMethod:AYLA_REQUEST_METHOD_GET sourceLink:source uri:@"/local_lan/property/datapoint.json" data:nil];
                        
                        AylaLanCommandEntity *command = [[AylaLanCommandEntity alloc] initWithParams:cmdId jsonString:cmd type:AYLA_LAN_COMMAND];
                        [command setRespBlock:^(AylaLanCommandEntity *command, NSDictionary *resp, int status, AylaError *error) {
                            
                            if(status == AML_ERROR_PRECONDITION_FAILED || status >= 500) {
                                AylaError *error = [AylaError new];
                                error.httpStatusCode = status;
                                error.errorInfo = @{@"error" : [NSString stringWithFormat:@"Failed when retrieving %@", pName]};
                                [command.parentOperation invokeCallbackBlockWithResponse:nil responseObj:nil error:error];
                                return;
                            }
                            
                            if(status >= AML_ERROR_BAD_REQUEST) {
                                responseStatus = AML_ERROR_ASYNC_OK_PARTIAL_CONTENT;
                            }
                                                        
                            if(--count == 0){
                                AylaResponse *response = [AylaResponse new]; response.httpStatusCode = responseStatus;
                                [command.parentOperation invokeCallbackBlockWithResponse:response responseObj:nil error:nil];
                            }
                        }];
                        
                        [commands addObject:command];
                    }else{
                        AylaLogW(@"Properties", 0, @"name:%@, Skipped:%@, %@", pName, @"unableToFind-LAN", @"getProperties.lan");
                        count-- ;
                    }
                }
                
                if(commands.count > 0) {
                    AylaLanOperation *operation = [AylaLanOperation operationWithsubType:AylaLanOperationTypeProperty commands:commands callbackBlock:nil];
                    // allocate more time for this operation request
                   [operation setTimeoutInterval:[operation suggestedTimeoutInterval]];
                    [operation setCallbackBlock:^(AylaResponse *response, id responseObj, AylaError *error) {
                        if(!error) {
                            //success
                            NSMutableArray *array = [NSMutableArray new];
                            for(NSString *name in names) {
                                AylaProperty *prop = [properties objectForKey:name];
                                if(prop)
                                    [array addObject:[prop copy]];
                            }
                            AylaLogI(@"Properties", 0, @"%@:%ld, %@:%ld, %@", @"httpCode", (unsigned long)response.httpStatusCode, @"LAN", (unsigned long)array.count, @"getProperties.lan");
                            successBlock(response, array);
                        }
                        else {
                            AylaLogE(@"Properties", 0, @"%@, %@, %@", @"LAN", [error logDescription], @"getProperties.lan");
                            failureBlock(error);
                        }
                    }];
                    
                    if(![operation startOnSession:session]) {
                        AylaLogE(@"Properties", 0, @"%@:%@, %@", @"LAN", @"FailedToStartOnSession", @"getProperties.lan");
                    }
                    return operation;
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        AylaResponse *resp = [AylaResponse new];
                        resp.httpStatusCode = AML_ERROR_ASYNC_OK_NON_AUTH_INFO;
                        successBlock(resp, @[]);
                    });
                };
            }
            else if([AylaReachability getConnectivity]== AML_REACHABILITY_REACHABLE){
                NSString *path = [NSString stringWithFormat:@"%@%@%@",  @"devices/", device.key, @"/properties.json"];
                
                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                if([names nilIfNull]) {
                    [params setObject:names forKey:@"names"];
                }
                
                AylaLogD(@"Properties", 0, @"%@:%@, %@", @"path", path, @"getProperties");

                AylaHTTPOperation *operation =
                [[AylaApiClient sharedDeviceServiceInstance] getPath:path parameters:params success:^(AylaHTTPOperation *operation, id responseObject) {
                    
                    int i = 0;
                    NSMutableArray *properties = [NSMutableArray array];
                    for (NSDictionary *propertyDictionary in responseObject) {
                        AylaProperty *property = [[AylaProperty alloc] initDevicePropertyWithDictionary:propertyDictionary];
                        property.owner = device.dsn;
                        [properties addObject:property];
                        ++i;
                    }
                    AylaLogI(@"Properties", 0, @"%@:%d, %@", @"i", i, @"getProperties.get");
                    [AylaProperty lanModeEnable:device properties:properties];
                    
                    AylaDevice *lanDevice = [device managedCopy];
                    NSArray *bufferedProperties = lanDevice.properties.allValues;
                    
                    if(bufferedProperties.count > 0)
                        [AylaCache save:AML_CACHE_PROPERTY withIdentifier:lanDevice.dsn andObject: [NSMutableArray arrayWithArray:bufferedProperties]];
                    
                    successBlock(operation.response, properties);
                    
                } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                    AylaLogE(@"Properties", 0, @"%@, %@", error.logDescription,  @"getProperties.get");
                    failureBlock(error);
                }];
                return operation;
            }
            else{
                if([[AylaLanMode device] properties]!=nil && [[[AylaLanMode device] properties] count]!=0 &&
                   [AylaLanMode.device.dsn isEqualToString:device.dsn] &&
                   [AylaCache cachingEnabled:AML_CACHE_PROPERTY]){
                    NSMutableDictionary *properties = [[AylaLanMode device] properties];
                    NSArray *respArr = [properties allValues];
                    
                    AylaResponse *resp = [AylaResponse new];
                    resp.httpStatusCode = AML_ERROR_ASYNC_OK_NON_AUTH_INFO;
                    AylaLogI(@"Properties", 0, @"%@:%ld, %@:%ld, %@", @"httpCode", (long)resp.httpStatusCode, @"i", (unsigned long)respArr.count, @"getProperties.no_connectivity");
                    successBlock(resp, respArr);
                }
                else{
                    [AylaReachability determineReachability];
                    AylaError *err = [AylaError new]; err.errorCode = AML_ERROR_NO_CONNECTIVITY; err.nativeErrorInfo = nil;
                    err.httpStatusCode = 0; err.errorInfo = nil;
                    AylaLogE(@"Properties", 0, @"%@:%@, %@", @"Fail", @"no connectivity", @"getProperties.no_connectivity");
                    failureBlock(err);
                }
            }
       // }];
    }
    return nil;
}

static NSString * const kAylaDatapointAckEnabled = @"ack_enabled";
static NSString * const kAylaDatapointAckAt = @"acked_at";
static NSString * const kAylaDatapointAckStatus = @"ack_status";
static NSString * const kAylaDatapointAckMessage = @"ack_message";
static NSString * const kAylaDatapointDevTimeMs = @"dev_time_ms";
static NSString * const kAylaDatapointCreatedAtFromDevice = @"created_at_from_device";

- (id)initDevicePropertyWithDictionary:(NSDictionary *)propertyDictionary
{
  self = [super init];
  if (self)
  {
    if([propertyDictionary objectForKey:@"property"]) {
        propertyDictionary = propertyDictionary[@"property"];
    }
    NSDictionary *property = propertyDictionary;
    if (property) {
        self.baseType = [[property valueForKeyPath:@"base_type"] nilIfNull];
        self.value = ([property valueForKeyPath:@"value"] != [NSNull null])? [NSString stringWithFormat:@"%@", [property valueForKeyPath:@"value"]]: nil;
        self.deviceKey = [property valueForKeyPath:@"device_key"];
        self.name = [[property valueForKeyPath:@"name"] nilIfNull];
        self.key = [property valueForKeyPath:@"key"];
        self.direction = [[property valueForKeyPath:@"direction"] nilIfNull];
        self.displayName = [[property valueForKeyPath:@"display_name"] nilIfNull];
        self.dataUpdatedAt = [[property valueForKeyPath:@"data_updated_at"] nilIfNull];
        self.type = [[property valueForKeyPath:@"type"] nilIfNull];
        
        NSDateFormatter *timeFormater = [AylaSystemUtils timeFmt];
        _ackEnabled = [[[property objectForKey:kAylaDatapointAckEnabled] nilIfNull] boolValue];
        _ackedAt = [timeFormater dateFromString:[[property objectForKey:kAylaDatapointAckAt] nilIfNull]];
        _ackStatus = [[[property objectForKey:kAylaDatapointAckStatus] nilIfNull] integerValue];
        _ackMessage = [[[property objectForKey:kAylaDatapointAckMessage] nilIfNull] integerValue];
        
        [self updateDatapointFromProperty];
        
        //metadata
        _metadata = [[property valueForKeyPath:@"metadata"] mutableCopy];
        
    } else {
      saveToLog(@"%@, %@, %@:%@, %@", @"E", @"Properties", @"property", @"nil", @"retrieveDeviceProperties.initDevicePropertyWithDictionary");
    }
  }
  return self;
}

// ----------------------- Datapoint Helper Methods --------------------------
- (void)updateDatapointFromProperty
{    
    if(_datapoint == nil){
        _datapoint = [[AylaDatapoint alloc] init];
    }
    [_datapoint updateWithProperty:self params:nil];
}


//------------------------- Lan Mode Support ---------------------------

- (void)lanModeEnable:(AylaDevice*)device
{
    [self lanModeEnable:device property:self];
}

/*
+(void) lanModeEnable:(AylaProperty *)property{
    if([AylaSystemUtils currentState] == DISABLED){
        if([AylaLanMode device]!=nil){
            [[AylaLanMode device] setProperty:property];
        }
        else{
            saveToLog(@"%@, %@, %@:%@, %@", @"E", @"Property", @"lanMode", @"no device is enabled", @"lanModeEnable");
        }
    }
}
*/

+ (void)lanModeEnable:(AylaDevice *)device properties:(NSArray *)properties
{
    if([AylaSystemUtils lanModeState]!= DISABLED){
        AylaDevice *lanDevice = [device managedCopy];
        if(lanDevice){
            //properties update
            if(![lanDevice properties]) {
                lanDevice.properties = [NSMutableDictionary new];
            }
            
            NSMutableDictionary *propertyList = lanDevice.properties;
            for(AylaProperty *prop in properties) {
                AylaProperty *lanProp = lanDevice.properties[prop.name];
                if(lanProp) {
                    [lanProp updateWithCopy:prop];
                }
                else {
                    AylaProperty *copy = [prop copy];
                    [propertyList setObject:copy forKey:[prop.name copy]];
                }
            }
        }
        else{
            saveToLog(@"%@, %@, %@:%@, %@", @"W", @"AylaProperty", @"AylaLanMode.device", @"null", @"lanModeEnable_properties");
        }
    }
}

- (void)lanModeEnable:(AylaDevice*)device property:(AylaProperty *)property
{
    if(property) {
        [AylaProperty lanModeEnable:device properties:@[property]];
    }
}





// --------------------------- Retrive Property ----------------------------
- (NSOperation *)getPropertyDetail:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *response, AylaProperty *propertyUpdated))successBlock
               failure:(void (^)(AylaError *err))failureBlock
{
  NSString *path = [NSString stringWithFormat:@"%@%@%@", @"properties/", self.key, @".json"];
  saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Properties", @"path", path, @"retrieveDeviceProperty");
  return [[AylaApiClient sharedDeviceServiceInstance] getPath:path
                                            parameters:nil
       success:^(AylaHTTPOperation *operation, id responseObject) {
         AylaProperty *property = [[AylaProperty alloc] initDevicePropertyWithDictionary:responseObject];
         saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Properties", @"propertyKey", property.key, @"retrieveDeviceProperty.getPath");
         successBlock(operation.response, property);
       }
       failure:^(AylaHTTPOperation *operation, AylaError *error) {
         saveToLog(@"%@, %@, %@, %@", @"E", @"Properties", error.logDescription, @"retrieveDeviceProperty.getPath");
          failureBlock(error);
       }];
}


- (NSOperation *)createDatapoint:(AylaDatapoint *)datapoint
              success:(void (^)(AylaResponse *response, AylaDatapoint *datapoint))successBlock
              failure:(void (^)(AylaError *err))failureBlock;
{
    return [self createDatapoint:datapoint params:nil success:successBlock failure:failureBlock];
}

- (NSOperation *) createDatapoint:(AylaDatapoint *)datapoint params:(NSDictionary *)callParams
                          success:(void (^)(AylaResponse *response, AylaDatapoint *datapointCreated))successBlock
                          failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaDatapoint createDatapoint:self datapoint:datapoint params:callParams
                                  success:^(AylaResponse *response, AylaDatapoint *datapoint2) {
                                      _datapoint = datapoint2;
                                      successBlock(response, datapoint2);
                                  }
                                  failure:^(AylaError *err2) {
                                      failureBlock(err2);
                                  }];
}

- (void)createBlob:(NSDictionary *)callParams
         success:(void (^)(AylaResponse *response, AylaDatapointBlob *datapointCreated))successBlock
         failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaDatapointBlob createBlobWithProperty:self params:callParams success:successBlock failure:failureBlock];
}

- (NSOperation *)getDatapointsByActivity:(NSDictionary *)callParams
              success:(void (^)(AylaResponse *response, NSArray *datapoints))successBlock
              failure:(void (^)(AylaError *err))failureBlock;
{
  return [AylaDatapoint getDatapointsByActivity: self callParams:callParams
        success:^(AylaResponse *response, NSArray *datapoints2) {
            _datapoints = [NSMutableArray arrayWithArray: datapoints2 ];
          successBlock(response, datapoints2);
        }
        failure:^(AylaError *err2) {
          failureBlock(err2);
        }];
}

- (NSOperation *)getDatapointById:(NSString *)datapointId params:(NSDictionary *)callParams
             success:(void (^)(AylaResponse *response, AylaDatapoint *datapoint))successBlock
             failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaDatapoint getDatapointById:datapointId property:self params:callParams success:successBlock failure:failureBlock];
}

- (NSOperation *)getBlobsByActivity:(NSDictionary *)callParams
                    success:(void (^)(AylaResponse *response, NSArray *retrievedDatapoints))successBlock
                    failure:(void (^)(AylaError *err))failureBlock
{
   return [AylaDatapointBlob getBlobsByActvity:self callParams:callParams success:successBlock failure:failureBlock];
}

static NSString * const kAylaBlobPropertyName = @"property_name";
- (void)getBlobSaveToFlie:(AylaDatapointBlob *)datapoint params:(NSDictionary *)callParams
                   success:(void (^)(AylaResponse *response, NSString *retrieveBlobFileName))successBlock
                   failure:(void (^)(AylaError *err))failureBlock
{
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Datapoints", @"datapointProp", self.name, @"getBlobSaveToFlie");
    [AylaDatapointBlob getBlobLocation:datapoint success:^(AylaResponse *response, AylaDatapointBlob *retrievedDatapoint) {
        [AylaDatapointBlob getBlobSaveToFileWithDatapoint:retrievedDatapoint property:self params:callParams success:successBlock failure:failureBlock];
    } failure:failureBlock];
}

- (NSOperation *)createTrigger:(AylaPropertyTrigger *)propertyTrigger
            success:(void (^)(AylaResponse *response, AylaPropertyTrigger *propertyTriggerCreated))successBlock
            failure:(void (^)(AylaError *err))failureBlock
{
  return [AylaPropertyTrigger createTrigger: self propertyTrigger:propertyTrigger
     success:^(AylaResponse *response, AylaPropertyTrigger *propertyTriggerCreated) {
       _propertyTrigger= propertyTriggerCreated;
       successBlock(response, propertyTriggerCreated);
     }
     failure:^(AylaError *err) {
       failureBlock(err);
     }];
}

- (NSOperation *)getTriggers:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *response, NSArray *propertyTriggers))successBlock
               failure:(void (^)(AylaError *err))failureBlock
{
  return [AylaPropertyTrigger getTriggers: self callParams:callParams
    success:^(AylaResponse *response, NSMutableArray *propertyTriggers){
       _propertyTriggers= propertyTriggers;
       successBlock(response, propertyTriggers);
     }
     failure:^(AylaError *err){
       failureBlock (err);
     }];
}

- (NSOperation *)updateTrigger:(AylaPropertyTrigger *)propertyTrigger
                        success:(void (^)(AylaResponse *response, AylaPropertyTrigger *propertyTrigger))successBlock
                        failure:(void (^)(AylaError *err))failureBlock
{
  return [AylaPropertyTrigger updateTrigger:self propertyTrigger:propertyTrigger
    success:^(AylaResponse *response, AylaPropertyTrigger *propertyTrigger) {
      successBlock(response, propertyTrigger);
    }
    failure:^(AylaError *err) {
      failureBlock(err);
    }];
}

- (NSOperation *)destroyTrigger:(AylaPropertyTrigger *)propertyTrigger
                success:(void (^)(AylaResponse *response))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
  return [AylaPropertyTrigger destroyTrigger:propertyTrigger
      success:^(AylaResponse *response){
        successBlock(response);
       }
      failure:^(AylaError *err){
        failureBlock (err);
      }];
}

- (id)validatedValueFromDatapoint:(AylaDatapoint *)datapoint error:(AylaError * __autoreleasing *)error
{
    NSString *baseType = self.baseType;
    NSNumber *nValue = datapoint.nValue;
    NSString *sValue = datapoint.sValue;
    id value;
    NSDictionary *errorInfo;
    
    if(![baseType nilIfNull]) {
        errorInfo = @{ @"baseType" : @"can't be blank" };
    }
    else if ([baseType isEqualToString:@"integer"]) {
        if (nValue == nil){
            errorInfo = @{ @"nValue" : @"can't be blank" };
        }
        else if (strcmp([nValue objCType], @encode(long)) != 0 &&
                 strcmp([nValue objCType], @encode(int)) != 0){
            errorInfo = @{ @"nValue" : @"is invalid" };
        }
        else {
            value = nValue;
        }
    } else if ([baseType isEqualToString:@"string"]) {
        if (sValue == nil){
            errorInfo = @{ @"sValue" : @"can't be blank" };
        }
        else if(![sValue isKindOfClass:[NSString class]]) {
            errorInfo = @{ @"sValue" : @"is invalid" };
        }
        else {
            value = [sValue copy];
        }
    } else if ([baseType isEqualToString:@"boolean"]) {
        if (nValue == nil){
            errorInfo = @{ @"nValue" : @"can't be blank" };
        }
        else if (![nValue isKindOfClass:[NSNumber class]]) {
            errorInfo = @{ @"nValue" : @"is invalid" };
        }
        else {
            value = @(nValue.integerValue&1);
        }
    } else if ([baseType isEqualToString:@"decimal"] ||
               [baseType isEqualToString:@"float"]) {
        if (nValue == nil){
            errorInfo = @{ @"nValue" : @"can't be blank" };
        }
        else if (![nValue isKindOfClass:[NSNumber class]]) {
            errorInfo = @{ @"nValue" : @"is invalid" };
        }
        else {
            value = nValue;
        }
    } else if ([baseType isEqualToString:@"file"] ||
               [baseType isEqualToString:@"stream"]) {
        // Discussion:
        // Basetype of file/stream has to be handled differently.
        // If input datapoint is an instance of AylaDatapointBlob. Use 'url' attribute to complete validation.
        //
        // If input datapoint is an instance of AylaDatapoint. Since uploading files to 'file'/'stream' properties will
        // always create a empty datapoint first, library will skip validation here and always return null to indicate
        // an empty value.
        if([datapoint isKindOfClass:[AylaDatapointBlob class]]) {
            AylaDatapointBlob *blob = (AylaDatapointBlob *)datapoint;
            if([blob.url nilIfNull]) {
                value = blob.url;
            }
            else {
                errorInfo = @{ @"url" : @"is invalid" };
            }
        }
        else {
            value = [NSNull null];
        }
    } else {
        errorInfo = @{ @"baseType" : @"is unknown" };
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"Datapoints", @"baseType", baseType, @"createDatapoint: unknown base type");
    }
    
    if(errorInfo) {
        if(error != NULL) {
            *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                      httpCode:0
                                   nativeError:nil
                                  andErrorInfo:errorInfo];
        }
        return nil;
    }
    
    return value;
}

- (BOOL)validateDatapoint:(AylaDatapoint *)datapoint error:(AylaError * __autoreleasing *)error
{
    return [self validatedValueFromDatapoint:datapoint error:error]?YES:NO;
}

//--------------------cache helper methods

- (void)updateWithValue:(id)value params:(NSDictionary *)params
{
    if(value) {
        self.value = value;
    }
    
    if([params objectForKey:kAylaDatapointAckStatus]) {
        self.ackedAt = [params objectForKey:kAylaDatapointAckAt];
        self.ackMessage = [[params objectForKey:kAylaDatapointAckMessage] integerValue];
        self.ackStatus = [[params objectForKey:kAylaDatapointAckStatus] integerValue];
    }
    
    if([params objectForKey:kAylaDatapointDevTimeMs]) {
        NSTimeInterval timeInterval = [params[kAylaDatapointDevTimeMs] longLongValue]/1000.0;
        self.dataUpdatedAt = [[AylaSystemUtils timeFmt] stringFromDate:[[NSDate alloc] initWithTimeIntervalSince1970:timeInterval]];
    }
    else {
        self.dataUpdatedAt = [[AylaSystemUtils timeFmt] stringFromDate:[NSDate date]];
    }
    
    [self updateDatapointFromProperty];
}

- (void)updateWithCopy:(AylaProperty *)property
{
    if([property.name isEqualToString:property.name] &&
       [self hash] != [property hash]) {
        if(property.key)
            self.key = property.key;
        self.value = property.value;
        if(property.baseType)
            self.baseType = property.baseType;
        self.retrievedAt = property.retrievedAt;
        self.displayName = property.displayName;
        
        self.ackedAt = property.ackedAt;
        self.ackStatus = property.ackStatus;
        self.ackEnabled = property.ackEnabled;
        self.ackMessage = property.ackMessage;
    }
}


- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_baseType forKey:@"baseType"];
    [encoder encodeObject:_name forKey:@"name"];
    [encoder encodeObject:_deviceKey forKey:@"deviceKey"];
    [encoder encodeObject:_owner forKey:@"owner"];
    [encoder encodeObject:_type forKey:@"type"];
    [encoder encodeObject:_direction forKey:@"direction"];
    //[encoder encodeObject:_retrievedAt forKey:@"retrievedAt"];
    [encoder encodeObject:_key forKey:@"key"];
    [encoder encodeObject:_value forKey:@"value"];
    [encoder encodeObject:_dataUpdatedAt forKey:@"dataUpdatedAt"];
    [encoder encodeObject:_displayName?_displayName:[NSNull null] forKey:@"displayName"];
    [encoder encodeObject:_metadata forKey:@"metadata"];
    
    [encoder encodeObject:@(_ackEnabled) forKey:kAylaDatapointAckEnabled];
    [encoder encodeObject:_ackedAt forKey:kAylaDatapointAckAt];
    [encoder encodeObject:@(_ackStatus) forKey:kAylaDatapointAckStatus];
    [encoder encodeObject:@(_ackMessage) forKey:kAylaDatapointAckMessage];
}

- (id)initWithCoder:(NSCoder *)decoder
{    
    _baseType = [decoder decodeObjectForKey:@"baseType"];
    _name = [decoder decodeObjectForKey:@"name"];
    _deviceKey = [decoder decodeObjectForKey:@"deviceKey"];
    _owner = [decoder decodeObjectForKey:@"owner"];
    _type = [decoder decodeObjectForKey:@"type"];
    _direction = [decoder decodeObjectForKey:@"direction"];
    //_retrievedAt = [decoder decodeObjectForKey:@"retrievedAt"];
    _key = [decoder decodeObjectForKey:@"key"];
    _value = [decoder decodeObjectForKey:@"value"];
    _dataUpdatedAt= [decoder decodeObjectForKey:@"dataUpdatedAt"];
    _displayName = [decoder decodeObjectForKey:@"displayName"]!= [NSNull null] ?[decoder decodeObjectForKey:@"displayName"]:nil;
    _metadata = [[decoder decodeObjectForKey:@"metadata"] nilIfNull];

    _ackEnabled = [[decoder decodeObjectForKey:kAylaDatapointAckEnabled] boolValue];
    _ackedAt = [decoder decodeObjectForKey:kAylaDatapointAckAt];
    _ackStatus = [[decoder decodeObjectForKey:kAylaDatapointAckStatus] integerValue];
    _ackMessage = [[decoder decodeObjectForKey:kAylaDatapointAckMessage] integerValue];
    
    return self;
}

- (NSUInteger)hash
{
    return [self.key hash] ^ [self.value hash] ^ [self.retrievedAt hash] ^ [self.ackedAt hash];
}

//-------------------- helper methods ------------------

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaProperty *_copy = copy;
        _copy.baseType = [_baseType copy];
        _copy.name = [_name copy];
        _copy.deviceKey = [_deviceKey copy];
        _copy.owner = [_owner copy];
        _copy.type = _type;
        _copy.direction = [_direction copy];
        //_copy.retrievedAt = [_retrievedAt copy];
        _copy.key = [_key copy];
        _copy.value = [_value copy];
        _copy.displayName = [_displayName copy];
        _copy.dataUpdatedAt = [_dataUpdatedAt copy];
        _copy.datapoint = [_datapoint copy];
        _copy.datapoints = [_datapoints copy];
        _copy.metadata = [_metadata mutableCopy];
        _copy.ackEnabled = _ackEnabled;
        _copy.ackedAt = [_ackedAt copy];
        _copy.ackStatus = _ackStatus;
        _copy.ackMessage = _ackMessage;
    }
    return copy;
}

@end  // AylaProperty

NSString * const kAylaPropertyParamDatapointCount = @"count";
NSString * const kAylaPropertyParamDatapointIsAcked = @"ack";
NSString * const kAylaPropertyParamDatapointAckStatus = @"status";
NSString * const kAylaPropertyParamDatapointPollingRetries = @"repeat";
NSString * const kAylaPropertyParamDatapointPollingTimeInterval = @"interval";
NSString * const kAylaPropertyParamDatapointSinceDate = @"created_at_since_date";
NSString * const kAylaPropertyParamDatapointEndDate = @"created_at_end_date";

//==================================== AylaDatapoint ===========================

@interface AylaDatapoint ()
@property (nonatomic, copy, readwrite) NSString *id;
@property (nonatomic, copy, readwrite) NSDate *ackedAt;
@property (nonatomic, assign, readwrite) NSInteger ackStatus;
@property (nonatomic, assign, readwrite) NSInteger ackMessage;
@property (nonatomic, copy, readwrite) NSDate *createdAtFromDevice;

- (id)initPropertyDatapointWithDictionary:(NSDictionary *)datapointDictionary;
@end

@implementation AylaDatapoint

@synthesize createdAt = _createdAt;
@synthesize value = _value;
@synthesize nValue = _nValue;
@synthesize sValue = _sValue;
@synthesize retrievedAt = _retrievedAt;

+ (NSOperation *)createDatapointsWithBatchRequests:(NSArray AYLA_GENERIC(AylaDatapointBatchRequest *) *)requests
                                           success:(void (^)(AylaResponse *response, NSArray AYLA_GENERIC(AylaDatapointBatchResponse *) *batchResponses))successBlock
                                           failure:(void (^)(AylaError *err))failureBlock
{
    void (^localErrorHandler)(NSArray *) = ^(NSArray *errorObjs) {
        AylaError *respError = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                                httpCode:0
                                             nativeError:nil
                                            andErrorInfo:@{
                                                           kAylaErrorInfoDescription: @"Invalid request",
                                                           kAylaErrorInfoObjects: errorObjs
                                                           }];
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        failureBlock(respError);
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
    };
    
    AylaError *aError;
    NSMutableArray *reqErrors = [NSMutableArray arrayWithCapacity:requests.count];
    NSString *deviceDsn = nil;
    for (AylaDatapointBatchRequest *req in requests) {
        if(![req validateSelf:&aError]) {
            [reqErrors addObject:@{
                                     kAylaErrorInfoObject: req,
                                     kAylaErrorInfoObjectErrors: aError.errorInfo?:@{}
                                     }];
        }
        else if(![deviceDsn isEqualToString:[req.property.owner nilIfNull]]){
            // Check if all properties belonging to a same device.
            if(!deviceDsn) {
                deviceDsn = [req.property.owner nilIfNull];
            }
            else {
                [reqErrors addObject:@{
                                       kAylaErrorInfoObject: req,
                                       kAylaErrorInfoObjectErrors: @{
                                               kAylaErrorInfoDescription: @"Invalid request",
                                               NSStringFromSelector(@selector(property)) : @"is a property belonging to a different device"
                                               }
                                       }];
            }
        }
        aError = nil;
    }
    
    if(reqErrors.count > 0) {
        localErrorHandler(reqErrors);
        return nil;
    }
    
    //Compose request list
    NSMutableArray *JSONArray = [NSMutableArray arrayWithCapacity:requests.count];
    AylaError *jsonError;
    for (AylaDatapointBatchRequest *req in requests) {
        id JSONObject = [req toCloudJSONObject:&jsonError];
        if(JSONObject) {
            [JSONArray addObject:JSONObject];
        }
        else {
            [reqErrors addObject:@{
                                   kAylaErrorInfoObject: req,
                                   kAylaErrorInfoObjectErrors: jsonError.errorInfo?:@{}
                                   }];
        }
    }
    
    if(reqErrors.count > 0) {
        localErrorHandler(reqErrors);
        return nil;
    }
    
    NSDictionary *toCloudParams = @{@"batch_datapoints": JSONArray};
    return
    [[AylaApiClient sharedDeviceServiceInstance] postPath:@"/apiv1/batch_datapoints.json" parameters:toCloudParams
        success:^(AylaHTTPOperation *operation, id responseObject) {
            NSMutableArray *batchResponseArray = [NSMutableArray arrayWithCapacity:[(NSArray *)responseObject count]];
            
            for (NSDictionary *JSONDict in responseObject) {
                AylaDatapointBatchResponse *batchResp = [[AylaDatapointBatchResponse alloc] initWithJSONDictionary:JSONDict];
                if(batchResp) [batchResponseArray addObject:batchResp];
            }
            
            successBlock(operation.response, batchResponseArray);
        } failure:^(AylaHTTPOperation *operation, AylaError *error) {
            failureBlock(error);
        }];
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"\n" 
          "createdAt: %@\n"
          "retrievedAt: %@\n"
          "sValue: %@\n"
          "nValue: %@\n"
          , _createdAt, _retrievedAt, _sValue, _nValue]; 
}
//--------------------------- Set Property Data Point --------------------------------------

- (void)updateWithProperty:(AylaProperty *)property params:(NSDictionary *)params
{
    if(!property) {
        return;
    }
    
    NSNumberFormatter *form = [[NSNumberFormatter alloc] init];
    [form setNumberStyle:NSNumberFormatterDecimalStyle];
    
    if(property.value != nil){
        _value = [NSString stringWithString:property.value];
        _sValue = [NSString stringWithString:_value];
        _nValue = [form numberFromString:_value];
        if(property.dataUpdatedAt!=nil){
            _createdAt = [NSString stringWithString:property.dataUpdatedAt];
        }
        
        _ackedAt = [property.ackedAt copy];
        _ackStatus = property.ackStatus;
        _ackMessage = property.ackMessage;
    }
}

+ (NSOperation *)createDatapoint:(AylaProperty *)thisProperty datapoint:(AylaDatapoint *)datapoint params:(NSDictionary *)callParams
                      success:(void (^)(AylaResponse *response, AylaDatapoint *datapoint))successBlock
                      failure:(void (^)(AylaError *err))failureBlock
{
  NSString *valueStr;
  AylaError *error;
  id value = [thisProperty validatedValueFromDatapoint:datapoint error:&error];
  valueStr = [NSString stringWithFormat:@"%@", value];

  if(!error &&
    (![thisProperty.baseType nilIfNull]
     || [thisProperty.baseType isEqualToString:@"file"]
     || [thisProperty.baseType isEqualToString:@"stream"])) {
        
    error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                             httpCode:0
                          nativeError:nil
                         andErrorInfo:@{@"baseType" : @"is not supported"}];
  }
    
  if(error) {
      AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
      failureBlock(error);
      AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
      return nil;
  }

  //FIXME: Use 2 for now
  //Option 1: Add check to device type, treat diffently if input is node
  //Option 2: Go through all lan mode enabled devices and find a match one
  
  NSArray *lanDevices = [AylaLanMode activeDeviceList];
  AylaDevice *endpoint = nil;
  AylaDevice *sender = nil;
  for (AylaDevice *device in lanDevices) {
      endpoint = [device lanModeEdptFromDsn:thisProperty.owner];
      if(endpoint) {
          sender = device;
          break;
      }
  }
    
  if (endpoint && [endpoint isLanModeActive]) {
      
      NSString *propertyName = [endpoint lanModePropertyNameFromEdptPropertyName:thisProperty.name];
      if(![propertyName isEmptyString]) {
          // check whether requested property representitive is available
          AylaProperty *lanProp = [sender findProperty:propertyName];
          if(lanProp!=nil){
          }
          else{
              AylaLogE(@"Datapoints", 0, @"%@:%@, %@", @"lanProperty", @"cannot find", @"createDatapoint.lan");
              AylaError *err = [AylaError new]; err.errorCode = AML_ERROR_NOT_FOUND; err.nativeErrorInfo = nil;
              err.httpStatusCode = AML_ERROR_NOT_FOUND; err.errorInfo = nil;
              failureBlock(err);
              return nil;
          }
      }
      
      datapoint.createdAt = [[AylaSystemUtils timeFmt] stringFromDate:[NSDate date]];
      //datapoint.retrievedAt = [NSString stringWithString:datapoint.createdAt];
      datapoint.value = [NSString stringWithString:valueStr];
      
      AylaLanSession *session = sender.lanModule.session;
      int cmdId = [session nextCommandOutstandingId];
      int cmdType = [endpoint isKindOfClass:[AylaDeviceNode class]] && [(AylaDeviceNode *)endpoint isGenericNode]? AYLA_LAN_NODE_PROPERTY: AYLA_LAN_PROPERTY;

      NSString *jsonString = [endpoint lanModeToDeviceUpdateWithCmdId:cmdId property:thisProperty valueString:valueStr];
      
      AylaLanCommandEntity *command = [[AylaLanCommandEntity alloc] initWithParams:cmdId jsonString:jsonString type:cmdType];
      
      //Check if property has enabled datapoint acknowledgement.
      if(thisProperty.ackEnabled) {
          command.tag = AylaMessageTypeDatapointUpdateWithAck;
      }
      
      [command setRespBlock:^(AylaLanCommandEntity *command, NSDictionary *resp, int status, AylaError *error) {
          if(status >= 200 && status < 300) {
              if(command.tag == AylaMessageTypeDatapointUpdateWithAck) {
                  NSDictionary *data = [resp objectForKey:kAylaLanMessageParamData];
                  datapoint.ackedAt = [NSDate date];
                  datapoint.ackMessage = [[[data objectForKey:kAylaDatapointAckMessage] nilIfNull] integerValue];
                  datapoint.ackStatus = [[[data objectForKey:kAylaDatapointAckStatus] nilIfNull] integerValue];
              }
              AylaResponse *resp = [AylaResponse new]; resp.httpStatusCode = status;
              [command.parentOperation invokeCallbackBlockWithResponse:resp responseObj:datapoint error:nil];
          }
          else {
              AylaError *error = [AylaError new];
              error.httpStatusCode = status;
              error.errorInfo = @{@"error" : @"Failed when creating datapoint"};
              [command.parentOperation invokeCallbackBlockWithResponse:nil responseObj:nil error:error];
          }
      }];
      
      AylaLanOperation *operation = [AylaLanOperation operationWithsubType:AylaLanOperationTypeProperty commands:@[command] callbackBlock:nil];
      // allocate more time for this operation request
      [operation setTimeoutInterval:20];
      [operation setCallbackBlock:^(AylaResponse *response, id responseObj, AylaError *error) {
          if(!error) {
              //success
              AylaLogI(@"Datapoints", 0, @"%@:%@, %@", @"LAN", @"created", @"createDatapoints.lan");
              successBlock(response, (AylaDatapoint *)responseObj);
          }
          else {
              if(error.errorCode == AML_ERROR_NATIVE_CODE_REQUEST_TIMED_OUT) {
                  error.httpStatusCode = AML_ERROR_REQUEST_TIMEOUT;
              }
              AylaLogE(@"Datapoints", 0, @"%@:%@, %@", @"LAN", [error logDescription], @"createDatapoints.lan");
              failureBlock(error);
          }
      }];
      
      if(![operation startOnSession:session]) {
          AylaLogE(@"Datapoints", 0, @"%@:%@, %@", @"LAN", @"FailedToStartOnSession", @"createDatapoints.lan");
      }
      return operation;
    }
  else{
      NSDictionary *parameters =[NSDictionary dictionaryWithObjectsAndKeys:
                                 valueStr, @"value", nil ];
      NSDictionary *params =[NSDictionary dictionaryWithObjectsAndKeys:
                             parameters, @"datapoint", nil];
      NSString *path = [NSString stringWithFormat:@"%@%@%@", @"properties/", thisProperty.key, @"/datapoints.json"];
      AylaLogD(@"Datapoints", 0, @"%@:%@, %@", @"path", path, @"createDatapoint");
      
      __block AylaHTTPOperation *httpOperation =
      [[AylaApiClient sharedDeviceServiceInstance] postPath:path parameters:params
         success:^(AylaHTTPOperation *operation, id responseObject) {
             AylaDatapoint *datapoint = [[AylaDatapoint alloc] initPropertyDatapointWithDictionary:responseObject];
             saveToLog(@"%@, %@, %@, %@", @"I", @"Datapoints", @"none", @"createDatapoint.postPath");
             
             if(thisProperty.ackEnabled && !datapoint.ackedAt) {
                 NSInteger ackRepeat = [[callParams[kAylaPropertyParamDatapointPollingRetries] nilIfNull] integerValue];
                 if(ackRepeat < 1)
                     ackRepeat = AylaPropertyParamDefaultPollingRetries;
                 NSUInteger ackInterval = AylaPropertyParamDefaultPollingTimeInterval;
                 if(callParams[kAylaPropertyParamDatapointPollingTimeInterval])
                     ackInterval = [[callParams[kAylaPropertyParamDatapointPollingTimeInterval] nilIfNull] unsignedIntegerValue];
                 
                 AylaDatapoint *createdDatapoint = datapoint;
                 [AylaDatapoint getStatus:datapoint withProperty:thisProperty params:@{kAylaRequestAckRepeat:@(ackRepeat), kAylaRequestAckInterval:@(ackInterval)}
                            checkingBlock:^BOOL(AylaDatapoint *datapoint) {
                                if(operation.isCancelled || operation.isTimeout) {
                                    // Since http operation has been cancelled or timed out. skip left repeats
                                    return YES;
                                }
                                if(datapoint.ackedAt) {
                                    // ack info has been updated
                                    return YES;
                                }
                                return NO;
                            }
                          completionBlock:^(AylaDatapoint *datapoint, AylaError *error, BOOL isTimeout) {
                              if (isTimeout) {
                                  NSMutableDictionary *info = [NSMutableDictionary dictionary];
                                  if(createdDatapoint) [info setObject:createdDatapoint forKey:kAylaErrorInfoObject];
                                  [info setObject:NSLocalizedString(@"Polling timed out", nil) forKey:kAylaErrorInfoDescription];
                                  error = [AylaError createWithCode:AML_ERROR_NATIVE_CODE_REQUEST_TIMED_OUT
                                                           httpCode:AML_ERROR_REQUEST_TIMEOUT
                                                        nativeError:nil
                                                       andErrorInfo:info];
                              }
                              if(!error) {
                                  successBlock(operation.response, datapoint);
                              }
                              else {
                                  failureBlock(error);
                              }
                          }];
             }
             else {
                 successBlock(operation.response, datapoint);
             }
         } failure:^(AylaHTTPOperation *operation, AylaError *error) {
             saveToLog(@"%@, %@, %@, %@", @"E", @"Datapoints", error.logDescription, @"createDatapoint.postPath");
             
             error.errorCode = error.errorInfo? AML_USER_INVALID_PARAMETERS: AML_AYLA_ERROR_FAIL;
             
             failureBlock(error);
         }];
      return httpOperation;
  }
  return nil;
}

+ (void)getStatus:(AylaDatapoint *)datapoint withProperty:(AylaProperty *)property params:(NSDictionary *)callParams
    checkingBlock:(BOOL (^)(AylaDatapoint *datapoint))checkingBlock
  completionBlock:(void (^)(AylaDatapoint *datapoint, AylaError *error, BOOL isTimeout))completeBlock
{
    NSInteger repeat = [callParams[kAylaPropertyParamDatapointPollingRetries] integerValue];
    NSUInteger interval = [callParams[kAylaPropertyParamDatapointPollingTimeInterval] unsignedIntegerValue];
    AylaRequestAck *reqAck = [[AylaRequestAck alloc] initWithRepeatTime:repeat interval:interval];
    [reqAck setExecuteBlock:^(AylaRequestAck *ack) {
        [AylaDatapoint getDatapointById:datapoint.id property:property params:nil success:^(AylaResponse *response, AylaDatapoint *datapoint) {
            if(checkingBlock(datapoint)) {
                completeBlock(datapoint, nil, NO);
            }
            else if(![ack executeIfHaveMoreRetries]) {
                completeBlock(nil, nil, YES);
            }
        } failure:^(AylaError *err) {
            completeBlock(nil, err, NO);
        }];
    }];
    [reqAck execute];
}

- (void)lanModeEnable:(AylaProperty *)property
{
    if([AylaSystemUtils lanModeState] != DISABLED){
        AylaLanMode.device.property.value = [NSString stringWithString: self.value];
        AylaLanMode.device.property.dataUpdatedAt = [NSString stringWithString: self.createdAt];
        [[[AylaLanMode device] property] updateDatapointFromProperty];
        if(AylaLanMode.device.property.datapoints == nil){
            AylaLanMode.device.property.datapoints = [NSMutableArray array];
        }
        NSMutableArray *dps = AylaLanMode.device.property.datapoints;
        [dps addObject:self];
        AylaLanMode.device.property.datapoint = self;
    }
}

- (id)initPropertyDatapointWithDictionary:(NSDictionary *)datapointDictionary
{
  self = [super init];
  if (self) {
    NSDictionary *datapoint = [datapointDictionary objectForKey:@"datapoint"];
    if (datapoint) {
      self.id = [[datapoint valueForKey:@"id"] nilIfNull];
      self.createdAt = ([datapoint valueForKeyPath:@"created_at"] != [NSNull null]) ? [datapoint valueForKeyPath:@"created_at"] : @"";
      //self.value = [datapoint valueForKeyPath:@"value"];
      self.nValue = [datapoint valueForKeyPath:@"value"];
      self.sValue = [datapoint valueForKeyPath:@"value"];
      //self.retrievedAt = [NSDate date];
    
      NSDateFormatter *timeFormater = [AylaSystemUtils timeFmt];
      _ackedAt = [timeFormater dateFromString:[[datapoint valueForKey:kAylaDatapointAckAt] nilIfNull]];
      _ackStatus = [[[datapoint valueForKey:kAylaDatapointAckStatus] nilIfNull] integerValue];
      _ackMessage = [[[datapoint valueForKey:kAylaDatapointAckMessage] nilIfNull] integerValue];
        
      _createdAtFromDevice = [timeFormater dateFromString:[[datapoint valueForKey:kAylaDatapointCreatedAtFromDevice] nilIfNull]];
        
    } else {
      saveToLog(@"%@, %@, %@:%@, %@", @"E", @"Datapoints", @"datapoint", @"nil", @"createDatapoint.initSetPropertyDatapointWithDictionary");
    }
  }
  return self;
}

//---------------------------- Get Property Data Points ----------------------------------

+ (NSOperation *)getDatapointsByActivity:(AylaProperty *)property callParams:callParams
                success:(void (^)(AylaResponse *response, NSArray *datapoints))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
  // Limit count to maxCount
  NSNumber *count = [callParams valueForKeyPath:kAylaPropertyParamDatapointCount];
  NSNumber *maxCount = [AylaSystemUtils maxCount];
  count = ([count compare:maxCount] == NSOrderedAscending) ? count : maxCount;
    
    //Parse input params
    BOOL skipLanMode = NO;
    NSNumber * paramDatapointIsAcked = nil;
    NSNumber * paramDatapointAckStatus = nil;
    NSString * sinceDate = nil;
    NSString * endDate = nil;
    
    if(callParams) {
        // check if request could be lan mode supported
        if([callParams[kAylaPropertyParamDatapointIsAcked] nilIfNull]) {
            
            paramDatapointIsAcked = callParams[kAylaPropertyParamDatapointIsAcked];
            paramDatapointAckStatus = [callParams[kAylaDatapointAckStatus] nilIfNull];
            
            BOOL isAcked = paramDatapointIsAcked.boolValue;
            NSInteger ackStatus = paramDatapointAckStatus.integerValue;
            
            if (!isAcked
                || ackStatus >= AML_ERROR_BAD_REQUEST) {
                skipLanMode = YES;
            }
        }
        
        // check if contains time filter
        sinceDate = [callParams[kAylaPropertyParamDatapointSinceDate] nilIfNull];
        endDate = [callParams[kAylaPropertyParamDatapointEndDate] nilIfNull];
        if (sinceDate || endDate) {
            count = maxCount;
        }
    }
    
    AylaDevice *lanDevice = [[AylaDeviceManager sharedManager] deviceWithDsn:property.owner recursiveCheck:YES];
    AylaDevice *sender = [lanDevice lanModeDelegate];
    AylaLogD(@"Datapoints", 0, @"%@:%d, %@", @"skipLan", skipLanMode, @"getDatapoints");
    
    if (!skipLanMode
        && lanDevice
        && [lanDevice isLanModeActive]
        && [count intValue] == 1)
    {
        AylaLanSession *session = sender.lanModule.session;
        AylaProperty *lanProp = [lanDevice findProperty:property.name];
        if (lanProp != nil) {
            
            int cmdId = [session nextCommandOutstandingId];
            NSString *source = [NSString stringWithFormat:@"property.json?name=%@", lanProp.name];
            NSString *cmd = [lanDevice lanModeToDeviceCmdWithCmdId:cmdId messageType:AylaMessageTypePropertyGet requestMethod:AYLA_REQUEST_METHOD_GET sourceLink:source uri:@"/local_lan/property/datapoint.json" data:nil];
            
            AylaLanCommandEntity *command = [[AylaLanCommandEntity alloc] initWithParams:cmdId jsonString:cmd type:AYLA_LAN_COMMAND];
            [command setRespBlock:^(AylaLanCommandEntity *command, NSDictionary *resp, int status, AylaError *error) {
                if(status >= 200 && status < 300) {
                    AylaResponse *resp = [AylaResponse new]; resp.httpStatusCode = status;
                    [command.parentOperation invokeCallbackBlockWithResponse:resp responseObj:lanProp.datapoint error:nil];
                }
                else {
                    if(!error) {
                        error = [AylaError new];
                        error.httpStatusCode = status;
                        error.errorInfo = @{@"error" : @"Failed when retrieving datapoint"};
                    }
                    [command.parentOperation invokeCallbackBlockWithResponse:nil responseObj:nil error:error];
                }
            }];
            
            AylaLanOperation *operation = [AylaLanOperation operationWithsubType:AylaLanOperationTypeProperty commands:@[command] callbackBlock:nil];
            // allocate more time for this operation request
            [operation setTimeoutInterval:20];
            [operation setCallbackBlock:^(AylaResponse *response, id responseObj, AylaError *error) {
                if(!error) {
                    //success
                    AylaLogI(@"Datapoints", 0, @"%@, %@, %@", @"LAN", @"success", @"getDatapoints.lan");
                    successBlock(response, @[responseObj]);
                }
                else {
                    AylaLogE(@"Datapoints", 0, @"%@, %@:%@, %@", @"LAN", @"failed", [error logDescription], @"getDatapoints.lan");
                    failureBlock(error);
                }
            }];
            
            if(![operation startOnSession:session]) {
                AylaLogE(@"Datapoints", 0, @"%@, %@, %@", @"LAN", @"FailedToStartOnSession", @"getDatapoints.lan");
            }
            return operation;
        }
        else {
            AylaError *err = [AylaError new]; err.errorCode = AML_ERROR_NOT_FOUND; err.nativeErrorInfo = nil;
            err.httpStatusCode = AML_ERROR_NOT_FOUND; err.errorInfo = nil;
            AylaLogE(@"Datapoints", 0, @"%@, %@, %@", @"LAN", @"PropertyNotFound", @"getDatapoints.lan");
            failureBlock(err);
        }
    }
    else {
        // properties/44/datapoints.json?limit=5
        NSString *path = [NSString stringWithFormat:@"%@%@%@%@%@", @"properties/", property.key, @"/datapoints.json", @"?limit=", count];
        if (sinceDate) {
            path = [path stringByAppendingFormat:@"%@%@", @"&filter[created_at_since_date]=", [sinceDate stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        if (endDate) {
            path = [path stringByAppendingFormat:@"%@%@", @"&filter[created_at_end_date]=", [endDate stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
        AylaLogD(@"Datapoints", 0, @"%@, %@, %@", @"path", path, @"getDatapoints.get");
        
        //Rebuild request call params
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        if(paramDatapointIsAcked) [params setObject:paramDatapointIsAcked.boolValue?@"true":@"false" forKey:kAylaPropertyParamDatapointIsAcked];
        if(paramDatapointAckStatus) [params setObject:paramDatapointAckStatus forKey:kAylaPropertyParamDatapointAckStatus];
        
        AylaHTTPOperation *httpOperation =
         [[AylaApiClient sharedDeviceServiceInstance] getPath:path parameters:params
          success:^(AylaHTTPOperation *operation, id responseObject) {
              int i = 0;
              NSMutableArray *datapoints = [NSMutableArray array];
              for (NSDictionary *datapointDictionary in responseObject) {
                  AylaDatapoint *datapoint = [[AylaDatapoint alloc] initPropertyDatapointWithDictionary:datapointDictionary];
                  [datapoints addObject:datapoint];
                  i++;
              }
              AylaLogI(@"Datapoints", 0, @"%@:%d, %@", @"i", i, @"getDatapoints.get");
              successBlock(operation.response, datapoints);
          } failure:^(AylaHTTPOperation *operation, AylaError *error) {
              AylaLogE(@"Datapoints", 0, @"%@:%@, %@", @"failed", [error logDescription], @"RetrieveDatapoints.get");
              failureBlock(error);
          }];

        return httpOperation;
    }
    return nil;
}

+ (NSOperation *)getDatapointById:(NSString *)datapointId property:(AylaProperty *)property params:callParams
                                 success:(void (^)(AylaResponse *response, AylaDatapoint *datapoint))successBlock
                                 failure:(void (^)(AylaError *err))failureBlock
{
    if(!property.name || !property.deviceKey || !datapointId) {
        AylaError *error = [AylaError new]; error.errorCode = AML_USER_INVALID_PARAMETERS; error.nativeErrorInfo = nil;
        error.httpStatusCode = 0; error.errorInfo = @{@"error": @"invalid input."};
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        failureBlock(error);
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"devices/%@/properties/%@/datapoints/%@.json", property.deviceKey, property.name, datapointId];
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Datapoints", @"path", path, @"getDatapointById");
    
    AylaHTTPOperation *httpOperation =
    [[AylaApiClient sharedDeviceServiceInstance]
                     getPath:path parameters:callParams
     success:^(AylaHTTPOperation *operation, id responseObject) {
         AylaDatapoint *datapoint = [[AylaDatapoint alloc] initPropertyDatapointWithDictionary:responseObject];
         saveToLog(@"%@, %@, %@", @"I", @"Datapoint", @"getDatapointById");
         successBlock(operation.response, datapoint);
     } failure:^(AylaHTTPOperation *operation, AylaError *error) {
         AylaLogE(@"Datapoint", 0, @"%@, %@", error.logDescription, @"getDatapointById");
         failureBlock(error);
     }];

    return httpOperation;
}

//------------------------------helper methods---------------------------------
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        AylaDatapoint *_copy = copy;
        _copy.createdAt = [_createdAt copy];
        _copy.id = [_id copy];
        _copy.value = [_value copy];
        _copy.nValue = [_nValue copy];
        _copy.sValue = [_sValue copy];
        //_copy.retrievedAt = [_retrievedAt copy];
        
        _copy.ackedAt = [_ackedAt copy];
        _copy.ackStatus = _ackStatus;
        _copy.ackMessage = _ackMessage;
        
        _copy.createdAtFromDevice = [_createdAtFromDevice copy];
    }
    return copy;
}

@end


@interface AylaDatapointBlob ()

@property (nonatomic, strong) NSString *fileUrl;
@property (nonatomic, strong) NSString *location;

@end

@implementation AylaDatapointBlob

static NSString * const kAylaPropertyBaseTypeStream = @"stream"; //going to be deprecated
static NSString * const kAylaPropertyBaseTypeFile = @"file";

- (instancetype)initPropertyDatapointWithDictionary:(NSDictionary *)datapointDictionary
{
    self = [super initPropertyDatapointWithDictionary:datapointDictionary];
    if(self) {
        NSDictionary *attributes = [datapointDictionary objectForKey:@"datapoint"];
        self.location = [attributes objectForKey:@"location"]?:self.sValue;
        self.fileUrl = [attributes objectForKey:@"file"];
        self.closed = [[attributes objectForKey:@"closed"] boolValue];
        
        //get url from location
        if(self.location) {
            NSRange range = [self.location rangeOfString:@"devices/"];
            if(range.location != NSNotFound) {
                NSRange rangeOfJson = [self.location rangeOfString:@".json"];
                self.url = [NSString stringWithFormat:rangeOfJson.location == NSNotFound? @"%@.json": @"%@", [self.location substringFromIndex:range.location]];
            }
        }
    }
    return self;
}

+ (NSOperation *)getBlobsByActvity:(AylaProperty *)property callParams:callParams
                           success:(void (^)(AylaResponse *response, NSArray *retrievedDatapoints))successBlock
                           failure:(void (^)(AylaError *err))failureBlock
{
    NSNumber *count = [callParams valueForKeyPath:@"count"]?:@(1); //retrieve one datapoint by default
    NSNumber *maxCount = [AylaSystemUtils maxCount];
    count = ([count compare:maxCount] == NSOrderedAscending)? count : maxCount;
    
    NSString *path = [NSString stringWithFormat:@"%@%@%@%@%@", @"properties/", property.key, @"/datapoints.json", @"?limit=", count];
    saveToLog(@"%@, %@, %@:%@, %@: %@", @"I", @"Datapoints", @"path", path, @"getBlobs_count", count);
    
    return
    [[AylaApiClient sharedDeviceServiceInstance] getPath:path
                                              parameters:nil
                                                 success:^(AylaHTTPOperation *operation, id datapointsDict) {
                                                     NSMutableArray *datapoints = [NSMutableArray array];
                                                     for (NSDictionary *datapointDictionary in datapointsDict) {
                                                         AylaDatapointBlob *datapoint = [[AylaDatapointBlob alloc] initPropertyDatapointWithDictionary:datapointDictionary];
                                                         [datapoints addObject:datapoint];
                                                     }
                                                     successBlock(operation.response, datapoints);
                                                 }
                                                 failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                     error.errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt: AML_GET_BLOBS_GET], @"subtaskfailed", nil];
                                                     AylaLogE(@"Datapoint", 0, @"%@, %@", error.logDescription, @"RetrieveDatapoints.getPath");
                                                     failureBlock(error);
                                                 }];
}

+ (void)createBlobWithProperty:(AylaProperty *)property params:(NSDictionary *)callParams
                       success:(void (^)(AylaResponse *response, AylaDatapointBlob *retrievedBlobs))successBlock
                       failure:(void (^)(AylaError *err))failureBlock
{
    [AylaDatapointBlob createBlobDatapointWithProperty:property params:callParams success:^(AylaResponse *response, AylaDatapointBlob *datapoint) {
        [AylaDatapointBlob uploadBlobWithDatapoint:datapoint params:callParams success:^(AylaResponse *response, AylaDatapointBlob *datapoint) {
            [datapoint markFinished:nil success:^(AylaResponse *response) {
                //mark finished compelted, update close value to be true.
                datapoint.closed = YES;
                successBlock(response, datapoint);
            } failure:failureBlock];
        } failure:failureBlock];
    } failure:failureBlock];
}

+ (NSOperation *)createBlobDatapointWithProperty:(AylaProperty *)property params:(NSDictionary *)callParams
                                         success:(void (^)(AylaResponse *response, AylaDatapointBlob *datapoint))successBlock
                                         failure:(void (^)(AylaError *err))failureBlock
{
    if(!([property.baseType isEqualToString:kAylaPropertyBaseTypeFile] ||
         [property.baseType isEqualToString:kAylaPropertyBaseTypeStream])) {
        AylaError *err = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:@{@"base_type": @"should be stream"}];
        failureBlock(err);
        return nil;
    }
    
    if(!property.key) {
        AylaError *err = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:@{@"property": @"is invalid"}];
        failureBlock(err);
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"%@%@%@", @"properties/", property.key, @"/datapoints.json"];
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Datapoints", @"path", path, @"createDatapoint");
    return
    [[AylaApiClient sharedDeviceServiceInstance] postPath:path
                                               parameters:nil
                                                  success:^(AylaHTTPOperation *operation, id datapointDict) {
                                                      AylaDatapointBlob *datapoint = [[AylaDatapointBlob alloc] initPropertyDatapointWithDictionary:datapointDict];
                                                      saveToLog(@"%@, %@, %@, %@", @"I", @"Datapoints", @"none", @"createDatapoint.postPath");
                                                      successBlock(operation.response, datapoint);
                                                  }
                                                  failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                      AylaLogE(@"Datapoint", 0, @"%@, %@", error.logDescription, @"createDatapoint.postPath");
                                                      failureBlock(error);
                                                  }];
}


+ (NSOperation *)getBlobLocation:(AylaDatapointBlob *)datapoint
                            success:(void (^)(AylaResponse *response, AylaDatapointBlob *datapoint))successBlock
                            failure:(void (^)(AylaError *err))failureBlock
{
    if(!datapoint.url) {
        AylaError *err = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:@{@"url": @"is invalid"}];
        failureBlock(err);
        return nil;
    }
    
    return
    [[AylaApiClient sharedDeviceServiceInstance] getPath:datapoint.url parameters:nil
    success:^(AylaHTTPOperation *operation, id responseObject) {
        AylaDatapointBlob *datapoint = [[AylaDatapointBlob alloc] initPropertyDatapointWithDictionary:responseObject];
        saveToLog(@"%@, %@, %@, %@", @"I", @"Datapoints", @"none", @"updateBlobLocation");
        successBlock(operation.response, datapoint);
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        AylaLogE(@"Datapoint", 0, @"%@, %@", error.logDescription, @"updateBlobLocation");
        failureBlock(error);
    }];
}

+ (void)getBlobSaveToFileWithDatapoint:(AylaDatapointBlob *)datapoint property:(AylaProperty *)property
                  params:(NSDictionary *)callParams
                  success:(void (^)(AylaResponse *response, NSString *retrievedBlobName))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    NSString *url = datapoint.fileUrl;
    NSString *localPath = [callParams objectForKey:kAylaBlobFileLocalPath];
    NSString *propertyName = property.name;
    NSString *suffixName = [callParams objectForKey:kAylaBlobFileSuffixName];
    
    if(!url) {
        saveToLog(@"%@, %@, %@: %@, %@", @"E", @"Datapoints", @"Error", @"No URL found.", @"getBlobSaveToFile");
        AylaError *err = [AylaError new];
        err.errorCode = AML_AYLA_ERROR_FAIL;
        err.errorInfo = nil; err.nativeErrorInfo = nil;
        failureBlock(err);
        return;
    }

    NSString *fileName = [NSString stringWithFormat:@"%@_%@", propertyName?:@"Blob" ,suffixName?:@"BlobFile"];
    NSString *fileAbosultePath = [NSString stringWithFormat:@"%@%@/%@", [AylaSystemUtils rootDocumentsDirectory], localPath?:@"", fileName];
    
    AylaApiClient *client = [AylaApiClient HTTPClient];
    NSMutableURLRequest *request = [client requestWithMethod:AYLA_REQUEST_METHOD_GET path:url parameters:nil];
    
    AylaHTTPOperation *operation =
    [client operationWithDownloadRequest:request destination:^NSURL *(NSURL *filePath, NSURLResponse *response) {
        NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:fileAbosultePath isDirectory:NO];
        return fileUrl;
    } success:^(AylaHTTPOperation *operation, NSURL *filePath) {
        saveToLog(@"%@, %@, %@%@, %@", @"I", @"Datapoints", @"success", @"", @"getBlobSaveToFile");
        successBlock(operation.response, fileName);
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        error.errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys: @(AML_GET_BLOBS_SAVE_TO_FILE), @"subtaskfailed", nil];
        failureBlock(error);
    }];
    [operation start];
}

+ (void)uploadBlobWithDatapoint:(AylaDatapointBlob *)datapoint params:(NSDictionary *)callParams
                        success:(void (^)(AylaResponse *response, AylaDatapointBlob *datapoint))successBlock
                        failure:(void (^)(AylaError *err))failureBlock
{
    if(!datapoint.fileUrl) {
        AylaError *err = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:@{@"url": @"is invalid"}];
        failureBlock(err);
        return;
    }
    
    NSData *fileData = callParams[kAylaBlobFileData];
    NSURL *filePath = callParams[kAylaBlobFileUrl];
    NSNumber *fileSize = nil; NSInputStream *inputStream = nil;
    
    AylaApiClient *client = [AylaApiClient HTTPClient];
    NSMutableURLRequest *request = [client requestWithMethod:AYLA_REQUEST_METHOD_PUT path:datapoint.fileUrl parameters:nil];
    
    if(!request) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"Datapoints", @"request", @"can't be created", @"updateBlobWithDatapoint");
        AylaError *err = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                          httpCode:0
                                       nativeError:nil
                                      andErrorInfo:@{@"datapoint": @"is invalid"}];
        failureBlock(err);
        return;
    }
    
    void(^successHandler)(AylaHTTPOperation *, id) = ^(AylaHTTPOperation *operation, id responseObject) {
        saveToLog(@"%@, %@, %@%@, %@", @"I", @"Datapoints", @"success", @"", @"uploadBlobWithDatapoint");
        successBlock(operation.response, datapoint);
    };
        
    void (^failureHandler)(AylaHTTPOperation *, AylaError *)= ^(AylaHTTPOperation *operation, AylaError *error) {
        error.errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys: @(AML_GET_BLOBS_SAVE_TO_FILE), @"subtaskfailed", nil];
        failureBlock(error);
    };
    
    // Setup request header
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    AylaHTTPOperation *operation = nil;
    if(filePath) {
        NSError *fileError;
        [filePath getResourceValue:&fileSize
                            forKey:NSURLFileSizeKey
                             error:&fileError];
        
        inputStream = [NSInputStream inputStreamWithURL:filePath];
        if(fileError || !inputStream) {
            saveToLog(@"%@, %@, %@:%@, %@", @"E", @"Datapoints", @"filePath", @"is invalid", @"updateBlobWithDatapoint");
            AylaError *err = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                              httpCode:0
                                           nativeError:nil
                                          andErrorInfo:@{kAylaBlobFileUrl: @"is invalid"}];
            failureBlock(err);
            return;
        }
        
        // Setup header fields
        [request setValue:fileSize.stringValue forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBodyStream:inputStream];
        
        operation = [client operationWithStreamedUploadRequest:request success:successHandler failure:failureHandler];
        [operation start];
    }
    else if(fileData) {
        fileSize = @(fileData.length);
        
        operation = [client operationWithUploadRequest:request fromData:fileData success:successHandler failure:failureHandler];
        [operation start];
    }
    else {
        AylaError *err = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:@{@"file": @"not found"}];
        failureBlock(err);
        return;
    }
}

static NSString * const kAylaDatapointMarkFinishTag = @"type";
static NSString * const kAylaDatapointMarkFinishTagFetched = @"fetched";
static NSString * const kAylaDatapointMarkFinishTagUploaded = @"uploaded";
- (NSOperation *)markFetched:(NSDictionary *)callParams
            success:(void (^)(AylaResponse *response))successBlock
            failure:(void (^)(AylaError *err))failureBlock
{
    return [self markFinished:@{kAylaDatapointMarkFinishTag: kAylaDatapointMarkFinishTagFetched} success:successBlock failure:failureBlock];
}

- (NSOperation *)markFinished:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *response))successBlock
               failure:(void (^)(AylaError *err))failureBlock
{
    if(!self.url) {
        AylaError *err = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:@{@"url": @"is invalid"}];
        failureBlock(err);
        return nil;
    }
    
    NSDictionary *values = nil; NSDictionary *params = nil;
    if([callParams[kAylaDatapointMarkFinishTag] isEqualToString:kAylaDatapointMarkFinishTagFetched]) {
        values = @{kAylaDatapointMarkFinishTagFetched : @"True"};
    }
    if(values) {
        params = @{@"datapoint": values};
    }
    
    return
    [[AylaApiClient sharedDeviceServiceInstance] putPath:self.url parameters:params success:^(AylaHTTPOperation *operation, id responseObject) {
        saveToLog(@"%@, %@, %@: %@, %@", @"I", @"Datapoints", @"success", @"", @"markFinished");
        successBlock(operation.response);
    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
        error.errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt: AML_BLOBS_MARK_FINISH], @"subtaskfailed", nil];
        AylaLogE(@"Datapoint", 0, @"%@, %@", error.logDescription, @"markFinished");
        failureBlock(error);
    }];
}

- (NSString *)description
{
    NSString *description = [NSString stringWithFormat:@"<%@: %#x, url: %@, closed: %d>",
                             NSStringFromClass([self class]), (unsigned int) self, _url, _closed];
    return description;
}

@end

NSString * const kAylaDeviceTypeWifi = @"Wifi";
NSString * const kAylaDeviceTypeGateway = @"Gateway";
NSString * const kAylaDeviceTypeNode = @"Node";

NSString * const kAylaDeviceClassNameGateway = @"AylaDeviceGateway";
NSString * const kAylaDeviceClassNameNode = @"AylaDeviceNode";
NSString * const kAylaDeviceClassName = @"AylaDevice";
NSString * const kAylaDeviceProductName = @"product_name";

NSString * const kAylaBlobFileLocalPath = @"file_local_path";
NSString * const kAylaBlobFileSuffixName = @"file_suffix_name";
NSString * const kAylaBlobFileData = @"file_data";
NSString * const kAylaBlobFileUrl = @"file_url";
