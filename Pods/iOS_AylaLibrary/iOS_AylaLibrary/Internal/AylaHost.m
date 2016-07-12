//
//  AylaHost.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/22/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaHost.h"
#import "AylaSetupSupport.h"
#import "AylaModuleSupport.h"
#import "AylaDeviceSupport.h"
#import "AylaLanModeSupport.h"
#import "AylaSecuritySupport.h"
#import "AylaErrorSupport.h"
#import "AylaDefines_Internal.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaReachabilitySupport.h"
#import "NSObject+AylaNetworks.h"
@implementation AylaHost

+ (void)connectToNewDeviceContinued:
        /*success:*/ (void (^)(AylaResponse *, AylaModule *))successBlock
        failure: (void (^)(AylaError *))failureBlock
{
    [AylaSetup init];
    
    if(![AylaSetup isConnectedToPotentialNewDevice]) {
        AylaError *err = [AylaError new];
        err.errorCode = AML_NO_DEVICE_CONNECTED;
        err.httpStatusCode = 0;
        
        // Update error message to @"No new device found." in iOS 9.
        NSDictionary *description =
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
        @{@"error": @"No new device found."};
#else
        @{@"error": @"Invalid new device SSID."};
#endif
        err.errorInfo = description;
        err.nativeErrorInfo = nil;
        
        failureBlock(err);
        return;
    }

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    [AylaSetup setHostNewDeviceSsid:@"TEMP_SSID"];
#else
    [AylaSetup setHostNewDeviceSsid:[self returnHostNetworkConnection]];
#endif
    [AylaSetup setHostNewDevicePassword:@""];
    [AylaSetup setHostNewDeviceSecurityType:AML_OPEN];
    [AylaSetup setConnectedMode:AML_CONNECTED_TO_HOST];
    //saveToLog(@"%@, %@, %@:%@, %@", @"I", @"AylaSetup", @"newDeviceSsid", curSsid, @"AylaHost.connectToNewDevice");
    
    [[AylaSetup newDevice] getNewDeviceDetail:
         /*success:*/^(AylaResponse *response, AylaModule *newDevice){
             AylaSetup.newDevice.dsn = newDevice.dsn;
             AylaSetup.newDevice.deviceService = newDevice.deviceService;
             AylaSetup.newDevice.lastConnectMtime = newDevice.lastConnectMtime;
             AylaSetup.newDevice.version = newDevice.version;
             AylaSetup.newDevice.apiVersion = newDevice.apiVersion;
             AylaSetup.newDevice.build = newDevice.build;
             AylaSetup.newDevice.mac = newDevice.mac;
             AylaSetup.newDevice.registrationType = newDevice.registrationType;
             AylaSetup.newDevice.features = newDevice.features;
             AylaSetup.newDevice.lanIp = AML_SETUP_DEFAULT_NEW_DEVICE_LAN_IP; // Set default lan ip
             AylaSetup.newDevice.connectorLanIp = [AylaSystemUtils getIPAddress];
             AylaSetup.newDevice.hasConnected = YES;
             [AylaSetup.newDevice startListeningDisconnection];
             
             saveToLog(@"%@, %@, %@:%@, %@:%@, %@:%@, %@", @"I", AYLA_THIS_CLASS, @"dsn", newDevice.dsn, @"mac", newDevice.mac, @"build", newDevice.build, @"connectToNewDevice.getNewDeviceDetail");
             // Set new device time
             NSNumber *newTime = [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]];
                       
             void (^blockContinued)() = ^(){
                 [[AylaSetup newDevice] setNewDeviceTime:newTime
                         success:^(AylaResponse *response){
                             AylaLogI(AYLA_THIS_CLASS, 0, @"%@:%@, %@.%@", @"deviceNewTime", newTime, AYLA_THIS_METHOD, @"setNewDeviceTime");
                             [AylaSetup setLastMethodCompleted:AML_SETUP_TASK_CONNECT_TO_NEW_DEVICE];
                             
                             // Do retrieve wifi status history
                             [AylaSetup getNewDeviceWiFiStatus:^(AylaResponse *response, AylaWiFiStatus *wifiStatus){} failure:^(AylaError *err){}];
                             successBlock(response, AylaSetup.newDevice);
                         } failure:^(AylaError *err) {
                             AylaLogE(AYLA_THIS_CLASS, 0, @"%@, %@.%@", err.logDescription, AYLA_THIS_METHOD, @"setNewDeviceTime");
                             failureBlock(err);
                         }
                  ];
             };
             
            if(AylaSetup.newDevice.features && [AylaSetup.newDevice.features containsObject:@"rsa-ke"]) {
                // Key exchange required
                 if([AylaLanMode lanModeState]!= RUNNING)
                     [AylaLanMode enable];
                
                 [newDevice lanModeEnableWithType:AylaLanModeSessionTypeSetup];
                 __block BOOL getResp = NO;
                 __block NSObject *synchronizedObj = [NSObject new];
                 [AylaSetup continueBlock:^(BOOL isEastablished) {
                     [AylaSetup continueBlock:nil];
                     
                     @synchronized(synchronizedObj) {
                         getResp = YES;
                         if(isEastablished) {
                             blockContinued();
                         }
                         else {
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 AylaError *error = [AylaError new]; error.errorCode = AML_ERROR_FAIL;
                                 error.nativeErrorInfo = nil;
                                 error.errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"key exchange failed", @"error", nil];
                                 AylaLogE(AYLA_THIS_CLASS, 0, @"%@, %@", @"key exchange failed", AYLA_THIS_METHOD);
                                 failureBlock(error);
                             });
                         }
                     }
                }];
                
                //[AylaSecurity startKeyNegotiation:lanDevice.lanModule.session returnBlock:[AylaSetup continueBlock]];
                 NSUInteger addtions = [AylaSecurity isRSAKeyPairAvailable]? AML_SECURITY_KEY_EXCHANGE_RSA_WITH_KEY_PAIR:AML_SECURITY_KEY_EXCHANGE_RSA_WITHOUT_KEY_PAIR; // two timeout values
                 double delayInSeconds = DEFAULT_SETUP_WIFI_HTTP_TIMEOUT+addtions;
                 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                 dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                     @synchronized(synchronizedObj){
                         if(!getResp){
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 AylaError *error = [AylaError new]; error.errorCode = AML_ERROR_FAIL;
                                 error.nativeErrorInfo = nil;
                                 error.errorInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"key exchange failed", @"error", nil];
                                 AylaLogE(AYLA_THIS_CLASS, 0, @"%@:%@, %@", @"timeout", @"key exchange failed", AYLA_THIS_METHOD);
                                 failureBlock(error);
                             });
                             [AylaSetup continueBlock:nil];
                         }
                     }
                 });
             }
             else {
                 blockContinued();
             }
         } failure:^(AylaError *err) {
             AylaLogE(AYLA_THIS_CLASS, 0, @"%@, %@.%@", err.logDescription, AYLA_THIS_METHOD, @"getNewDeviceDetail");
             failureBlock(err);
         }
     ];
}


