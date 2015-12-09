//
//  AirPurifier_MxChip.h
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AirPurifierStatus.h"
#import "AirPurifierSensor.h"
#import "AirPurifierInfo.h"
#import "../../Device/OznerDevice.h"
@interface AirPurifier_MxChip : OznerDevice
{
    NSMutableDictionary* propertys;
    NSTimer* updateTimer;
}
@property (strong,nonatomic)AirPurifierStatus* status;
@property (strong,nonatomic)AirPurifierSensor* sensor;
@property (strong,nonatomic)AirPurifierInfo* info;


@end
