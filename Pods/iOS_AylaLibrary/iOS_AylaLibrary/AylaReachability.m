//
//  AylaReachability.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/11/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaLanModeSupport.h"
#import "AylaDeviceSupport.h"
#import "AylaReachability.h"
#import "TMReachability_Ayla.h"
#import "AylaPingHelper.h"
#import "AylaDiscovery.h"
#import "AylaLogService.h"
#import "AylaHost.h"
#import "AylaDefines_Internal.h"
#import "AylaDeviceSupport.h"
#import "AylaHTTPOperation.h"
@implementation AylaReachability

static int connectivity = AML_REACHABILITY_UNKNOWN;
static int device = AML_REACHABILITY_UNREACHABLE;

static int isDeviceReachable = AML_REACHABILITY_UNKNOWN;
static int isServiceReachable = AML_REACHABILITY_UNKNOWN;

static bool isServiceReachabilityExpired = false;
static bool isDeviceReachabilityExpired = false;

static NSDate *lastUpdateTimeOfServiceReachability = nil;
static const int kAylaReachabilityValidTimeInterval = -3;

static void (^reachabilityHandler)(NSDictionary *) = NULL;

+ (void)register:(void (^)(NSDictionary *))rhandler
{
    reachabilityHandler = rhandler;
}

+ (BOOL)isDeviceReachabilityExpired
{
    return isDeviceReachabilityExpired;
}
+ (void)setIsDeviceReachabilityExpired:(BOOL)_isReachable
{
    isDeviceReachabilityExpired = _isReachable;
}

+ (BOOL)isServiceReachabilityExpired
{
    if(!lastUpdateTimeOfServiceReachability) return YES;
    return [lastUpdateTimeOfServiceReachability timeIntervalSinceNow] > kAylaReachabilityValidTimeInterval? NO: YES;
}
+ (void)setIsServiceReachabilityExpired:(BOOL)_isReachable
{
    isServiceReachabilityExpired = _isReachable;
}

+ (int)getDeviceReachability
{
    return AML_REACHABILITY_REACHABLE;
}
+ (void)setDeviceReachability:(int)reachable
{
    if (reachable != device){
        device = reachable;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(reachabilityHandler != nil && device != AML_REACHABILITY_UNKNOWN ){
                NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt:device], @"device", [NSNumber numberWithInt: connectivity], @"connectivity", nil];
                reachabilityHandler(dict);
            }
        });
        saveToLog(@"%@, %@, %@, %d, %@", @"I", @"Reachability", @"deviceReachability", device , @"setDeviceReachability");
    }
}

+ (void)determineDeviceReachability:(AylaDevice *)device completionBlock:(void(^)(int reachability))completionBlock
{
    // if Lan Session is ON, skip reachability check
    if([device lanModeState] == UP) {
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        completionBlock(AML_REACHABILITY_REACHABLE);
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
        return;
    }

    NSString *dsn = device.dsn;
    if(!dsn) {
        saveToLog(@"%@, %@, %@, %@, %@", @"E", @"Reachability", @"dsn", @"NotFound", @"determineDeviceReachability");
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        completionBlock(AML_REACHABILITY_UNKNOWN);
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
        return;
    }
    
    [AylaDiscovery getDeviceIpAddressWithHostName:dsn timeout:AML_DEVICE_REACHABILITY_TIMEOUT andResultBlock:^(NSString *lanIp, NSString *deviceHostName) {
        if ([dsn isEqualToString:deviceHostName] &&
            lanIp != nil){
            isDeviceReachable = AML_REACHABILITY_REACHABLE;
        }
        else {
            isDeviceReachable = AML_REACHABILITY_UNREACHABLE;
        }
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        completionBlock(isDeviceReachable);
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
    }];

}

+ (int)getConnectivity
{
    return connectivity;
}

+ (void)setConnectivity:(int)reachable
{
    if(reachable == AML_REACHABILITY_REACHABLE)
        lastUpdateTimeOfServiceReachability = [NSDate date];
    
    if (reachable != connectivity){
        connectivity = reachable;

        dispatch_async(dispatch_get_main_queue(), ^{
            if(reachabilityHandler != nil && connectivity != AML_REACHABILITY_UNKNOWN ){
                NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithInt:device], @"device", [NSNumber numberWithInt: connectivity], @"connectivity", nil];
                reachabilityHandler(dict);
            }
        });
        saveToLog(@"%@, %@, %@, %d, %@", @"I", @"Reachability", @"serviceReachability", connectivity , @"setConnectivity");
    }
}

+ (int)getReachability
{
    if (connectivity >= 0) {
        return AML_REACHABILITY_REACHABLE;
    } else  {
        return AML_REACHABILITY_UNREACHABLE;
    }
}

+ (void)determineReachability
{
    [AylaReachability determineServiceReachabilityWithBlock:^(int reachable) { }];
}

