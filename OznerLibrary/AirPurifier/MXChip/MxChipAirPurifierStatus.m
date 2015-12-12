//
//  AirPurifierStatus.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "MxChipAirPurifierStatus.h"
#import "AirPurifierConsts.h"
@implementation MxChipAirPurifierStatus

-(instancetype)init:(NSDictionary*)propertys Callback:(updateStatusHandler)cb;
{
    if (self=[super init])
    {
        self->callback=cb;
        self->propertys=propertys;
    }
    return self;
}
-(BOOL)getBool:(int)propertyId
{
    @synchronized(propertys) {
        NSData* data=[propertys objectForKey:[NSNumber numberWithInt:propertyId]];
        if (data)
        {
            if (data.length>0)
            {
                return *((BytePtr)[data bytes])==1;
            }else
                return false;
        }else
            return false;
    }
}

-(Byte)getByte:(int)propertyId
{
    @synchronized(propertys) {
        NSData* data=[propertys objectForKey:[NSNumber numberWithInt:propertyId]];
        if (data)
        {
            if (data.length>0)
            {
                return *((BytePtr)[data bytes]);
            }else
                return 0;
        }else
            return 0;
    }
}

-(BOOL)resetFilterStatus
{
    MxChipAirPurifierFilterStatus* status=[[MxChipAirPurifierFilterStatus alloc] init];
    return callback(PROPERTY_FILTER,[status toBytes]);
}

-(MxChipAirPurifierFilterStatus *)filterStatus
{
    @synchronized(propertys) {
        NSData* data=[propertys objectForKey:[NSNumber numberWithInt:PROPERTY_FILTER]];
        if (data)
        {
            if (data.length>0)
            {
                return [[MxChipAirPurifierFilterStatus alloc] init:data];
                
            }else
                return nil;
        }else
            return nil;
    }
}


-(void)setPower:(BOOL)power
{
    Byte data[1]={power?1:0};
    callback(PROPERTY_POWER,[NSData dataWithBytes:data length:sizeof(data)]);
}

-(BOOL)getPower
{
    return [self getBool:PROPERTY_POWER];
}

-(BOOL)getLock
{
    return [self getBool:PROPERTY_LOCK];
}
-(void)setLock:(BOOL)lock
{
    Byte data[1]={lock?1:0};
    callback(PROPERTY_LOCK,[NSData dataWithBytes:data length:sizeof(data)]);
}
-(Byte)getLight
{
    return [self getByte:PROPERTY_LIGHT];
}
-(void)setLight:(Byte)light
{
    Byte data[1]={light};
    callback(PROPERTY_LIGHT,[NSData dataWithBytes:data length:sizeof(data)]);
}
-(Byte)getSpeed
{
    return [self getByte:PROPERTY_SPEED];
}
-(void)setSpeed:(Byte)speed
{
    Byte data[1]={speed};
    callback(PROPERTY_SPEED,[NSData dataWithBytes:data length:sizeof(data)]);
}

@end
