//
//  WaterPurifier_Ayla.h
//  OznerLibraryDemo
//
//  Created by 赵兵 on 16/7/14.
//  Copyright © 2016年 Ozner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../Device/OznerDevice.h"
#import "AylaIO.h"
#import "WaterPurifierInfo.h"
#import "WaterPurifierSensor.h"
#import "WaterPurifierStatus.h"

@interface WaterPurifier_Ayla : OznerDevice
{
    
}
@property (strong,readonly,nonatomic) WaterPurifierInfo* info;
@property (readonly,nonatomic) bool isOffline;
@property (readonly,nonatomic) int TDS1;
@property (readonly,nonatomic) int TDS2;
/*!
 @property power
 @discussion 电源
 */
//@property (nonatomic,readonly) bool Power;
/*!
 @property cool
 @discussion 制冷
 */
//@property (nonatomic,readonly) bool Cool;
/*!
 @property hot
 @discussion 加热
 */
//@property (nonatomic,readonly) bool Hot;
/*!
 @property sterilization
 @discussion 杀菌
 */
//@property (nonatomic,readonly) bool Sterilization;
-(BOOL)getPower;
-(BOOL)getHot;
-(BOOL)getCool;
-(BOOL)getSterilization;
-(void)setPower:(BOOL)power Callback:(OperateCallback)cb;
-(void)setSterilization:(BOOL)sterilization Callback:(OperateCallback)cb;
-(void)setCool:(BOOL)cool Callback:(OperateCallback)cb;
-(void)setHot:(BOOL)hot Callback:(OperateCallback)cb;

//-(void)load:(BytePtr)bytes;
@end