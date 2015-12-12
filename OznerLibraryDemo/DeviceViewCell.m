//
//  DeviceViewCell.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/4.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "DeviceViewCell.h"

@implementation DeviceViewCell

- (void)awakeFromNib {
    // Initialization code
}
-(void)OznerDeviceSensorUpdate:(OznerDevice *)device
{
    [self update];
}
-(void)OznerDeviceStatusUpdate:(OznerDevice *)device
{
    [self update];
}
+(instancetype)loadNibCell;
{
    return [[NSBundle mainBundle] loadNibNamed:@"DeviceViewCell" owner:nil options:nil][0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(void)update
{
    if (self.device)
    {
        [self.name setText:self.device.settings.name];
        [self.identifier setText:[NSString stringWithFormat:@"id:%@",self.device.identifier]];
        [self.type setText:[NSString stringWithFormat:@"type:%@",self.device.type]];
        switch (self.device.status) {
            case Connected:
                [self.status setText:@"status:已连接"];
                break;
            case Disconnect:
                [self.status setText:@"status:未连接"];
                break;
            case Connecting:
                [self.status setText:@"status:连接中"];
                break;
        }
        [self.sensor setText:[self.device description]];
    }
    
}
-(void)setDevice:(OznerDevice *)device
{
    _device=device;
    _device.delegate=self;
    [self update];
}
@end
