//
//  AylaRegistration.m
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 8/29/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaRegistration.h"
#import "AylaApiClient.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaDevice.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceSupport.h"
#import "AylaSetup.h"
#import "AylaSetupSupport.h"
#import "AylaResponseSupport.h"
#import "AylaErrorSupport.h"
#import "NSObject+AylaNetworks.h"
#import "AylaDeviceManager.h"
#import "NSString+AylaNetworks.h"
#import "AylaDefines_Internal.h"

@interface AylaRegistration ()
@property (nonatomic, copy) NSString *regToken;
@property (nonatomic, copy) AylaDevice *regCandidate;
@property (nonatomic, copy) NSString *lanIpAddress;
@property (nonatomic, copy) NSDate *retrievedAt;
@end

@implementation AylaRegistration

@synthesize regToken = _regToken;
@synthesize regCandidate = _regCandidate;
@synthesize lanIpAddress = _lanIpAddress;
@synthesize retrievedAt = _retrievedAt;

- (NSString *)description
{
  return [NSString stringWithFormat:@"\n" 
          "regCandidate: %@\n"
          "lanIpAddress: %@\n"
          "retrievedAt: %@\n"
          , _regCandidate, _lanIpAddress, _retrievedAt];
}

// ---------------------- Register a New Device ---------------------------
//
// Prerequisites:
//   a) The local Ayla device has completed setup and connected to the Ayla device service withn the last hour
//   b) The local Ayla device and the phone/pad/pod/tablet running this code are connected to the same WLAN
//
// Steps
//   a) Get registration candidate device from the Ayla device service. Save the LAN IP address & DSN.
//   b) Get registration token from the local device using the LAN IP address
//   c) Register the local device with the Ayla device service using the Ayla local device registration token and DSN
//
// Returns
//   Success
//      A newly registered Ayla device
//   Failure
//     Ayla error code indicating which step failed
// 
// ------------------------------------------------------------------------
+ (void)registerNewDevice:(AylaDevice *)targetDevice
                   success:(void (^)(AylaResponse *response, AylaDevice *registeredDevice))successBlock
                   failure:(void (^)(AylaError *err))failureBlock
{
    AylaLogI(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"targetDsn", targetDevice.dsn, @"registerNewDevice");
    
    if(targetDevice == nil || targetDevice.registrationType == nil ||
       [targetDevice.registrationType isEqualToString:AML_REGISTRATION_TYPE_SAME_LAN] ||
       [targetDevice.registrationType isEqualToString:AML_REGISTRATION_TYPE_BUTTON_PUSH]){
        [AylaRegistration getRegistrationCandidateWithDsn:targetDevice.dsn andRegistrationType:targetDevice.registrationType params:nil
           success:^(AylaDevice *regCandidate1) {
             NSString *lanIp = regCandidate1.lanIp;
             NSString *dsn = regCandidate1.dsn;
             [AylaRegistration getModuleRegistrationToken:lanIp
                  success:^(NSString *regToken) {
                      [AylaRegistration registerDevice:(NSString *)dsn regToken:(NSString *)regToken setupToken:nil
                         success:^(AylaResponse *response, AylaDevice *newRegisteredDevice) {
                           successBlock(response, newRegisteredDevice);
                         }
                         failure:^(AylaError *err) {
                           failureBlock(err);
                         }
                     ];
                  }
                  failure:^(AylaError *err) {
                    failureBlock(err);
                  }
              ];
           }
           failure:^(AylaError *err) {
             failureBlock(err);
           }
        ];
    }
    else if([targetDevice.registrationType isEqualToString:AML_REGISTRATION_TYPE_AP_MODE]){
        if(targetDevice.setupToken != nil){
            
            [AylaRegistration registerDevice:targetDevice.dsn regToken:nil setupToken:targetDevice.setupToken
              success:^(AylaResponse *response, AylaDevice *newRegisteredDevice) {
                  successBlock(response, newRegisteredDevice);
              }failure:^(AylaError *err) {
                  failureBlock(err);
              }];
        }
        else{
            AylaError *err = [AylaError new]; err.errorCode = AML_NO_ITEMS_FOUND; err.httpStatusCode = 0; err.nativeErrorInfo = nil;
            NSDictionary *errDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"can't be blank.", @"setupToken", nil];
            err.errorInfo = errDict;
            AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"failed", [err logDescription], @"registerNewDevice.registerDevice.ap");
            failureBlock(err);
        }
    }
    else if([targetDevice.registrationType isEqualToString:AML_REGISTRATION_TYPE_DISPLAY]){
        if(targetDevice.registrationToken != nil){
            [AylaRegistration registerDevice:targetDevice.dsn regToken:targetDevice.registrationToken setupToken:nil
                                     success:^(AylaResponse *response, AylaDevice *newRegisteredDevice) {
                                         successBlock(response, newRegisteredDevice);
                                     }failure:^(AylaError *err) {
                                         failureBlock(err);
                                     }];
        }
        else{
            AylaError *err = [AylaError new]; err.errorCode = AML_NO_ITEMS_FOUND; err.httpStatusCode = 0; err.nativeErrorInfo = nil;
            NSDictionary *errDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"can't be blank.", @"setupToken", nil];
            err.errorInfo = errDict;
            AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"failed", [err logDescription], @"registerNewDevice.registerDevice.display");
            failureBlock(err);
        }
    }
    else if([targetDevice.registrationType isEqualToString:AML_REGISTRATION_TYPE_DSN] ||
            [targetDevice.registrationType isEqualToString:AML_REGISTRATION_TYPE_NODE]) {
        if(targetDevice.dsn != nil){
            [AylaRegistration registerDevice:targetDevice.dsn regToken:nil setupToken:nil
                                     success:^(AylaResponse *response, AylaDevice *newRegisteredDevice) {
                                         successBlock(response, newRegisteredDevice);
                                     }failure:^(AylaError *err) {
                                         failureBlock(err);
                                     }];
        }
        else {
            AylaError *err = [AylaError new]; err.errorCode = AML_NO_ITEMS_FOUND; err.httpStatusCode = 0; err.nativeErrorInfo = nil;
            NSDictionary *errDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"can't be blank.", @"dsn", nil];
            err.errorInfo = errDict;
            AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"failed", [err logDescription], @"registerNewDevice.registerDevice.dsn/n");
            failureBlock(err);
        }
    }
    else {
        AylaError *err = [AylaError new]; err.errorCode = AML_ERROR_NOT_FOUND; err.httpStatusCode = 0; err.nativeErrorInfo = nil;
        NSDictionary *errDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"is not supported.", @"registrationType", nil];
        err.errorInfo = errDict;
        [AylaSetup clear];
        AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"failed", [err logDescription], @"registerNewDevice");
        failureBlock(err);
    }

}

