//
//  TapRecord.h
//  OznerBluetooth
//
//  Created by zhiyongxu on 15/3/27.
//  Copyright (c) 2015年 zhiyongxu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CupRecord : NSObject
@property (nonatomic) int Id;
//!@brief 时间，小时或天的取整时间
@property (copy,nonatomic) NSDate * Time;
//!@brief 饮水量计数
@property (nonatomic) int Vol;
//!@brief 50-200 TDS计数
@property (nonatomic) int TDS_50_200;
//!@brief 50以下 TDS计数
@property (nonatomic) int TDS_50;
//!@brief 200以上 TDS计数
@property (nonatomic) int TDS_200;
//!@brief 65度以上温度计数
@property (nonatomic) int Temp_65;
//!@brief 25-65度温度计数
@property (nonatomic) int Temp_25_65;
//!@brief 25度以下温度计数
@property (nonatomic) int Temp_25;

@property (nonatomic) int Temp_High;
@property (nonatomic) int TDS_High;
@property (nonatomic) int Count;
-(id) initWithJSON:(NSDate*)time JSON:(NSString*)JSON;
-(void)incTDS:(int)TDS;
-(void)incTemp:(int)Temp;
-(NSString*)json;

@end