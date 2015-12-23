//
//  WaterReplenishmentMeter.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/21.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../Device/OznerDevice.h"
#import "../Bluetooth/BluetoothIO.h"
#import "WaterReplenishmentMeterStatus.h"

typedef void (^TestCallback)(NSNumber* value);
enum TestParts {Face=0,Hand=1,Eye=2,Other=4};
@interface TestData : NSObject
{
}
@property (strong) TestCallback callback;
@property enum TestParts testParts;
@end

@interface WaterReplenishmentMeter : OznerDevice
{
    NSTimer* updateTimer;
    NSDate* lastDataTime;
}
@property (strong,readonly) WaterReplenishmentMeterStatus* status;
-(void)Test:(enum TestParts) testParts Callback:(TestCallback)callback;

+(BOOL)isBindMode:(BluetoothIO*)io;
@end