+ (void)connectToNewDevice:
        /*success:*/(void (^)(AylaResponse *response, AylaModule * newDevice))successBlock
        failure:(void (^)(AylaError *err))failureBlock
{    
    __block NSUInteger failureTries = 3;
    void (^__block _failureBlock)(AylaError *);
    void (^__block __weak __failureBlock)(AylaError *);
    __failureBlock = _failureBlock = ^(AylaError *err) {
        NSInteger subTask = [[err.errorInfo objectForKey:@"subTaskFailed"] integerValue];
        if(err.errorCode == AML_NO_DEVICE_CONNECTED
         || (subTask == AML_GET_NEW_DEVICE_DETAIL && err.httpStatusCode >= AML_ERROR_BAD_REQUEST)) {
            failureBlock(err);
        }
        else if(--failureTries>0){
            saveToLog(@"%@, %@, %@, %@:%lu, %@", @"E", AYLA_THIS_CLASS, @"Failed", @"retries", (unsigned long)failureTries, AYLA_THIS_METHOD);
            [AylaHost connectToNewDeviceContinued:^(AylaResponse *response, AylaModule *newDevice) {
                successBlock(response, newDevice);
            } failure:__failureBlock];
        }
        else {
            failureBlock(err);
        }
    };
    [AylaHost connectToNewDeviceContinued:
            /*success:*/ ^(AylaResponse *response, AylaModule *newDevice) {
                successBlock(response, newDevice);
            } failure: _failureBlock];
    
}

+ (NSString *)returnHostNetworkConnection
{
    /**
     Warning Discussion
     
     Below is Apple's note to Captive Network framework:
     
    @note IMPORTANT: This API is deprecated starting in iOS 9.
     For captive network applications, this has been completely
     replaced by <NetworkExtension/NEHotspotHelper.h>.
     For other applications, there is no direct replacement.
     Please file a bug describing your use of this API so that
     we can consider your requirements as this situation evolves.
     
     Hence, library looses limit here so that SSID name could be returned
     as long as Captive Network is still applicable.
     
     */
    NSArray *iface = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSDictionary* info = (__bridge_transfer id) CNCopyCurrentNetworkInfo((__bridge CFStringRef)([iface objectAtIndex:0]));
    if(![[info valueForKeyPath:@"SSID"] nilIfNull]) return nil;
    return [[info valueForKeyPath:@"SSID"] copy];
}


+ (Boolean)matchDeviceSsidRegex:(NSString *)ssid
{
    NSError *error = NULL;
    static NSRegularExpression *regex;
    if(regex==NULL){
        regex = [NSRegularExpression regularExpressionWithPattern:deviceSsidRegex
            options:NSRegularExpressionCaseInsensitive
            error:&error];
    }
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:ssid
                                                        options:0
                                                        range:NSMakeRange(0, [ssid length])];
    return numberOfMatches == 0? NO:YES;
}

+ (Boolean)isNewDeviceConnected
{
    // Workaround for potential SSID issue in future iOS release.
    // Use SSID if possbile, otherwise check new device's hasConnected value.
    NSString *curSsid = [[AylaHost returnHostNetworkConnection] nilIfNull];
    if(curSsid) {
        return [AylaHost matchDeviceSsidRegex:curSsid];
    }
    return [[AylaSetup newDevice] hasConnected];
}

@end
