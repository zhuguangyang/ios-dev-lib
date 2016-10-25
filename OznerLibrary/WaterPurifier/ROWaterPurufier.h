//
//  ROWaterPurufier.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 2016/10/24.
//  Copyright © 2016年 Ozner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../Device/OznerDevice.h"
#import "../Bluetooth/BluetoothIO.h"
#import "ROWaterSettingInfo.h"
#import "RO_WaterInfo.h"
#import "RO_FilterInfo.h"
@interface ROWaterPurufier : OznerDevice
{
    NSTimer* updateTimer;
    NSDate* lastDataTime;
    int requestCount;
}
@property (strong,readonly) ROWaterSettingInfo* settingInfo;
//水质信息
@property (strong,readonly) RO_WaterInfo* waterInfo;
//滤芯信息
@property (strong,readonly) RO_FilterInfo* filterInfo;

-(BOOL) reset;
+(BOOL)isBindMode:(BluetoothIO*)io;
@end
