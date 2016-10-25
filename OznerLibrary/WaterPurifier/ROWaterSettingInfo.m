//
//  ROWaterSettingInfo.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 2016/10/25.
//  Copyright © 2016年 Ozner. All rights reserved.
//

#import "ROWaterSettingInfo.h"

@implementation ROWaterSettingInfo
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
    _Ozone_Interval=0;
    _Ozone_WorkTime=0;
}
-(void)load:(NSData*)data
{
    Byte* bytes=(Byte*)[data bytes];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    
    _rtc=[formatter dateFromString:[NSString stringWithFormat:@"%d-%d-%d %d:%d:%d",
                                    bytes[0],bytes[1],bytes[2],
                                    bytes[3],bytes[4],bytes[5]]];
    
    _Ozone_WorkTime=bytes[7];
    _Ozone_Interval=bytes[6];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"臭氧工作时间:%d 间隔:%d",_Ozone_WorkTime,_Ozone_Interval];
}

@end
