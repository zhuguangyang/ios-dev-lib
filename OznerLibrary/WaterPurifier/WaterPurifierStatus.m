//
//  WaterPurifierStatus.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "WaterPurifierStatus.h"

@implementation WaterPurifierStatus
-(instancetype)init:(onWaterPurifierStatusSetHandler)cb
{
    if (self=[super init])
    {
        self->callback=cb;
    }
    return self;
}
-(NSString *)description
{
    return [NSString stringWithFormat:@"Power:%d Cool:%d Hot:%d Sterilization:%d",self.power,self.cool,self.hot,self.sterilization];
}
-(void)load:(BytePtr)bytes
{
    _hot = bytes[12] != 0;
    _cool = bytes[13] != 0;
    _power = bytes[14] != 0;
    _sterilization = bytes[15] != 0;
}
-(BOOL)toSet
{
    Byte bytes[4];
    bytes[0]=self.hot?1:0;
    bytes[1]=self.cool?1:0;
    bytes[2]=self.power?1:0;
    bytes[3]=self.sterilization?1:0;
    NSData* data=[NSData dataWithBytes:bytes length:4];
    return callback(data);
}
-(void)setPower:(BOOL)power
{
    _power=power;
    [self toSet];
}
-(void)setSterilization:(BOOL)sterilization
{
    _sterilization=sterilization;
    [self toSet];
}
-(void)setCool:(BOOL)cool
{
    _cool=cool;
    [self toSet];
}
-(void)setHot:(BOOL)hot
{
    _hot=hot;
    [self toSet];
}
@end
