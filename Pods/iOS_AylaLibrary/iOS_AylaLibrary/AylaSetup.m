//
//  AylaSetup.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/17/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaHost.h"
#import "AylaModuleSupport.h"
#import "AylaDeviceSupport.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaErrorSupport.h"
#import "AylaSecuritySupport.h"
#import "AylaCacheSupport.h"
#import "AylaDefines_Internal.h"
#import "NSObject+AylaNetworks.h"
#define AYLA_SETUP_DEVICE_CONNECT_TO_SERVICE @"wifi_connect.json?"
#define AYLA_SETUP_TOKEN_LEN 6

//--------------------AylaSetup--------------------
@implementation AylaSetup

    static NSString *connectedMode = AML_CONNECTION_UNKNOWN; // connection status of the new device
    static BOOL inExit = false;
    static int lastMethodCompleted = AML_SETUP_TASK_NONE;	  // incremented as each Setup task is completed. Use in an application task progress indicator

    static AylaModule *newDevice = nil;	// new device selected by user

    //Connect To new Device
    static NSString *hostOriginalSsid = nil; // phone/tablet ssid it is originally connected to
    static NSString *hostNewDeviceSsid = nil; // ssid of Ayla new device in AP mode selected by user
    static NSString *hostNewDevicePassword = nil; // null for Ayla AP mode
    static NSString *hostNewDeviceSecurityType = AML_OPEN; // OPEN for Ayla new device in AP mode
    static NSString *hostNewDeviceLanId = GBL_MODULE_DEFAULT_WIFI_IPADDR; // 192.168.0.1 default ip addr in AP mode
    static NSString *newDeviceDsn = nil; // dsn

    //Connect New Device To Service
    static NSString *setupToken = nil; // setup token sent to new device and service for secure association
    static Boolean hidden = false;   // is wifi hidden TBD
    static NSString *lanSsid = nil;    // WLAN AP with internet access ssid
    static NSString *lanPassword = nil; // WLAN AP with internet access pswd
    static NSString *lanSecurityType = nil; // WLAN AP with internet access security type

    //Confirm Device To Service Connection
    static NSString *lanIp = nil;	// WLAN IP address of new device connected to device service
    static int newDeviceToServiceConnectionRetries = 0;	// number of retries to confirm successful setup. Use in an application progress indicator.
    static int newDeviceToServiceNoInternetConnectionRetries = 0;

    //Init Securing WiFi Setup
    static AylaSetupSecurityType securityType = AylaSetupSecurityTypeNone;
    static void (^continueBlock)(BOOL isEastablished) = nil;

+ (void)init
{    
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"AylaSetup", @"entry", @"OK", @"init()");
    newDeviceDsn = nil;
    setupToken = nil;
    
    newDevice = [[AylaModule alloc] init];
    inExit = false;
    lastMethodCompleted = AML_SETUP_TASK_INIT;
    
    connectedMode = AML_CONNECTION_UNKNOWN;
    hostOriginalSsid = nil;
    hostNewDeviceSsid = nil;
    hostNewDevicePassword = nil;
    hostNewDeviceSecurityType = AML_OPEN;
    hostNewDeviceLanId = GBL_MODULE_DEFAULT_WIFI_IPADDR;
    newDeviceDsn = nil;
    
    // Connect New Device To Service
    setupToken = nil;
    hidden = false;
    lanSsid = nil;
    lanPassword = nil;
    lanSecurityType = nil;
    
    // Confirm Device To Service Connection
    lanIp = nil;
    newDeviceToServiceConnectionRetries = 0;
    newDeviceToServiceNoInternetConnectionRetries = 0;
    
    securityType = AylaSetupSecurityTypeNone;
    continueBlock = nil;
}

+ (BOOL)isConnectedToPotentialNewDevice
{
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
    
    /**
     If SSID info is available, keep using +isNewDeviceConnected
     to determine connectivity.
     */
    if([AylaHost returnHostNetworkConnection]) {
        return [AylaHost isNewDeviceConnected];
    }
    
    NSString *lanIp = [[AylaSystemUtils getIPAddress] nilIfNull];
    BOOL isPossibleLanIp = lanIp? ([lanIp rangeOfString:AML_SETUP_DEFAULT_NEW_DEVICE_LAN_IP_PREFIX].location != NSNotFound): NO;
    return isPossibleLanIp;
#else
    return [AylaHost isNewDeviceConnected];
#endif
}

+ (void)connectToNewDevice:
                /*success:*/(void (^)(AylaResponse *response, AylaModule *newDevice))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    [AylaHost connectToNewDevice:successBlock failure:failureBlock];
}

+ (void)getNewDeviceScanForAPs:
                /*success:*/(void (^)(AylaResponse *response, NSMutableArray *apList))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    [AylaModule getNewDeviceScanForAPs:successBlock failure:failureBlock];
}

+ (void) connectNewDeviceToService:(NSString *)ssid
                          password:(NSString *)password
                    optionalParams:(NSDictionary *)callParams
                           success:(void (^)(AylaResponse *))successBlock
                           failure:(void (^)(AylaError *))failureBlock
{
    [AylaModule connectNewDeviceToService:ssid password:password optionalParams:callParams success:successBlock failure:failureBlock];
}

+ (void)connectNewDeviceToService:(NSString *)ssid
                password:(NSString *)password isHidden: (Boolean)isHidden
                success:(void (^)(AylaResponse *response))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    [self connectNewDeviceToService:ssid password:password optionalParams:nil success:successBlock failure:failureBlock];
}

