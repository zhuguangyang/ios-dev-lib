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
#import "WaterPurifier_Ayla.h"
@implementation WaterPurifierManager

-(OznerDevice *)createDevice:(NSString *)identifier Type:(NSString *)type Settings:(NSString *)json
{
    if ([type isEqualToString:@"MXCHIP_HAOZE_Water"]) {
        WaterPurifier* device=[[WaterPurifier alloc] init:identifier Type:type Settings:json];
        [[OznerManager instance].ioManager.mxchip createMXChipIO:identifier Type:type];
        return device;
    } else if([type isEqualToString:@"AY001MAB1"]){
        WaterPurifier* waterPurifier = [[WaterPurifier_Ayla alloc] init:identifier Type:type Settings:json];
        return waterPurifier;
    }else{
        return nil;
    }
    
}
+(BOOL)isWaterPurifier:(NSString*)type
{
    return [type isEqualToString:@"MXCHIP_HAOZE_Water"] || [type isEqualToString:@"AY001MAB1"];
}

-(BOOL)isMyDevice:(NSString *)type
{
    return [WaterPurifierManager isWaterPurifier:type];
}

@end
