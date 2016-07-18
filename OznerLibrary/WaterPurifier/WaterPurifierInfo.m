//
//  WaterPurifierInfo.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/9.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "WaterPurifierInfo.h"

@implementation WaterPurifierInfo
-(instancetype)init
{
    if (self=[super init])
    {
    }
    return self;
}
-(void)load:(BytePtr)bytes
{
    self->_Model=[[NSString alloc] initWithBytes:bytes+12 length:10 encoding:NSASCIIStringEncoding];
    self->_Type=[[NSString alloc] initWithBytes:bytes+22 length:16 encoding:NSASCIIStringEncoding];
    self->_MainBoard=[[NSString alloc] initWithBytes:bytes+38 length:22 encoding:NSASCIIStringEncoding];
    self->_ControlBoard=[[NSString alloc] initWithBytes:bytes+60 length:22 encoding:NSASCIIStringEncoding];
    self->_ErrorCount=bytes[123];
    self->_Error=*((int*)(bytes+124));
}
-(void)load_Ayla:(BytePtr)bytes
{
//    info.Model = new String(bytes, 6, 10, "US-ASCII").trim();
//    info.MainBoard = new String(bytes, 76, 12, "US-ASCII").trim();
//    info.ControlBoard = new String(bytes, 88, 12, "US-ASCII").trim();
    
    self->_Model=[[NSString alloc] initWithBytes:bytes+6 length:10 encoding:NSASCIIStringEncoding];
    //self->_Type=[[NSString alloc] initWithBytes:bytes+22 length:16 encoding:NSASCIIStringEncoding];
    self->_MainBoard=[[NSString alloc] initWithBytes:bytes+76 length:12 encoding:NSASCIIStringEncoding];
    self->_ControlBoard=[[NSString alloc] initWithBytes:bytes+88 length:12 encoding:NSASCIIStringEncoding];
    //self->_ErrorCount=bytes[123];
    //self->_Error=*((int*)(bytes+124));
}
@end
