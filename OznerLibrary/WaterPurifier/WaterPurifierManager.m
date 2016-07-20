//
//  WaterPurifierManager.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "WaterPurifierManager.h"
#import "../Device/BaseDeviceManager.hpp"
#import "WaterPurifier.h"
#import "OznerManager.h"
#import "Helper.h"
#import "WaterPurifier_Ayla.h"
#import <AylaNetWorks.h>
//#define WaterPurifier_Ayla_Type @"AY001MAB1"
@implementation WaterPurifierManager

-(OznerDevice *)createDevice:(NSString *)identifier Type:(NSString *)type Settings:(NSString *)json
{
    if ([type isEqualToString:@"MXCHIP_HAOZE_Water"]) {
        WaterPurifier* device=[[WaterPurifier alloc] init:identifier Type:type Settings:json];
        [[OznerManager instance].ioManager.mxchip createMXChipIO:identifier Type:type];
        return device;
    } else if([type isEqualToString:@"AY001MAB1"]){
        WaterPurifier_Ayla* waterPurifier = [[WaterPurifier_Ayla alloc] init:identifier Type:type Settings:json];
//        AylaDevice* tmpDev=[Helper getAylaDeviceFromLocal:identifier];
//        if (tmpDev==nil) {
//            return nil;
//        }
//        [[OznerManager instance].ioManager.aylaIOManager createAylaIO:tmpDev];
        return waterPurifier;
    }else{
        return nil;
    }
    
}
+(BOOL)isWaterPurifier:(NSString*)type
{
    return [type isEqualToString:@"MXCHIP_HAOZE_Water"] || [type isEqualToString:@"AY001MAB1"];
}
+(BOOL)isWaterPurifier_Ayla:(NSString*)type
{
    return [type isEqualToString:@"AY001MAB1"];
}

-(BOOL)isMyDevice:(NSString *)type
{
    return [WaterPurifierManager isWaterPurifier:type];
}

@end
