//
//  AirPurifier_MXChip_TableViewCell.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/16.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "AirPurifier_MXChip_TableViewCell.h"
#import "AirPurifier_MxChip.h"
@implementation AirPurifier_MXChip_TableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)PowerClick:(id)sender {
    AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
    [self.deviceInfo startSend];
    
    [air.status setPower:!air.status.power Callback:^(NSError *error) {
        [self printSendStatus:error];
    }];
    
}

- (IBAction)SpeedClick:(id)sender {
    AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
    Byte speed=air.status.speed;
    
    switch (speed) {
        case FAN_SPEED_AUTO:
            speed=FAN_SPEED_POWER;
            break;
        case FAN_SPEED_POWER:
            speed=FAN_SPEED_SILENT;
            break;
        case FAN_SPEED_SILENT:
            speed=FAN_SPEED_AUTO;
            break;
        default:
            speed=FAN_SPEED_AUTO;
            break;
    }
    
    [self.deviceInfo startSend];
    
    [air.status setSpeed:speed Callback:^(NSError *error) {
        [self printSendStatus:error];
    }];
    
}

- (IBAction)LockClick:(id)sender {
    AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
    [self.deviceInfo startSend];
    
    [air.status setLock:!air.status.lock Callback:^(NSError *error) {
        [self printSendStatus:error];
    }];
}

- (IBAction)ResetFilter:(id)sender {
    AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
    [self.deviceInfo startSend];
    
    [air.status resetFilterStatus:^(NSError *error) {
        [self printSendStatus:error];
    }];
}

- (IBAction)PowerTimerChange:(id)sender {
    
    AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
    UISwitch* sw=(UISwitch*)sender;
    air.powerTimer.enable=sw.on;
    
}

-(void)setDevice:(OznerDevice *)device
{
    [super setDevice:device];
    [self loadPowerTimer];
}
-(void)loadPowerTimer
{
    AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
    self.PowerSwitch.on=air.powerTimer.enable;
    [self.StartTime setTitle:[NSString stringWithFormat:@"%d:%d",
                              air.powerTimer.powerOnTime/60,
                              air.powerTimer.powerOnTime%60] forState:UIControlStateNormal];
    
    [self.EndTime setTitle:[NSString stringWithFormat:@"%d:%d",
                              air.powerTimer.powerOffTime/60,
                              air.powerTimer.powerOffTime%60] forState:UIControlStateNormal];
    
    
    ((UIButton*)[self viewWithTag:Monday]).selected=(air.powerTimer.week & Monday);
    ((UIButton*)[self viewWithTag:Tuesday]).selected=(air.powerTimer.week & Tuesday);
    ((UIButton*)[self viewWithTag:Wednesday]).selected=(air.powerTimer.week & Wednesday);
    ((UIButton*)[self viewWithTag:Thursday]).selected=(air.powerTimer.week & Thursday);
    ((UIButton*)[self viewWithTag:Friday]).selected=(air.powerTimer.week & Friday);
    ((UIButton*)[self viewWithTag:Saturday]).selected=(air.powerTimer.week & Saturday);
    ((UIButton*)[self viewWithTag:Sunday]).selected=(air.powerTimer.week & Sunday);
    
}

- (IBAction)StartTimeClick:(id)sender {
    AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
    UIAlertController* alert=[UIAlertController alertControllerWithTitle:@"\n\n\n\n\n\n\n\n\n\n"
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    [datePicker setDatePickerMode:UIDatePickerModeTime];
    datePicker.date=[NSDate dateWithTimeIntervalSince1970:air.powerTimer.powerOnTime*60-[NSTimeZone systemTimeZone].secondsFromGMT];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action){
                                                         AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
                                                        NSTimeInterval inv=[datePicker.date timeIntervalSince1970]+[NSTimeZone systemTimeZone].secondsFromGMT;
                                                        
                                                         air.powerTimer.powerOnTime=((int)inv%86400)/60;
                                                         [self loadPowerTimer];
                                                         
                                                     }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    
    [alert.view addSubview:datePicker];

    [alert addAction:okAction];
    [alert addAction:cancelAction];

    [self.window.rootViewController presentViewController:alert animated:true completion:nil];
    
    
}

- (IBAction)EndTimeClick:(id)sender {
    AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
    UIAlertController* alert=[UIAlertController alertControllerWithTitle:@"\n\n\n\n\n\n\n\n\n\n"
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    [datePicker setDatePickerMode:UIDatePickerModeTime];
    [datePicker setTimeZone:[NSTimeZone defaultTimeZone]];
    
    datePicker.date=[NSDate dateWithTimeIntervalSince1970:air.powerTimer.powerOffTime*60-[NSTimeZone systemTimeZone].secondsFromGMT];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action){
                                                         AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
                                                         NSTimeInterval inv=[datePicker.date timeIntervalSince1970]+[NSTimeZone systemTimeZone].secondsFromGMT;
                                                         
                                                         air.powerTimer.powerOffTime=((int)inv%86400)/60;
                                                         [self loadPowerTimer];
                                                         
                                                     }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    
    [alert.view addSubview:datePicker];
    
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    [self.window.rootViewController presentViewController:alert animated:true completion:nil];
}

- (IBAction)WeekClick:(id)sender {
    
    AirPurifier_MxChip* air=(AirPurifier_MxChip*)self.device;
   
    air.powerTimer.week=(air.powerTimer.week ^ (int)((UIButton*)sender).tag);
    
    [self loadPowerTimer];
    
    
}
- (IBAction)SaveClick:(id)sender {
    [self.deviceInfo startSend];
    [[OznerManager instance] save:self.device Callback:^(NSError *error) {
        [self printSendStatus:error];
    }];
}
@end
