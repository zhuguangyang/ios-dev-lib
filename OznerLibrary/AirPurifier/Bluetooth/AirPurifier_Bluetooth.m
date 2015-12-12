//
//  AirPurifier_Bluetooth.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/10.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "AirPurifier_Bluetooth.h"
#import "../../Device/OznerDevice.hpp"
@implementation AirPurifier_Bluetooth
#define opCode_UpdateTime  0x40
#define opCode_Request  0x20
#define opCode_Power  0x10
#define opCode_StatusResp  0x21
#define opCode_SensorResp  0x22
#define opCode_A2DPResp  0x24
#define opCode_FilterResp  0x23
#define opCode_ResetFilter  0x41
#define opCode_A2DPPair 0x42
#define type_status  1
#define type_sensor  2
#define type_filter  3
#define type_a2dp  4

-(instancetype)init:(NSString *)identifier Type:(NSString *)type Settings:(NSString *)json
{
    if (self=[super init])
    {
        _sensor=[[BluetoothAirPurifierSensor alloc] init];
        [_sensor reset];
    }
    return self;
}
-(void)DeviceIODidDisconnected:(BaseDeviceIO *)io
{
    [_sensor reset];
}
-(void)DeviceIO:(BaseDeviceIO *)io recv:(NSData *)data
{
    if (data==nil) return;
    if (data.length<1) return;
    BytePtr bytes=(BytePtr)[data bytes];
    Byte opCode=bytes[0];
    switch (opCode) {
        case opCode_StatusResp:
            break;
        case opCode_SensorResp:
            break;
        case opCode_ResetFilter:
            break;
        case opCode_A2DPResp:
            break;
        default:
            break;
    }
}
@end
