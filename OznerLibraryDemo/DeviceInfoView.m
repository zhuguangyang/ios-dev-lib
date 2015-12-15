//
//  WaiterPurifierTableViewCell.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/15.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "DeviceInfoView.h"

@implementation DeviceInfoView


+(instancetype)loadNibCell:(id)owner
{
    return [[[NSBundle mainBundle] loadNibNamed:@"DeviceInfoView" owner:owner options:nil] lastObject];
}

-(void) load:(OznerDevice*)device
{
    [self.NameLable setText:device.settings.name];
    [self.IdLabel setText:[NSString stringWithFormat:@"id:%@",device.identifier]];
    [self.TypeLabel setText:[NSString stringWithFormat:@"type:%@",device.type]];
    switch ([device connectStatus]) {
        case Connected:
            [self.StatusLabel setText:@"status:已连接"];
            break;
        case Disconnect:
            [self.StatusLabel setText:@"status:未连接"];
            break;
        case Connecting:
            [self.StatusLabel setText:@"status:连接中"];
            break;
    }
    [self.DescLabel setText:[device description]];
}


@end
