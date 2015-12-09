//
//  TapRecord.m
//  OznerBluetooth
//
//  Created by zhiyongxu on 15/3/27.
//  Copyright (c) 2015年 zhiyongxu. All rights reserved.
//

#import "CupRecord.h"

@implementation CupRecord
-(id)init
{
    if (self=[super init])
    {
        _Time=[NSDate dateWithTimeIntervalSince1970:0];
        _Vol=0;
        _TDS_200=0;
        _TDS_50=0;
        _TDS_50_200=0;
        _Temp_25=0;
        _Temp_25_65=0;
        _Temp_65=0;
        _Temp_High=0;
        _TDS_High=0;
        _Count=0;
    }
    return self;
}
-(void)incTDS:(int)TDS
{
    if (TDS>200)
        _TDS_200++;
    else
        if (TDS<50)
            _TDS_50++;
        else
            _TDS_50_200++;
    if (TDS>_TDS_High)
        _TDS_High=TDS;
}

-(void)incTemp:(int)Temp
{
    if (Temp>50)
        _Temp_65++;
    else
        if (Temp<20)
            _Temp_25++;
        else
            _Temp_25_65++;
    if (Temp>_Temp_High)
        _Temp_High=Temp;
    _Count++;
}

-(id)initWithJSON:(NSDate *)time JSON:(NSString *)JSON
{
    if (self=[self init])
    {
        _Time=[NSDate dateWithTimeIntervalSince1970:[time timeIntervalSince1970]];
        NSData* data=[JSON dataUsingEncoding:NSUTF8StringEncoding];
        NSError* error;
        NSDictionary* object=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
        if (!error)
        {
            if ([object objectForKey:@"Volume"])
            {
                _Vol=[[object objectForKey:@"Volume"] intValue];
            }
            if ([object objectForKey:@"TDS_50_200"])
            {
                _TDS_50_200=[[object objectForKey:@"TDS_50_200"] intValue];
            }
            if ([object objectForKey:@"TDS_50"])
            {
                _TDS_50=[[object objectForKey:@"TDS_50"] intValue];
            }
            if ([object objectForKey:@"TDS_200"])
            {
                _TDS_200=[[object objectForKey:@"TDS_200"] intValue];
            }
            if ([object objectForKey:@"Temp_65"])
            {
                _Temp_65=[[object objectForKey:@"Temp_65"] intValue];
            }
            if ([object objectForKey:@"Temp_25_65"])
            {
                _Temp_25_65=[[object objectForKey:@"Temp_25_65"] intValue];
            }
            if ([object objectForKey:@"Temp_25"])
            {
                _Temp_25=[[object objectForKey:@"Temp_25"] intValue];
            }
            if ([object objectForKey:@"Temp_High"])
            {
                _Temp_High=[[object objectForKey:@"Temp_High"] intValue];
            }
            if ([object objectForKey:@"TDS_High"])
            {
                _TDS_High=[[object objectForKey:@"TDS_High"] intValue];
            }
            if ([object objectForKey:@"Count"])
            {
                _Count=[[object objectForKey:@"Count"] intValue];
            }
        }
    }
    return self;
}
-(NSString *)json
{
    NSMutableDictionary* dict=[[NSMutableDictionary alloc] init];
    [dict setObject:[NSNumber numberWithInt: _Vol] forKey:@"Volume"];
    [dict setObject:[NSNumber numberWithInt: _TDS_50_200] forKey:@"TDS_50_200"];
    [dict setObject:[NSNumber numberWithInt: _TDS_50] forKey:@"TDS_50"];
    [dict setObject:[NSNumber numberWithInt: _TDS_200] forKey:@"TDS_200"];
    [dict setObject:[NSNumber numberWithInt: _Temp_65] forKey:@"Temp_65"];
    [dict setObject:[NSNumber numberWithInt: _Temp_25_65] forKey:@"Temp_25_65"];
    [dict setObject:[NSNumber numberWithInt: _Temp_25] forKey:@"Temp_25"];
    
    [dict setObject:[NSNumber numberWithInt: _Temp_High] forKey:@"Temp_High"];
    [dict setObject:[NSNumber numberWithInt: _TDS_High] forKey:@"TDS_High"];
    [dict setObject:[NSNumber numberWithInt: _Count] forKey:@"Count"];
    
    NSError* error;
    NSData* data=[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    if (!error)
    {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }else
        return nil;
}
@end