// Get the registration candidate from the Ayla device service
+ (void)getRegistrationCandidateWithDsn:(NSString *)targetDsn andRegistrationType:(NSString *)targetRegType
                           params:(NSDictionary *)callParams
                          success:(void (^)(AylaDevice *regCandidate))successBlock
                          failure:(void (^)(AylaError *err))failureBlock
{
    [AylaRegistration getRegistrationCandidatesWithDsn:targetDsn andRegistrationType:targetRegType params:callParams success:^(AylaResponse *resp, NSArray *candidates) {
        //never return an empty array
        if(candidates.count == 0) {
            AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"candidates", @"can't be empty.", @"getRegistrationCandidate.getPath");
        }
        successBlock(candidates[0]);
    } failure:failureBlock];
}

// Get the registration candidate from the Ayla device service
+ (NSOperation *)getRegistrationCandidatesWithDsn:(NSString *)targetDsn andRegistrationType:(NSString *)targetRegType
                                 params:(NSDictionary *)callParams
                                success:(void (^)(AylaResponse *resp, NSArray *candidates))successBlock
                                failure:(void (^)(AylaError *err))failureBlock
{
    NSString *tempPath = [NSString stringWithFormat:@"%@", @"devices/register.json"];
    NSMutableString *path = [NSMutableString stringWithString:tempPath];
    if (targetDsn) {
        [path appendString: [NSString stringWithFormat:@"%@%@",@"?dsn=", targetDsn, nil]];
        if(targetRegType) {
            [path appendString: [NSString stringWithFormat:@"&%@%@",@"regtype=", targetRegType, nil]];
        }
    }
    else if (targetRegType) {
        [path appendString:[NSString stringWithFormat:@"%@%@",@"?regtype=", targetRegType, nil]];
    }
    
    if ([[targetRegType nilIfNull] isEqualToString:AML_REGISTRATION_TYPE_NODE] &&
        [callParams objectForKey:kAylaRegistrationParamWindowLength]) {
        [path appendString:[NSString stringWithFormat:@"&%@=%@",
                            kAylaRegistrationParamWindowLength,
                            callParams[kAylaRegistrationParamWindowLength]]];
    }
    
    AylaLogI(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"path", path, @"getRegistrationCandidates");
    return
    [[AylaApiClient sharedDeviceServiceInstance] getPath:path parameters:nil
     success:^(AylaHTTPOperation *operation, id responseObject) {
         NSMutableArray *candidates = [NSMutableArray new];
         if([responseObject isKindOfClass:[NSArray class]]) {
             for(NSDictionary *deviceDictionary in responseObject) {
                 AylaDevice *candidate = [AylaDevice deviceFromDeviceDictionary:deviceDictionary];
                 candidate.registrationType = targetRegType;
                 [candidates addObject:candidate];
             }
             AylaLogI(AYLA_THIS_CLASS, 0, @"%@:%ld, %@", @"count", (unsigned long)candidates.count, @"getRegistrationCandidates.getPath");
         }
         else {
             AylaDevice *candidate = [AylaDevice deviceFromDeviceDictionary:responseObject];
             candidate.registrationType = targetRegType;
             [candidates addObject:candidate];
             AylaLogI(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"model", candidate.model, @"getRegistrationCandidates.getPath");
         }
         
         successBlock(operation.response, candidates);
     } failure:^(AylaHTTPOperation *operation, AylaError *error) {
         error.errorCode = AML_GET_REGISTRATION_CANDIDATE;
         AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"failed", error.logDescription, @"getRegistrationCandidates.getPath");
         failureBlock(error);
     }];
}


