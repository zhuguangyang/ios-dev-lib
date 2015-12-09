//
//  AirPurifierSensor.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "AirPurifierSensor.h"
#import "AirPurifierConsts.h"
@implementation AirPurifierSensor
-(instancetype)init:(NSDictionary *)propertys
{
    if (self=[super init])
    {
        self->propertys=propertys;
    }
    return self;
}
-(BOOL)getShort:(int)propertyId
{
    @synchronized(propertys) {
        NSData* data=[propertys objectForKey:[NSNumber numberWithInt:propertyId]];
        if (data)
        {
            if (data.length>0)
            {
                return *((ushort*)[data bytes])==1;
            }else
                return AIR_PURIFIER_ERROR;
        }else
            return AIR_PURIFIER_ERROR;
    }
}
-(int)getLight
{
    return [self getShort:PROPERTY_LIGHT];
}
-(int)getTemperature
{
    return [self getShort:PROPERTY_TEMPERATURE];
}
-(int)getVOC
{
    return [self getShort:PROPERTY_VOC];
}
-(int)getHumidity
{
    return [self getShort:PROPERTY_HUMIDITY];
}
-(int)getPM25
{
    return [self getShort:PROPERTY_PM25];
}

@end
