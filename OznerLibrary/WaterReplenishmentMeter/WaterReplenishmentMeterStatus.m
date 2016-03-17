//
//  WaterReplenishmentMeterStatus.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/21.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "WaterReplenishmentMeterStatus.h"

@implementation WaterReplenishmentMeterStatus


static double testValueTable[][8]=
{
    {8, 200, 0, 0, 0, 0, 0, 0},
    {200, 250, 0.082, 16.4, 20.5, 0.036, 7.2, 9.0},
    {250, 300, 0.081, 20.3, 24.3, 0.0355, 8.9, 10.7},
    {300, 350, 0.08, 24.0, 28.0, 0.035, 10.5, 12.3},
    {350, 380, 0.079, 27.7, 30.0, 0.0345, 12.1, 13.1},
    {380, 450, 0.079, 30.0, 35.6, 0.034, 12.9, 15.3},
    {450, 500, 0.078, 35.1, 39.0, 0.0335, 15.1, 16.8},
    {500, 550, 0.077, 38.5, 42.4, 0.033, 16.5, 18.2},
    {550, 600, 0.0765, 42.1, 45.9, 0.0325, 17.9, 19.5},
    {600, 650, 0.076, 45.6, 49.4, 0.032, 19.2, 20.8},
    {650, 700, 0.0755, 49.1, 52.9, 0.0315, 20.5, 22.1},
    {700, 750, 0.075, 52.5, 56.3, 0.031, 21.7, 23.3},
    {750, 800, 0.0745, 55.9, 59.6, 0.0305, 22.9, 24.4},
    {800, 850, 0.074, 59.2, 62.9, 0.03, 24.0, 25.5},
    {850, 900, 0.0735, 62.5, 66.2, 0.0295, 25.1, 26.6},
    {900, 1023, 0.073, 65.7, 74.7, 0.029, 26.1, 29.7},
};

-(instancetype)init
{
    if (self=[super init])
    {
        [self reset];
    }
    return self;
}
-(void)startTest
{
    _testing=true;
    _moisture=0;
    _oil=0;
}
-(void)loadTest:(int)adc
{
    for (int i=0;i<sizeof(testValueTable);i++)
    {
        if ((adc>=testValueTable[i][0]) && (adc<=testValueTable[i][1]))
        {
            _moisture=testValueTable[i][1]-testValueTable[i][0]*testValueTable[i][2]+testValueTable[i][3];
            _oil=testValueTable[i][1]-testValueTable[i][0]*testValueTable[i][5]+testValueTable[i][6];
            break;
        }
    }
    _testing=false;
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
- (NSString *)description
{
    return [NSString stringWithFormat:@"Power:%d Battery:%d moisture:%f oil:%f",_power,_battery,_moisture,_oil];
}
@end
