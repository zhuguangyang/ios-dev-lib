//
//  WaterReplenishmentMeter_TableViewCell.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/21.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "WaterReplenishmentMeter_TableViewCell.h"

@implementation WaterReplenishmentMeter_TableViewCell


- (IBAction)TestClick:(id)sender {
    [self.deviceInfo startSend];
    WaterReplenishmentMeter* water=(WaterReplenishmentMeter*)self.device;
    [water Test:Face Callback:^(NSNumber *value) {
        [self.deviceInfo printStatus:[NSString stringWithFormat:@"测试结果:%f",value.floatValue]];
    }];
}
@end
