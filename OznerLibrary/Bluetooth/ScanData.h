//
//  ScanData.h
//  OznerBluetooth
//
//  Created by zhiyongxu on 15/3/16.
//  Copyright (c) 2015年 zhiyongxu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScanData : NSObject
-(instancetype)init:(NSData*) data;
-(instancetype)init:(NSString*)model platform:(NSString*) platform advertisement:(NSData*) advertisementData;
@property (readonly,copy) NSString* model;
@property (readonly,copy) NSString* platform;
@property (strong,readonly) NSDate* firmware;

@property (readonly) int scanResponesType;
@property (strong,readonly) NSData* scanResponesData;


@end
