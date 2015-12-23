//
//  WaterReplenishmentMeterStatus.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/21.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "WaterReplenishmentMeterStatus.h"

@implementation WaterReplenishmentMeterStatus

-(instancetype)init
{
    if (self=[super init])
    {
        [self reset];
    }
    return self;
}

-(void)load:(NSData *)data
{
    BytePtr bytes=(BytePtr)[data bytes];
    _power=bytes[1];
    _battery=bytes[2];
}

-(void)reset
{
    _power=false;
}

@end