+ (void) connectNewDeviceToService:(NSString *)ssid
                          password:(NSString *)password
                    optionalParams:(NSDictionary *)callParams
                          isHidden:(Boolean)isHidden
                           success:(void (^)(AylaResponse *))successBlock
                           failure:(void (^)(AylaError *))failureBlock
{
    [self connectNewDeviceToService:ssid password:password optionalParams:callParams success:successBlock failure:failureBlock];
}

+ (void)confirmNewDeviceToServiceConnection:
                /*success:*/(void (^)(AylaResponse *response, NSDictionary *result))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    //reset retries
    AylaSetup.newDeviceToServiceConnectionRetries = 0;
    AylaSetup.newDeviceToServiceNoInternetConnectionRetries = 0;
    
    [AylaModule confirmNewDeviceToServiceConnection:successBlock failure:failureBlock];
}

+ (void)getNewDeviceWiFiStatus:
                /*success:*/(void (^)(AylaResponse *response, AylaWiFiStatus *wifiStatus))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    [AylaModule getNewDeviceWiFiStatus:^(AylaResponse *response, AylaWiFiStatus *wifiStatus) {
        successBlock(response, wifiStatus);
    } failure:^(AylaError *err) {
        failureBlock(err);
    }];
}


+ (void)exit
{
    if(inExit == true){
        saveToLog(@"%@, %@, %@:%@, %@", @"I", @"AylaSetup", @"entry", @"reEntry", @"exit()-------------------------");
        return;
    }
    
    inExit = true;
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"AylaSetup", @"entry", @"OK", @"exit()-------------------------");
    hostNewDeviceSsid = nil;
    hostNewDevicePassword = nil;
    hostNewDeviceSecurityType = AML_OPEN;
    lastMethodCompleted = AML_SETUP_TASK_EXIT;
    continueBlock = nil;
    securityType = AylaSetupSecurityTypeNone;
    [AylaSecurity cleanCurrentSession];
    [[[AylaApiClient sharedNewDeviceInstance] operationQueue] cancelAllOperations];
    if(newDevice)
        [newDevice lanModeDisable]; //Clean current buffered lan mode enabled device
}


+ (AylaDevice *)load
{
    NSArray *arr = [AylaCache get:AML_CACHE_SETUP];
    if(arr != nil && [arr count]!=0){
        return (AylaDevice *)[arr objectAtIndex:0];
    }
    else
        return nil;
}

+ (void)save:(AylaDevice *)newDevice
{
    if(newDevice == nil)
        [AylaCache save:AML_CACHE_SETUP withObject:nil];
    else
        [AylaCache save:AML_CACHE_SETUP withObject:[NSArray arrayWithObjects:newDevice, nil]];
}

+ (void)clear
{
    [AylaCache save:AML_CACHE_SETUP withObject:nil];
}

+ (BOOL)inExit
{
    return inExit;
}

+ (AylaModule *)newDevice
{
    return newDevice;
}
+ (void)setNewDevice:(AylaModule *)_newDevice
{
    newDevice = _newDevice;
}

+ (NSString *)hostNewDeviceSsid
{
    return hostNewDeviceSsid;
}
+ (void)setHostNewDeviceSsid:(NSString *)_hostNewDeviceSsid
{
    hostNewDeviceSsid = _hostNewDeviceSsid;
}

+ (NSString *)hostNewDevicePassword
{
    return hostNewDevicePassword;
}
+ (void)setHostNewDevicePassword:(NSString *)_hostNewDevicePassword
{
    hostNewDevicePassword = _hostNewDevicePassword;
}

+ (NSString *)hostNewDeviceSecurityType
{
    return hostNewDeviceSecurityType;
}
+ (void)setHostNewDeviceSecurityType:(NSString *)_hostNewDeviceSecurityType
{
    hostNewDeviceSecurityType = _hostNewDeviceSecurityType;
}
+ (NSString *)connectedMode
{
    return connectedMode;
}
+ (void)setConnectedMode:(NSString *)_connectedMode
{
    connectedMode  = _connectedMode;
}

+ (int)lastMethodCompleted
{
    return lastMethodCompleted;
}
+ (void)setLastMethodCompleted:(int)_lastMethodCompleted
{
    lastMethodCompleted = _lastMethodCompleted;
}
+ (NSString *)setupToken
{
    return setupToken;
}
+ (void)setSetupToken:(NSString *)_setupToken
{
    setupToken = _setupToken;
}
+ (NSString *)lanIp
{
    return lanIp;
}
+ (void)setLanIp:(NSString *)_lanIp
{
    lanIp  = _lanIp;
}
+ (int)newDeviceToServiceConnectionRetries
{
    return newDeviceToServiceConnectionRetries;
}
+ (void)setNewDeviceToServiceConnectionRetries:(int)_newDeviceToServiceConnectionRetries
{
    newDeviceToServiceConnectionRetries = _newDeviceToServiceConnectionRetries;
}
+ (int)newDeviceToServiceNoInternetConnectionRetries
{
    return newDeviceToServiceNoInternetConnectionRetries;
}
+ (void)setNewDeviceToServiceNoInternetConnectionRetries:(int)_newDeviceToServiceNoInternetConnectionRetries
{
    newDeviceToServiceNoInternetConnectionRetries = _newDeviceToServiceNoInternetConnectionRetries;
}

+ (dispatch_queue_t)setupQueue
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    static const char *label = "com.aylanetworks.setup";
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    });
    return queue;
}

+ (void) securityType:(AylaSetupSecurityType)type
{
    securityType = type;
}

+ (AylaSetupSecurityType) securityType
{
    return securityType;
}

+ (void) continueBlock:(void (^)(BOOL isEastablished))block
{
    continueBlock = block;
}
+ (void (^)(BOOL isEastablished)) continueBlock
{
    return continueBlock;
}

@end
