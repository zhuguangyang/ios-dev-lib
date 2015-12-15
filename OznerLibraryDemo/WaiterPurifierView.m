//
//  WaiterPurifierView.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/15.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "WaiterPurifierView.h"
#import "WaterPurifier.h"
@implementation WaiterPurifierView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (IBAction)PowerClick:(id)sender {
    WaterPurifier* device=(WaterPurifier*)self.device;
    if (self.device)
    {
        [device.status setPower:!device.status.power];
    }
}

- (IBAction)HotClick:(id)sender {
    WaterPurifier* device=(WaterPurifier*)self.device;
    if (self.device)
    {
        [device.status setHot:!device.status.hot];
    }
}

- (IBAction)CoolClick:(id)sender {
    WaterPurifier* device=(WaterPurifier*)self.device;
    if (self.device)
    {
        [device.status setCool:!device.status.cool];
    }
}


@end
