//
//  AirPurifier_MxChip.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "AirPurifier_MxChip.h"
#import "AirPurifierConsts.h"
#import "../../Helper/Helper.h"
#import "../../Device/OznerDevice.h"
#import "../../Device/OznerDevice.hpp"

@implementation AirPurifier_MxChip
#define Timeout 5


-(instancetype)init:(NSString *)identifier Type:(NSString *)type Settings:(NSString *)json
{
    if (self=[super init:identifier Type:type Settings:json])
    {
        propertys=[[NSMutableDictionary alloc] init];
        _status=[[MxChipAirPurifierStatus alloc] init:propertys Callback:^BOOL(Byte propertyId, NSData *data) {
            return [self setProperty:propertyId Data:data];
        }];
        _powerTimer=[[PowerTimer alloc] init];
        NSString* json=[self.settings get:@"powerTimer" Default:@""];
        [_powerTimer loadByJSON:json];
    }
    return self;
}
-(void)updateSettings
{
    //NSString* json=[self.settings get:@"powerTimer" Default:@""];
    NSData* data=[_powerTimer toBytes];
    [propertys setObject:data forKey:[NSNumber numberWithInt:PROPERTY_POWER_TIMER]];
    [self setProperty:PROPERTY_POWER_TIMER Data:data];
    [super updateSettings];
    
}
-(void)saveSettings
{
    NSString* json=[_powerTimer toJSON];
    [self.settings put:json Value:@"powerTimer"];
}

-(BOOL)reqesutProperty:(NSSet*)propertys
{
    if (!io) return false;
    if (!io.isReady) return false;
    
    int len=14 + [propertys count];
    Byte bytes[len];
    
    bytes[0] = (Byte) 0xfb;
    *((ushort*)bytes)=len;
    bytes[3] =  CMD_REQUEST_PROPERTY;
    
    NSData* mac=[Helper stringToHexData:[self.identifier stringByReplacingOccurrencesOfString:@":" withString:@""]];
    BytePtr tmp=(BytePtr)[mac bytes];
    bytes[4]=tmp[0];
    bytes[5]=tmp[1];
    bytes[6]=tmp[2];
    bytes[7]=tmp[3];
    bytes[8]=tmp[4];
    bytes[9]=tmp[5];
    bytes[10]=0;
    bytes[11]=0;
    bytes[12]=(Byte)[propertys count];
    int p=13;
    for (NSNumber* prop in [propertys allObjects])
    {
        bytes[p]=(Byte)[prop intValue];
        p++;
    }
    return [io send:[NSData dataWithBytes:bytes length:len]];
}
-(BOOL)setProperty:(Byte)propertyId Data:(NSData*)value
{
    if (!io) return false;
    if (!io.isReady) return false;
    
    int len=13 + (int)value.length;
    Byte bytes[len];
    
    bytes[0] = (Byte) 0xfb;
    *((ushort*)bytes)=len;
    bytes[3] =  CMD_SET_PROPERTY;
    
    NSData* mac=[Helper stringToHexData:[self.identifier stringByReplacingOccurrencesOfString:@":" withString:@""]];
    BytePtr tmp=(BytePtr)[mac bytes];
    bytes[4]=tmp[0];
    bytes[5]=tmp[1];
    bytes[6]=tmp[2];
    bytes[7]=tmp[3];
    bytes[8]=tmp[4];
    bytes[9]=tmp[5];
    bytes[10]=0;
    bytes[11]=0;
    bytes[12] = propertyId;
    memccpy(bytes+13, [value bytes], 0, value.length);
    return [io send:[NSData dataWithBytes:bytes length:len]];
}

-(void)DeviceIO:(BaseDeviceIO *)io recv:(NSData *)data
{
    if (!data) return;
    if (data.length<=0) return;
    BytePtr bytes=(BytePtr)[data bytes];
    if (bytes[0]!=0xFA) return;
    int len=*((ushort*)bytes+1);
    if (len<0) return;
    Byte cmd=bytes[3];
    switch (cmd) {
        case CMD_RECV_PROPERTY:
        {
            Byte count=bytes[12];
            int p=13;
            NSMutableDictionary* set=[[NSMutableDictionary alloc] init];
            for (int i=0;i<count;i++)
            {
                int property=bytes[p];
                p++;
                Byte size=bytes[p];
                p++;
                NSData* data=[NSData dataWithBytes:bytes+p length:size];
                p+=size;
                [set setObject:data forKey:[NSNumber numberWithInt:propertys]];
                
            }
            @synchronized(propertys) {
                for (NSNumber* property in [set allKeys])
                {
                    [propertys setObject:[set valueForKey:property] forKey:property];
                }
            }
            for (NSNumber* property in [set allKeys])
            {
                switch (property.intValue) {
                    case PROPERTY_POWER_TIMER:
                    case PROPERTY_POWER:
                    case PROPERTY_LIGHT:
                    case PROPERTY_LOCK:
                    case PROPERTY_SPEED:
                    {
                        [self doStatusUpdate];
                        break;
                    }
                        
                    case PROPERTY_FILTER:
                    case PROPERTY_PM25:
                    case PROPERTY_TEMPERATURE:
                    case PROPERTY_VOC:
                    case PROPERTY_HUMIDITY:
                    case PROPERTY_LIGHT_SENSOR:
                    {
                        [self doSensorUpdate];
                        break;
                    }
                }
            }
            [self set];
            break;
        }
        default:
            break;
    }
}
-(BOOL)setTime
{
    Byte bytes[4];
    NSDate* date=[NSDate dateWithTimeIntervalSinceNow:0];
    int time=(int)[date timeIntervalSince1970];
    *((int*)bytes)=time;
    if ([self setProperty:PROPERTY_TIME Data:[NSData dataWithBytes:bytes length:sizeof(bytes)]])
    {
        return [self wait:Timeout];
    }else
    {
        return false;
    }
}
-(BOOL)DeviceIOWellInit:(BaseDeviceIO *)io
{
    [self setTime];

    NSMutableSet* set=[[NSMutableSet alloc] init];
    [set addObject:[NSNumber numberWithInt:PROPERTY_FILTER]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_MODEL]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_DEVICE_TYPE]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_CONTROL_BOARD]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_MAIN_BOARD]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_VERSION]];
    [self reqesutProperty:set];
    [self wait:Timeout];
    return true;
}

-(void)DeviceIODidReadly:(BaseDeviceIO *)io
{
    [self auto_update];
    [self start_auto_update];
}
-(void)stop_auto_update
{
    if (self->updateTimer)
    {
        [updateTimer invalidate];
        updateTimer=nil;
    }
}
-(void)start_auto_update
{
    if (updateTimer)
        [self stop_auto_update];
    if (!updateTimer)
    {
        updateTimer=[NSTimer scheduledTimerWithTimeInterval:5 target:self
                                                   selector:@selector(auto_update)
                                                   userInfo:nil repeats:YES];
        [updateTimer fire];
    }
}

-(void)auto_update
{
    NSMutableSet* set=[[NSMutableSet alloc] init];
    [set addObject:[NSNumber numberWithInt:PROPERTY_PM25]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_LIGHT_SENSOR]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_TEMPERATURE]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_VOC]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_HUMIDITY]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_POWER]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_SPEED]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_LIGHT]];
    [set addObject:[NSNumber numberWithInt:PROPERTY_LOCK]];
    [self reqesutProperty:set];
}

@end
