//
//  AylaConnectivityListener.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 6/25/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaConnectivityListener.h"
#import "TMReachability_Ayla.h"
#import "AylaReachabilitySupport.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaLogService.h"
#import "AylaHost.h"
#define AML_CONNECTIVITY_LISTENER_BEFORE_TOKEN_EXPIRY 60
@implementation AylaConnectivityListener {
    TMReachability_Ayla *logServiceReachbility;
}

- (id)init
{
    self = [super init];
    if(self){
        NSString *logServiceLink = nil;
        switch ([[AylaSystemUtils serviceType] integerValue]) {
                
            case AML_STAGING_SERVICE:
                logServiceLink = GBL_LOG_STAGING_URL;
                break;
            case AML_DEVELOPMENT_SERVICE:
                logServiceLink = GBL_LOG_DEVELOP_URL;
                break;
            default:
                logServiceLink = GBL_LOG_SERVICE_URL;
                
        }
        NSError *error;
        NSRegularExpression *linkRegex = [NSRegularExpression regularExpressionWithPattern:@"://[a-zA-Z0-9.-]{2,}/" options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *matches = [linkRegex matchesInString:logServiceLink options:0 range:NSMakeRange(0, [logServiceLink length])];
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        NSString *slashUrl = [logServiceLink substringWithRange:[match range]];
        NSString *url = [slashUrl substringWithRange:NSMakeRange(3, slashUrl.length-4)];
        
        logServiceReachbility = [TMReachability_Ayla reachabilityWithHostname:url];
    }
    return self;
}

- (void)startNotifier
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:kReachabilityChangedNotification_Ayla object:nil];
    [logServiceReachbility startNotifier];
}


- (void)networkChanged:(NSNotification *)notification
{
    
    // If it is talking to the new device, skip
    if( [AylaHost isNewDeviceConnected] ) {
        return;
    }
    NetworkStatus_Ayla hostStatus = [logServiceReachbility currentReachabilityStatus];
    if(hostStatus == ReachableViaWiFi_Ayla) {
    
        if( ![AylaHost isNewDeviceConnected] ) {
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [AylaReachability determineServiceReachabilityWithBlock:^(int reachable){
                    if(reachable == AML_REACHABILITY_REACHABLE){
                        if([AylaUser accessTokenSecondsToExpiry]>=AML_CONNECTIVITY_LISTENER_BEFORE_TOKEN_EXPIRY)
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                                [AylaLogService sendLogServiceMessage:nil withDelay:NO];
                            });
                    }
                }];
            });
        }
        else {
            [AylaReachability setConnectivity:AML_REACHABILITY_UNREACHABLE];
        }
    }
    else if(hostStatus == ReachableViaWWAN_Ayla) {
        [AylaLogService sendLogServiceMessage:nil withDelay:NO];
    }
    else{ // Not reachable
        [AylaReachability setConnectivity:AML_REACHABILITY_UNREACHABLE];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
