//
//  AirPurifierStatus.h
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MxChipAirPurifierFilterStatus.h"
typedef BOOL (^updateStatusHandler)(Byte propertyId,NSData* data);
@interface MxChipAirPurifierStatus : NSObject
{
    NSDictionary* propertys;
    updateStatusHandler callback;
}
-(instancetype)init:(NSDictionary*)propertys Callback:(updateStatusHandler)cb;

@property (getter=getPower,setter=setPower:) BOOL power;
@property (getter=getLock,setter=setLock:) BOOL lock;
@property (getter=getSpeed,setter=setSpeed:) Byte speed;
@property (getter=getLight,setter=setLight:) Byte light;
/*!
 @function filterStatus
 @discussion 滤芯状态
 */
-(MxChipAirPurifierFilterStatus*) filterStatus;
-(BOOL)resetFilterStatus;
@end
