//
//  AylaNetworks.m
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 6/27/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"

@implementation AylaNetworks
+(BOOL) initWithParams:(NSDictionary *)params
{
    BOOL re = [AylaSystemUtils loadSavedSettings] == SUCCESS? YES: NO;

    // Save AML version
    AylaLogI(@"AML", 0, @"Using Library Ver. %@", amlVersion);

    if(params) {
        if([params objectForKey:AML_DEVICE_SSID_REG_EXP])
            deviceSsidRegex = [[params objectForKey:AML_DEVICE_SSID_REG_EXP] copy];
        if([params objectForKey:AML_APP_ID]){
            [AylaSystemUtils appId:[[params objectForKey:AML_APP_ID] copy]];
            [AylaSystemUtils serviceLocationWithAppId:[AylaSystemUtils appId]];
        }
        else {
            saveToLog(@"E, initWithParams, AML_APP_ID: can't be blank.");
            return NO;
        }
    }
    else {
        saveToLog(@"E, initWithParams, params: can't be empty.");
        return NO;
    }
    return re;
}
@end

// GLOBALS
NSString *gblAuthToken;     //Global Authentication Token
NSString *deviceSsidRegex;  //Device Ssid Regular Expression