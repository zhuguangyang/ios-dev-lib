//
//  MXChipIOManager.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/8.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "MXChipIOManager.h"

#import "../../Device/IOManager.hpp"
@implementation MXChipIOManager
-(instancetype)init
{
    if (self=[super init])
    {
        proxy=[[MQTTProxy alloc] init];
    }
    return self;
}
-(void)delayAvailable:(MXChipIO*)io
{
    if (proxy.connected)
    {
        [self doAvailable:io];
    }
}
-(void)IOClosed:(MXChipIO *)io
{
    [self doUnavailable:io];
    if (proxy.connected)
    {
        //延迟5秒重新激活io
        [self performSelector:@selector(delayAvailable:) withObject:io afterDelay:5];
    }
}
-(MXChipIO*)createMXChipIO:(NSString *)identifier Type:(NSString*)type;
{
    MXChipIO* io=(MXChipIO*)[super getAvailableDevice:identifier];
    if (!io)
    {
        io=[[MXChipIO alloc] init:identifier Type:type];
    }
    io.statusDelegate=self;
    [self doAvailable:io];
    return io;
}

-(void)MQTTProxyConnected:(MQTTProxy *)proxy
{
    NSArray* devices=[super getAvailableDevices];
    for (MXChipIO* io in devices) {
        [self doAvailable:io];
    }
}

-(void)MQTTProxyDisconnected:(MQTTProxy *)proxy
{
    NSArray* devices=[super getAvailableDevices];
    for (MXChipIO* io in devices) {
        [self doUnavailable:io];
    }
}

-(BaseDeviceIO *)getAvailableDevice:(NSString *)identifier
{
    if (proxy.connected)
    {
        return [super getAvailableDevice:identifier];
    }else
        return nil;
}

-(NSArray *)getAvailableDevices
{
    if (proxy.connected)
    {
        return [super getAvailableDevices];
    }else
        return [[NSArray alloc] init];
}
@end