// Get the Module Registration token from the device on the local LAN
+ (void)getModuleRegistrationToken:(NSString *)lanIp
                            success:(void (^)(NSString *regToken))successBlock
                            failure:(void (^)(AylaError *err))failureBlock
{
  // http://192.168.0.1/regtoken.json
  NSString *path = [NSString stringWithFormat:@"%@", @"regtoken.json"];
  AylaLogI(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"lanIpAddress", lanIp, @"getRegistrationToken");
  [[AylaApiClient sharedConnectedDeviceInstance:lanIp] getPath:path
      parameters:nil
         success:^(AylaHTTPOperation *operation, id responseObject) {
           NSString *regToken = ([responseObject valueForKeyPath:@"regtoken"] != [NSNull null]) ? [responseObject valueForKeyPath:@"regtoken"] : @"";
           AylaLogI(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"regToken", @"retrieved", @"getRegistrationToken.getPath");
           successBlock(regToken);
           // retrieve the properties associated with the device
         }
         failure:^(AylaHTTPOperation *operation, AylaError *error) {
           error.errorCode = AML_GET_MODULE_REGISTRATION_TOKEN;
           AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"failed", error.logDescription, @"getRegistrationToken.getPath");
           failureBlock(error);
         }];
}

static NSInteger const defaultRegWindowDurationOpen = 200;
static NSInteger const defaultRegWindowDurationClose = 0;

+ (NSOperation *) openRegistrationWindow:(AylaDeviceGateway *)gateway params:(NSDictionary *)callParams
                                 success:(void (^)(AylaResponse *response))successBlock
                                 failure:(void (^)(AylaError *err))failureBlock
{
    NSInteger regWindowDuration = defaultRegWindowDurationOpen;
    if(callParams) {
        regWindowDuration =
        [callParams[kAylaDeviceGatewayRegWindowDuration] isNumber]? [callParams[kAylaDeviceGatewayRegWindowDuration] integerValue]: defaultRegWindowDurationOpen;
    }
    
    //url = "http://ads-dev.aylanetworks.com/apiv1/devices/<deviceId>/registration_window.json";
    NSDictionary *params = @{ kAylaDeviceGatewayRegWindowDuration: @(regWindowDuration) };
    NSString *path = [NSString stringWithFormat:@"%@/%@/%@", @"devices", gateway.key, @"registration_window.json"];
    return [[AylaApiClient sharedDeviceServiceInstance] postPath:path parameters:params
                                                         success:^(AylaHTTPOperation *operation, id responseObject) {
                                                             AylaLogI(AYLA_THIS_CLASS, 0, @"%@, %@", @"success", @"openRegistrationWindow");
                                                             successBlock(operation.response);
                                                         }
                                                         failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                             error.errorCode = AML_AYLA_ERROR_FAIL;
                                                             AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"failed", error.logDescription, @"openRegistrationWindow");
                                                             failureBlock(error);
                                                         }
            ];
}

