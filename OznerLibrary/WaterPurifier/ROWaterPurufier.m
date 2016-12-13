//
//  ROWaterPurufier.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 2016/10/24.
//  Copyright © 2016年 Ozner. All rights reserved.
//

#import "ROWaterPurufier.h"
#import "../Device/OznerDevice.hpp"

@implementation ROWaterPurufier


#define opCode_request_info 0x20
#define opCode_reset 0xa0
#define opCode_respone_setting 0x21
#define opCode_respone_water 0x22
#define opCode_respone_filter 0x23
#define opCode_update_setting 0x40


-(instancetype)init:(NSString *)identifier Type:(NSString *)type Settings:(NSString *)json
{
    if (self=[super init:identifier Type:type Settings:json])
    {
        _filterInfo=[[RO_FilterInfo alloc] init];
        _settingInfo=[[ROWaterSettingInfo alloc] init];
        _waterInfo=[[RO_WaterInfo alloc] init];
    }
    return self;
}

-(void)DeviceIODidDisconnected:(BaseDeviceIO *)io
{
    [_filterInfo reset];
    [_settingInfo reset];
    [_filterInfo reset];
}



Byte calcSum(Byte* data,int size)
{
    Byte sum=0;
    for (int i=0;i<size;i++)
        sum+=data[i];
    return sum;
}
-(void)requestSettingInfo
{
    if (!io) return;
    NSMutableData* data=[[NSMutableData alloc] init];
    Byte bytes[3];
    bytes[0]=opCode_request_info;
    bytes[1]=1;
    bytes[2]=calcSum(bytes,2);
    [data appendBytes:bytes length:3];
    
    [io send:data];
}

-(void)requestWaterInfo
{
    if (!io) return;
    NSMutableData* data=[[NSMutableData alloc] init];
    Byte bytes[3];
    bytes[0]=opCode_request_info;
    bytes[1]=2;
    bytes[2]=calcSum(bytes,2);
    [data appendBytes:bytes length:3];
    
    [io send:data];
}

-(void)requestFilterInfo
{
    if (!io) return;
    NSMutableData* data=[[NSMutableData alloc] init];
    Byte bytes[3];
    bytes[0]=opCode_request_info;
    bytes[1]=3;
    bytes[2]=calcSum(bytes,2);
    [data appendBytes:bytes length:3];
    
    [io send:data];
}

/*!
 滤芯历史信息
 */
-(void)requestFilterHisInfo
{
    if (!io) return;
    NSMutableData* data=[[NSMutableData alloc] init];
    Byte bytes[3];
    bytes[0]=opCode_request_info;
    bytes[1]=3;
    bytes[2]=calcSum(bytes,2);
    [data appendBytes:bytes length:3];
    
    [io send:data];
}
-(BOOL)updateSetting:(int)interval Ozone_WorkTime:(int)worktime ResteFilter:(BOOL)reset
{
    if (!io) return false;
    NSMutableData* data=[[NSMutableData alloc] init];
    Byte bytes[11];
    bytes[0]=opCode_update_setting;
    NSDate* time=[NSDate dateWithTimeIntervalSinceNow:0];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dateComps = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:time];
    
    bytes[1]=[dateComps year]-2000;
    bytes[2]=[dateComps month];
    bytes[3]=[dateComps day];
    bytes[4]=[dateComps hour];
    bytes[5]=[dateComps minute];
    bytes[6]=[dateComps second];
    
    bytes[7]=interval;
    bytes[8]=worktime;
    bytes[9]=reset?1:0;
    bytes[10]=calcSum(bytes,9);
    [data appendBytes:bytes length:11];
    
    return [io send:data];
    
}

-(BOOL) reset
{
    if (!io) return false;
    NSMutableData* data=[[NSMutableData alloc] init];
    Byte bytes[3];
    bytes[0]=opCode_reset;
    bytes[1]=calcSum(bytes,1);
    [data appendBytes:bytes length:2];
    
    return [io send:data];
}


-(BOOL)DeviceIOWellInit:(BaseDeviceIO *)io
{
    return true;
}
-(NSString *)description
{
    return [NSString stringWithFormat:@"%@\n%@\n%@",[_settingInfo description],
            [_waterInfo description],[_filterInfo description]];
    //return [NSString stringWithFormat:@"status:%@",[_status description]];
}

-(void)DeviceIO:(BaseDeviceIO *)io recv:(NSData *)data
{
    if (data==nil) return;
    if (data.length<1) return;
    BytePtr bytes=(BytePtr)[data bytes];
    Byte opCode=bytes[0];
    lastDataTime=[NSDate dateWithTimeIntervalSinceNow:0];
    switch (opCode) {
        case opCode_respone_setting:
            [_settingInfo load:data];
            [self doSensorUpdate];
            //settingInfo.fromBytes(data);
            break;
        case opCode_respone_water:
            [_waterInfo load:data];
            [self doSensorUpdate];
            //waterInfo.fromBytes(data);
            break;
        case opCode_respone_filter:
            [_filterInfo load:data];
            [self doSensorUpdate];
            
            //filterInfo.fromBytes(data);
            break;
    }
}


-(void)DeviceIODidReadly:(BaseDeviceIO *)io
{
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
        updateTimer=[NSTimer scheduledTimerWithTimeInterval:3 target:self
                                                   selector:@selector(auto_update)
                                                   userInfo:nil repeats:YES];
        [updateTimer fire];
    }
}


-(void)auto_update
{
    if ((requestCount%2)==0)
    {
        [self requestFilterInfo];
    }else
        [self requestWaterInfo];
    requestCount++;
}

//重置滤芯时间
-(BOOL) resetFilter
{
    if (_settingInfo.Ozone_Interval<=0) return false;
    if (_settingInfo.Ozone_WorkTime<=0) return false;
    
    return [self updateSetting:_settingInfo.Ozone_Interval Ozone_WorkTime:_settingInfo.Ozone_WorkTime ResteFilter:true];
    
}
//返回是否允许滤芯重置
-(BOOL) isEnableFilterReset
{
    return true;
}

+(BOOL)isBindMode:(BluetoothIO*)io
{
    return true;
}
@end
