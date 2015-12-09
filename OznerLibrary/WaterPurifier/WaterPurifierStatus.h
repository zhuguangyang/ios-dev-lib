//
//  WaterPurifierStatus.h
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef BOOL (^onWaterPurifierStatusSetHandler) (NSData* data);
@interface WaterPurifierStatus : NSObject
{
    onWaterPurifierStatusSetHandler callback;
}
-(instancetype)init:(onWaterPurifierStatusSetHandler)cb;

/*!
 @property power
 @discussion 电源
 */
@property (nonatomic) BOOL power;
/*!
 @property cool
 @discussion 制冷
 */
@property (nonatomic) BOOL cool;
/*!
 @property hot
 @discussion 加热
 */
@property (nonatomic) BOOL hot;
/*!
 @property sterilization
 @discussion 杀菌
 */
@property (nonatomic) BOOL sterilization;
-(void)load:(BytePtr)bytes;

@end
