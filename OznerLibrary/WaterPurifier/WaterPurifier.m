//
//  WaterPurifier.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "WaterPurifier.h"
#import "../Device/OznerDevice.hpp"
#import "../Helper/Helper.h"

@implementation WaterPurifier

#define GroupCode_DeviceToApp 0xFB
#define GroupCode_AppToDevice 0xFA
#define GroupCode_DevceToServer 0xFC

#define Opcode_RequestStatus  0x01
#define Opcode_RespondStatus  0x01
#define Opcode_ChangeStatus  0x02
#define Opcode_DeviceInfo  0x03

#define SecureCode @"16a21bd6"

-(instancetype)init:(NSString *)identifier Type:(NSString *)type Settings:(NSString *)json
{
    if (self=[super init:identifier Type:type Settings:json])
    {
        self->_info=[[WaterPurifierInfo alloc] init];
        self->_status=[[WaterPurifierStatus alloc] init:^BOOL(NSData *data) {
            return [self setStatus:data];
        }];
        self->_sensor=[[WaterPurifierSensor alloc] init];
    }
    return self;
}
-(BOOL)setStatus:(NSData*)data
{
    BOOL ret=[io send:[self MakeWoodyBytes:GroupCode_AppToDevice Opcode:Opcode_ChangeStatus Data:data]];
    [self reqeusetStatsus];
    return ret;
}

-(void)doSetDeviceIO:(BaseDeviceIO *)oldio NewIO:(BaseDeviceIO *)newio
{
    MXChipIO* io=(MXChipIO*)newio;
    [io setSecureCode:SecureCode];
}

-(NSString *)getDefaultName
{
    return @"Water Purifier";
}

-(NSData*) MakeWoodyBytes:(Byte)group Opcode:(Byte)opcode Data:(NSData*)payload
{
    int len = 10 + (payload == nil ? 3 : (int)payload.length + 3);
    Byte bytes[len];
    bytes[0] = group;
    *((short*)(bytes+1))=len;
    bytes[3]=opcode;
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
    if (payload)
    {
        memccpy(bytes+12, [payload bytes], 0, payload.length);
    }
    bytes[len-1]=[Helper Crc8:bytes inLen:len-1];
    return [NSData dataWithBytes:bytes length:len];
}

-(void)DeviceIO:(BaseDeviceIO *)io recv:(NSData *)data
{
    if (data==nil) return;
    BytePtr bytes=(BytePtr)[data bytes];
    if (data.length > 10) {
        Byte group = bytes[0];
        Byte opCode = bytes[3];
        switch (group) {
            case GroupCode_DeviceToApp:
                switch (opCode)
            {
                case Opcode_RespondStatus:
                    [_status load:bytes];
                    [_sensor load:bytes];
                    [self doSensorUpdate];
                    [self doStatusUpdate];
                    break;
                case Opcode_DeviceInfo:
                    [_info load:bytes];
                    [self set];
                    break;
            }
            break;
        }
        
    }
}
-(BOOL)reqeusetStatsus
{
    if (io)
    {
        return [io send:[self MakeWoodyBytes:GroupCode_AppToDevice Opcode:Opcode_RequestStatus Data:nil]];
    }else
        return false;
}

-(BOOL)DeviceIOWellInit:(BaseDeviceIO *)io
{
    if ([io send:[self MakeWoodyBytes:GroupCode_AppToDevice Opcode:Opcode_RequestStatus Data:nil]])
    {
        [self wait:5];
    }
    return true;
}


-(void)DeviceIODidReadly:(BaseDeviceIO *)io
{
    [self reqeusetStatsus];
    [self start_auto_update];
}

-(void)DeviceIODidConnected:(BaseDeviceIO *)io
{
    [self stop_auto_update];
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
    [self reqeusetStatsus];
}

@end

