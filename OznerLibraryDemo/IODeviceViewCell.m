//
//  IODeviceViewCell.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/4.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "IODeviceViewCell.h"
#import "../OznerLibrary/OznerManager.h"

@implementation IODeviceViewCell
+(instancetype)loadNibCell;
{
    return [[NSBundle mainBundle] loadNibNamed:@"IODeviceViewCell" owner:nil options:nil][0];
}

- (IBAction)bindDown:(id)sender {
    //配对设备
    OznerDevice* device= [[OznerManager instance] getDeviceByIO:self.io];
    if (device)
    {
        device.settings.name=@"test";
        //保存配对设备
        [[OznerManager instance] save:device];
    }
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(void)setIo:(BaseDeviceIO *)io
{
    self->_io=io;
    if (io)
    {
        [self.identifier setText:[NSString stringWithFormat:@"id:%@", io.identifier] ];
        [self.type setText:[NSString stringWithFormat:@"type:%@", io.type]];
        [self.info setText:[io description]];
        BOOL bind=[[OznerManager instance]  checkisBindMode:io];
        NSLog(@"bind:%d",bind);
        [self.bind setEnabled:bind];
        
    }
}


@end
