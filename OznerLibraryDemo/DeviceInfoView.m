//
//  WaiterPurifierTableViewCell.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/15.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "DeviceInfoView.h"

@implementation DeviceInfoView

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self=[super initWithCoder:aDecoder])
    {
        NameLable=[[UILabel alloc] init];
        IdLabel=[[UILabel alloc] init];
        TypeLabel=[[UILabel alloc] init];
        DescLabel=[[UILabel alloc] init];
        SendStatus=[[UILabel alloc] init];
        
        StatusLabel=[[UILabel alloc] init];
        [DescLabel setNumberOfLines:0];
        
        [SendStatus setText:@"发送状态:"];
        [SendStatus setNumberOfLines:0];
        
        [self addArrangedSubview:NameLable];
        [self addArrangedSubview:IdLabel];
        [self addArrangedSubview:TypeLabel];
        
        [self addArrangedSubview:StatusLabel];
        [self addArrangedSubview:DescLabel];

        [self addArrangedSubview:SendStatus];
        
    }
    return self;
}
-(void)startSend
{
    [SendStatus setText:@"发送状态:正在发送"];
}
-(void)printSendStatus:(NSError *)error
{
    if (error)
    {
        [SendStatus setText:[NSString stringWithFormat:@"发送状态:%@",[error debugDescription]]];
    }else
    {
        [SendStatus setText:@"发送状态:成功"];
    }
}
-(void) load:(OznerDevice*)device
{
    [NameLable setText:device.settings.name];
    [IdLabel setText:[NSString stringWithFormat:@"id:%@",device.identifier]];
    [TypeLabel setText:[NSString stringWithFormat:@"type:%@",device.type]];
    switch ([device connectStatus]) {
        case Connected:
            [StatusLabel setText:@"连接状态:已连接"];
            break;
        case Disconnect:
            [StatusLabel setText:@"连接状态:未连接"];
            break;
        case Connecting:
            [StatusLabel setText:@"连接状态:连接中"];
            break;
    }
    [DescLabel setText:[device description]];
}


@end
