//
//  FilterStatus.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "MxChipAirPurifierFilterStatus.h"

@implementation MxChipAirPurifierFilterStatus

-(instancetype)init
{
    if (self=[super init])
    {
        _lastTime=[NSDate dateWithTimeIntervalSinceNow:0];
        _workTime=0;
        _stopTime=[NSDate dateWithTimeIntervalSinceNow:0];
        _maxWorkTime=60 * 1000;
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setYear:[components year]+1];
        _stopTime=[cal dateByAddingComponents:components toDate:_lastTime options:0];
    }
    return self;
}
-(instancetype)init:(NSData*)data
{
    if ((data==nil) || (data.length<16)) return nil;
    if (self=[super init])
    {
        BytePtr bytes=(BytePtr)[data bytes];
        self->_lastTime=[NSDate dateWithTimeIntervalSince1970:*((UInt32*)bytes)];
        self->_workTime=*((UInt32*)(bytes+4));
        self->_stopTime=[NSDate dateWithTimeIntervalSince1970:*((UInt32*)(bytes+8))];
        self->_maxWorkTime=*((UInt32*)(bytes+12));
    }
    return self;
}

-(NSData *)toBytes
{
    Byte bytes[16];
    *((UInt32*)bytes)=(int)[_lastTime timeIntervalSince1970];
    *((UInt32*)bytes+4)=_workTime;
    *((UInt32*)bytes+8)=(int)[_stopTime timeIntervalSince1970];
    *((UInt32*)bytes+12)=_maxWorkTime;
    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}
@end
