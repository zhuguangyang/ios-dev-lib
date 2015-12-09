//
//  DeviceViewCell.h
//  MxChip
//
//  Created by Zhiyongxu on 15/12/4.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../OznerLibrary/Device/OznerDevice.h"
@interface DeviceViewCell : UITableViewCell<OznerDeviceDelegate>
@property (weak, nonatomic) IBOutlet UILabel *identifier;
@property (weak, nonatomic) IBOutlet UILabel *type;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UILabel *sensor;
@property (weak, nonatomic) IBOutlet UILabel *name;
+(instancetype)loadNibCell;
@property (weak,nonatomic) OznerDevice* device;

@end
