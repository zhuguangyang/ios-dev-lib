//
//  WaterPurifier_TableViewCell.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/16.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "WaterPurifier_TableViewCell.h"
#import "WaterPurifier.h"
@implementation WaterPurifier_TableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)PowerClick:(id)sender {
    WaterPurifier* device=(WaterPurifier*)self.device;
    if (self.device)
    {
        [self.deviceInfo startSend];
        
        [device.status setPower:!device.status.power Callback:^(NSError* error){
            [self printSendStatus:error];
        }];
    }
}

- (IBAction)HotClick:(id)sender {
    WaterPurifier* device=(WaterPurifier*)self.device;
    if (self.device)
    {
        [self.deviceInfo startSend];
        
        [device.status setHot:!device.status.hot Callback:^(NSError* error){
            [self printSendStatus:error];
        }];
    }
}

- (IBAction)CoolClick:(id)sender {
    WaterPurifier* device=(WaterPurifier*)self.device;
    if (self.device)
    {
        [self.deviceInfo startSend];
        
        [device.status setCool:!device.status.cool Callback:^(NSError* error){
            [self printSendStatus:error];
        }];
    }
}

- (IBAction)SterilizationClick:(id)sender {
    WaterPurifier* device=(WaterPurifier*)self.device;
    if (self.device)
    {
        [self.deviceInfo startSend];
        [device.status setSterilization:!device.status.sterilization Callback:^(NSError* error){
            [self printSendStatus:error];
        }];
    }
}

@end