+ (void)determineServiceReachabilityWithBlock:(void(^)(int))block
{    
    if(![AylaReachability isInternetReachable]){
        isServiceReachable = AML_REACHABILITY_UNREACHABLE;
        [AylaReachability setConnectivity:isServiceReachable];
        if(block)
            block(isServiceReachable);
        return;
    }
    
    if(![AylaReachability isServiceReachabilityExpired] &&
       connectivity == AML_REACHABILITY_REACHABLE) {
        block(connectivity);
        return;
    }
    
    NSString *wholeUrl = nil;
    NSString *hostUrl = nil ;
    isServiceReachable =  AML_REACHABILITY_UNKNOWN;
    
    wholeUrl = [[[AylaApiClient sharedDeviceServiceInstance] baseURL] absoluteString];
    hostUrl = [wholeUrl substringWithRange:NSMakeRange(8, [wholeUrl length]-8 -7)]; // 8 = "https://" 7 = "/apiv1/"
    int delaySeconds = [[AylaSystemUtils serviceReachableTimeout] intValue];
    if(delaySeconds == -1){ // User login locally
        [AylaReachability setConnectivity:AML_REACHABILITY_UNREACHABLE];
        if(block != nil)
            block(AML_REACHABILITY_UNREACHABLE);
        return;
    }
    
    if([AylaHost isNewDeviceConnected]) {
        isServiceReachable = AML_REACHABILITY_UNREACHABLE;
        [AylaReachability setConnectivity:isServiceReachable];
        if(block)
            block(isServiceReachable);
        return;    
    }
    
    
    if([[AylaSystemUtils slowConnection] boolValue]){
        
        [self performSelector:@selector(dnsCheckEnd:) withObject:block afterDelay:delaySeconds]; // This timeout is what retains the ping helper
        connectivity = AML_REACHABILITY_UNKNOWN;
        
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            struct hostent *host = gethostbyname([hostUrl cStringUsingEncoding:NSUTF8StringEncoding]);
            
            if(host != nil){ // Suppose time cost of DNS query is shorter than delaySeconds
                [AylaReachability setConnectivity:AML_REACHABILITY_REACHABLE];
                if(block!=nil)
                    dispatch_async(dispatch_get_main_queue(), ^{
                       block(AML_REACHABILITY_REACHABLE);
                    });
            };
        });
    }
    else{
        // Send a HTTP request to service
        NSMutableURLRequest *request = [[AylaApiClient sharedDeviceServiceInstance] requestWithMethod:@"PUT" path:@"" parameters:nil];
        [request setTimeoutInterval:delaySeconds];
        AylaHTTPOperation *operation = [[AylaApiClient sharedDeviceServiceInstance]
                                        operationWithRequest:request success:^(AylaHTTPOperation *operation, id responseObject) {
                                            isServiceReachable = AML_REACHABILITY_REACHABLE;
                                            [AylaReachability setConnectivity:isServiceReachable];
                                            if(block)
                                                block(AML_REACHABILITY_REACHABLE);
                                        } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                            saveToLog(@"%@, %@, %@:%ld, %@", @"I", @"Reachability", @"fromServer", (long)error.nativeErrorInfo.code, @"determineServiceReachabilityWithBlock");
                                            if(operation.response.httpStatusCode != 0){ // Get status code
                                                isServiceReachable = AML_REACHABILITY_REACHABLE;
                                                [AylaReachability setConnectivity:isServiceReachable];
                                                if(block)
                                                    block(AML_REACHABILITY_REACHABLE);
                                            }
                                            else{
                                                isServiceReachable = AML_REACHABILITY_UNREACHABLE;
                                                [AylaReachability setConnectivity:isServiceReachable];
                                                if(block)
                                                    block(AML_REACHABILITY_UNREACHABLE);
                                            }

                                        }];
        [operation start];
    }
}

+ (void)dnsCheckEnd:(void(^)(int))block
{    
    if(connectivity == AML_REACHABILITY_UNKNOWN || connectivity == AML_REACHABILITY_UNREACHABLE){
        [AylaReachability setConnectivity:AML_REACHABILITY_UNREACHABLE];
        block(AML_REACHABILITY_UNREACHABLE);
    }
}

+ (void)determineDeviceReachabilityWithBlock:(void(^)(int))block
{
    if(![AylaReachability isWiFiEnabled]) {
        isDeviceReachable = AML_REACHABILITY_UNREACHABLE;
        [AylaReachability setDeviceReachability:isDeviceReachable];
        if(block) {
            AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
            block(isDeviceReachable);
            AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
        }
        return;
    }
    
    if(![AylaLanMode isEnabled]) {
        if(block) {
            AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
            block(AML_REACHABILITY_LAN_MODE_DISABLED);
            AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
        }
        return;
    }
    
    if(block) {
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        block(AML_REACHABILITY_REACHABLE);
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
    }
}

+ (void)getDeviceIpAddressWithHostName: (NSString *)deviceHostName
                        resultBlock:(void(^)(NSString *, NSString*))resultBlock
{
    [AylaDiscovery getDeviceIpAddressWithHostName:deviceHostName timeout:AML_LAN_MODE_MDNS_DISCOVERY_TIMEOUT andResultBlock:^(NSString *ip, NSString *devHostName) {
        if(ip==nil)
            [AylaReachability setDeviceReachability:AML_REACHABILITY_UNREACHABLE];
        else
            [AylaReachability setDeviceReachability:AML_REACHABILITY_REACHABLE];
        resultBlock(ip,devHostName);
    }];
}


+ (BOOL)isInternetReachable
{  
    static TMReachability_Ayla *reach;
    reach = [TMReachability_Ayla reachabilityForInternetConnection];
    NetworkStatus_Ayla networkStatus = [reach currentReachabilityStatus];
    return !(networkStatus == NotReachable_Ayla);
}

+ (BOOL)isWiFiEnabled
{
    TMReachability_Ayla *reach = [TMReachability_Ayla reachabilityForLocalWiFi];
    BOOL reachable = [reach isReachableViaWiFi];
    return reachable;
}

@end
