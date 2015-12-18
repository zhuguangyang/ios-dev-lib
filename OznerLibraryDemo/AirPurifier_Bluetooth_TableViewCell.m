//
//  AirPurifier_Bluetooth_TableViewCell.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/18.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "AirPurifier_Bluetooth_TableViewCell.h"

@implementation AirPurifier_Bluetooth_TableViewCell

- (IBAction)SilderChanged:(id)sender {
    updated=true;
    [self.SpeedValue setText:[NSString stringWithFormat:@"%d%%",(int)_SpeedSlider.value]];
}

- (IBAction)PowerClick:(id)sender {
    [self.deviceInfo startSend];
    [air.status setPower:air.status.power Callback:^(NSError* error){
        [self.deviceInfo printSendStatus:error];
    }];
    
}

- (IBAction)SetClick:(id)sender {
    int RPM=_SpeedSlider.value;
    [self.deviceInfo startSend];
    [air.status setRPM:RPM Callback:^(NSError* error){
        [self.deviceInfo printSendStatus:error];
    }];
}
-(void)setDevice:(OznerDevice *)device
{
    updated=false;
    air=(AirPurifier_Bluetooth*)device;
    [super setDevice:device];
}
-(void)update
{
    if (!updated)
    {
        [self->_SpeedSlider setValue:air.status.RPM];
        [self.SpeedValue setText:[NSString stringWithFormat:@"%d%%",(int)_SpeedSlider.value]];
        
    }
    [super update];
}
@end
