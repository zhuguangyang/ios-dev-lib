//
//  RO_WaterInfo.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 2016/10/25.
//  Copyright © 2016年 Ozner. All rights reserved.
//

#import "RO_WaterInfo.h"

@implementation RO_WaterInfo
-(instancetype)init
{
    if (self=[super init])
    {
        [self reset];
    }
    return self;
}
-(void)reset
{
    _TDS1=0;
    _TDS2=0;
    _TDS1_RAW=0;
    _TDS2_RAW=0;
    _TDS_Temperature=0;
    _FilterVolume=0;
}
-(void)load:(NSData*)data
{
    short* bytes=(short*)[data bytes];
    _TDS1=*((unsigned short*)&bytes[0]);
    _TDS2=*((unsigned short*)&bytes[2]);
    
    _TDS1_RAW=*((unsigned short*)&bytes[4]);
    _TDS2_RAW=*((unsigned short*)&bytes[6]);
    
    _TDS_Temperature=*((unsigned short*)&bytes[8]);
    _FilterVolume=*((unsigned short*)&bytes[10]);
    
}
-(NSString *)description
{
    return [NSString stringWithFormat:@"TDS1:%d(%d) TDS2:%d(%d) 温度:%d 过滤量:%d",
            _TDS1,_TDS1_RAW,
            _TDS2,_TDS2_RAW,
            _TDS_Temperature,
            _FilterVolume];
}
@end
