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
@implementation WaterPurifierManager

-(OznerDevice *)createDevice:(NSString *)identifier Type:(NSString *)type Settings:(NSString *)json
{
    WaterPurifier* device=[[WaterPurifier alloc] init:identifier Type:type Settings:json];
    [[OznerManager instance].ioManager.mxchip createMXChipIO:identifier Type:type];
    return device;
}

@end
