//
//  AylaIOManager.m
//  OznerLibraryDemo
//
//  Created by 赵兵 on 16/7/13.
//  Copyright © 2016年 Ozner. All rights reserved.
//

#import "AylaIOManager.h"
#import <AylaNetworks.h>
#import "Helper.h"
#import "IOManager.hpp"
#import "OznerManager.h"

@implementation AylaIOManager
NSString* gblAmlDeviceSsidRegex = @"^OZNER_WATER-[0-9A-Fa-f]{12}";

-(NSString*) lanIpServiceBaseURL:(NSString*) lanIp {
    NSString* url = [NSString stringWithFormat:@"http://%@/",lanIp];//String.format("http://%s/", lanIp);
    return url;
}
-(instancetype)init
{
    if (self=[super init])
    {
        NSDictionary *dic = @{AML_DEVICE_SSID_REG_EXP:gblAmlDeviceSsidRegex,AML_APP_ID:@"a_ozner_water_mobile-cn-id"};//"super app"
        listenDeviceList=[[NSMutableDictionary alloc] init];
        [AylaNetworks initWithParams:dic];
        
        [AylaSystemUtils serviceType:[NSNumber numberWithInt:AML_DEVELOPMENT_SERVICE]];//AML_STAGING_SERVICE//AML_DEVELOPMENT_SERVICE
        [AylaSystemUtils serviceLocationWithCountryCode:@"CN"];
        [AylaSystemUtils loggingLevel:1 << 2];
        [AylaSystemUtils slowConnection:[NSNumber numberWithInt:0]];
        [AylaSystemUtils saveCurrentSettings];
        //[AylaLanMode enable];
    }
    return self;
}
-(void) removeDevice:(NSString*) identifier {
    AylaDevice* dev=(AylaDevice*)[listenDeviceList objectForKey:identifier];
    if (dev==nil) {
        return;
    }
    [dev unregisterDevice:nil success:^(AylaResponse *response) {
        NSLog(@"Ayla unregisterDevice complete%@",response);
    } failure:^(AylaError *err) {
        NSLog(@"Ayla unregisterDevice Error:%@",err);
    }];
}

-(BOOL) isAylaSSID:(NSString*) ssid {
    
    NSPredicate *ssidPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", gblAmlDeviceSsidRegex];
    return [ssidPre evaluateWithObject:ssid];
    
}
-(void) Start:(NSString*) user Token:(NSString*)Token {
    
    [AylaUser ssoLogin:user password:@"" token:Token appId:@"a_ozner_water_mobile-cn-id" appSecret:@"a_ozner_water_mobile-cn-7331816" success:^(AylaResponse *response, AylaUser *user) {
        
        NSLog(@"%@,%@,%@",response,user,AylaUser.currentUser.accessToken);
        NSLog(@"%@,%@",response,user);
        
        [AylaDevice getDevices:nil success:^(AylaResponse *response, NSArray *devices) {
            for (int i=0; i<devices.count; i++) {
                AylaDevice* device=(AylaDevice*)[devices objectAtIndex:i];
                NSLog(@"%@",device);
                AylaIO* io=[[[[OznerManager instance] ioManager] aylaIOManager] createAylaIO:device];
                
                OznerDevice* ioDevice=[[OznerManager instance] getDeviceByIO:io];
                [[OznerManager instance] save:ioDevice];
            }
            
            //NSLog(@"%@,%@",response,devices);
        } failure:^(AylaError *err) {
            NSLog(@"%@",err);
        }];
    } failure:^(AylaError *err) {
        NSLog(@"%@",err);
        //NSLog(@"%@",err);
    }];
}
-(AylaIO*) createAylaIO:(AylaDevice*)device
{
    AylaIO* io = [[AylaIO alloc] init:device];
    [listenDeviceList setObject:device forKey:io.identifier];
    [self doAvailable:io];
    return io;
}

@end
