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



-(instancetype)init:(NSString *)identifier Type:(NSString *)type Settings:(NSString *)json
{
    if (self=[super init:identifier Type:type Settings:json])
    {
        propertys=[[NSMutableDictionary alloc] init];
        _status=[[AirPurifierStatus alloc] init:propertys Callback:^BOOL(Byte propertyId, NSData *data) {
            return [self setProperty:propertyId Data:data];
        }];
    }
    
    return self;
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
            break;
        }
        default:
            break;
    }
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
}

@end
