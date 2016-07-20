//
//  WaterPurifier_TableViewCell.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/16.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "WaterPurifier_TableViewCell.h"
#import "WaterPurifier.h"
#import "OznerDevice.h"
#import "WaterPurifier_Ayla.h"
@implementation WaterPurifier_TableViewCell

//OznerDevice* Device;
- (void)awakeFromNib {
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)PowerClick:(id)sender {
    if (!self.device) {
        return;
    }
    
    if ([self.device.type isEqualToString:@"AY001MAB1"]) {
        WaterPurifier_Ayla* Device=(WaterPurifier_Ayla*)self.device;
        [self.deviceInfo startSend];
        [Device setPower:![Device getPower] Callback:^(NSError *error) {
            [self printSendStatus:error];
        }];
    }else{
        WaterPurifier* Device=(WaterPurifier*)self.device;
        [self.deviceInfo startSend];
        
        [Device.status setPower:!Device.status.power Callback:^(NSError* error){
            [self printSendStatus:error];
        }];
    }
    
}

- (IBAction)HotClick:(id)sender {
    if (!self.device) {
        return;
    }
    
    if ([self.device.type isEqualToString:@"AY001MAB1"]) {
        WaterPurifier_Ayla* Device=(WaterPurifier_Ayla*)self.device;
        [self.deviceInfo startSend];
        [Device setHot:![Device getHot] Callback:^(NSError *error) {
            [self printSendStatus:error];
        }];
    }else{
        WaterPurifier* Device=(WaterPurifier*)self.device;
        [self.deviceInfo startSend];
        
        [Device.status setHot:!Device.status.hot Callback:^(NSError* error){
            [self printSendStatus:error];
        }];
    }
}

- (IBAction)CoolClick:(id)sender {
    if (!self.device) {
        return;
    }
    
    if ([self.device.type isEqualToString:@"AY001MAB1"]) {
        WaterPurifier_Ayla* Device=(WaterPurifier_Ayla*)self.device;
        [self.deviceInfo startSend];
        [Device setCool:![Device getCool] Callback:^(NSError *error) {
            [self printSendStatus:error];
        }];
    }else{
        WaterPurifier* Device=(WaterPurifier*)self.device;
        [self.deviceInfo startSend];
        
        [Device.status setCool:!Device.status.cool Callback:^(NSError* error){
            [self printSendStatus:error];
        }];
    }
}

- (IBAction)SterilizationClick:(id)sender {
    if (!self.device) {
        return;
    }
    
    if ([self.device.type isEqualToString:@"AY001MAB1"]) {
        WaterPurifier_Ayla* Device=(WaterPurifier_Ayla*)self.device;
        [self.deviceInfo startSend];
        [Device setSterilization:![Device getSterilization] Callback:^(NSError *error) {
            [self printSendStatus:error];
        }];
    }else{
        WaterPurifier* Device=(WaterPurifier*)self.device;
        [self.deviceInfo startSend];
        
        [Device.status setSterilization:!Device.status.sterilization Callback:^(NSError* error){
            [self printSendStatus:error];
        }];
    }
}

@end
