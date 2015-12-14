//
//  DeviceViewCell.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/4.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "DeviceViewCell.h"
#import "../OznerLibrary/Cup/Cup.h"
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
        switch ([self.device connectStatus]) {
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
        
        if ([self.device isKindOfClass:[Cup class]])
        {
            Cup* cup=(Cup*) self.device;
            CupRecord* record=[cup.volumes getLastDay];
            NSLog(@"lastDay:%@",[record description]);
            
            record=[cup.volumes getLastHour];
            NSLog(@"lastHour:%@",[record description]);
            
            //取今天的0点时间
            NSDate* date=[[NSDate alloc] initWithTimeIntervalSince1970:(int)([[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970])/86400*86400];
            
            //取每次饮水纪录
            NSArray* array=[cup.volumes getRecordByDate:date Interval:Raw];
            for (CupRecord* r in array)
            {
                NSLog(@"Raw:%@",[r description]);
            }
            
            //取今日每小时饮水纪录
            array=[cup.volumes getRecordByDate:date Interval:Hour];
            for (CupRecord* r in array)
            {
                NSLog(@"hour:%@",[r description]);
            }
            
            //取今天饮水纪录
            array=[cup.volumes getRecordByDate:date Interval:Day];
            for (CupRecord* r in array)
            {
                NSLog(@"day:%@",[r description]);
            }
            
            
        }
    }
    
}
-(void)setDevice:(OznerDevice *)device
{
    _device=device;
    _device.delegate=self;
    [self update];
}
@end
