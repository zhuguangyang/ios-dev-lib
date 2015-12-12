//
//  AirPurifierManager.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/10.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "AirPurifierManager.h"
#import "../OznerManager.h"
#import "MXChip/AirPurifier_MxChip.h"

@implementation AirPurifierManager
+(BOOL)isMXChipAirPurifier:(NSString*)type
{
    return [type isEqualToString:@"FOG_HAOZE_AIR"];
    
}
+(BOOL)isBluetoothAirPurifier:(NSString*)type
{
    return [type isEqualToString:@"FLT001"];
}
-(BOOL)isMyDevice:(NSString *)type
{
    return [AirPurifierManager isBluetoothAirPurifier:type] || [AirPurifierManager isMXChipAirPurifier:type];
}
-(OznerDevice *)createDevice:(NSString *)identifier Type:(NSString *)type Settings:(NSString *)json
{
    if ([self isMyDevice:type])
    {
        if ([AirPurifierManager isBluetoothAirPurifier:type])
        {
            
        }
        if ([AirPurifierManager isMXChipAirPurifier:type])
        {
            OznerDevice* device= [[AirPurifier_MxChip alloc]init:identifier Type:type Settings:json];
            [[OznerManager instance].ioManager.mxchip createMXChipIO:identifier Type:type];
            return device;
        }
    }
    return nil;
}
@end
