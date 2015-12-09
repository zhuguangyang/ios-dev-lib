//
//  WaterPurifierSensor.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "WaterPurifierSensor.h"

@implementation WaterPurifierSensor
-(instancetype)init
{
    if (self=[super init])
    {
        _TDS1=WATER_PURIFIER_SENSOR_ERROR;
        _TDS2=WATER_PURIFIER_SENSOR_ERROR;
    }
    return self;
}

-(void)load:(BytePtr)bytes
{
    _TDS1 = *((short*) bytes+16);
    _TDS2 = *((short*) bytes+18);
}
@end