+ (NSOperation *) closeRegistrationWindow:(AylaDeviceGateway *)gateway params:(NSDictionary *)callParams
                                 success:(void (^)(AylaResponse *response))successBlock
                                 failure:(void (^)(AylaError *err))failureBlock
{
    //url = "http://ads-dev.aylanetworks.com/apiv1/devices/<deviceId>/registration_window.json";
    NSDictionary *params = @{ kAylaDeviceGatewayRegWindowDuration: @(defaultRegWindowDurationClose) };
    NSString *path = [NSString stringWithFormat:@"%@/%@/%@", @"devices", gateway.key, @"registration_window.json"];
    return [[AylaApiClient sharedDeviceServiceInstance] postPath:path parameters:params
                                                         success:^(AylaHTTPOperation *operation, id closeRegistrationWindow) {
                                                             AylaLogI(AYLA_THIS_CLASS, 0, @"%@, %@", @"success", @"closeRegistrationWindow");

                                                             successBlock(operation.response);
                                                         }
                                                         failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                             error.errorCode = AML_AYLA_ERROR_FAIL;
                                                             AylaLogE(AYLA_THIS_CLASS, 0, @"%@, %@, %@", @"failed", error.logDescription, @"closeRegistrationWindow");
                                                             failureBlock(error);
                                                         }
            ];
}

// Register the device with the Ayla device service
+ (NSOperation *)registerDevice:(NSString *)dsn regToken:(NSString *)regToken setupToken:(NSString *)setupToken
          success:(void (^)(AylaResponse *response, AylaDevice *registeredDevice))successBlock
          failure:(void (^)(AylaError *err))failureBlock
{
  //{"device":{"dsn":"AC000WT00000999","regtoken":"4d54f2"}}
  NSDictionary *parameters;
  if (setupToken != nil)
      parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                    dsn, @"dsn",
                    setupToken, @"setup_token",
                    nil ];
  else if(regToken != nil)
      parameters = dsn?[NSDictionary dictionaryWithObjectsAndKeys:
                   dsn, @"dsn",
                   regToken, @"regtoken",
                   nil ]:
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   regToken, @"regtoken",
                   nil];
  else
      parameters = dsn?[NSDictionary dictionaryWithObjectsAndKeys:
                        dsn, @"dsn", nil]:@{};
     
  NSDictionary *params =[NSDictionary dictionaryWithObjectsAndKeys:
                         parameters, @"device", nil];
  NSString *path = [NSString stringWithFormat:@"%@", @"devices.json"];
  AylaLogD(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"params", params, @"registerDevice.postPath");
    
  return [[AylaApiClient sharedDeviceServiceInstance] postPath:path parameters:params
      success:^(AylaHTTPOperation *operation, id responseObject) {
        AylaDevice *regCandidate = [AylaDevice deviceFromDeviceDictionary:responseObject];
        AylaLogI(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"productName", regCandidate.productName, @"registerDevice.postPath");
        successBlock(operation.response, regCandidate);
      }
      failure:^(AylaHTTPOperation *operation, AylaError *error) {
        error.errorCode = AML_REGISTER_DEVICE;
        AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"failed", [error logDescription], @"registerDevice.postPath");
        failureBlock(error);
      }
   ];
}

//------------------------------- Unregister -----------------------------
// Unregister a device from the Ayla device service
+ (NSOperation *)unregisterDevice:(AylaDevice *)device callParams:(NSDictionary *)callParams
            success:(void (^)(AylaResponse *response))successBlock
            failure:(void (^)(AylaError *err))failureBlock
{
  NSString *path = [NSString stringWithFormat:@"%@%@%@", @"devices/", device.key, @".json"];
  return [[AylaApiClient sharedDeviceServiceInstance] deletePath:path parameters:nil
      success:^(AylaHTTPOperation *operation, id responseObject) {
         AylaLogI(AYLA_THIS_CLASS, 0, @"%@:%ld, %@", @"success", (long)operation.response.httpStatusCode, @"unregisterDevice.deletePath");
        [AylaCache clearAll];
          [[AylaDeviceManager sharedManager] removeDevices:@[device]];
          double delayInSeconds = 2.0;
          dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
          dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
              successBlock(operation.response);
          });
      }
      failure:^(AylaHTTPOperation *operation, AylaError *error) {
        AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"failed", [error logDescription], @"unRegisterDevice.deletePath");
        failureBlock(error);
      }
   ];
}

@end

NSString * const kAylaRegistrationParamWindowLength = @"time";
