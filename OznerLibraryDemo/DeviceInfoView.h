//
//  WaiterPurifierTableViewCell.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/15.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OznerManager.h"
@interface DeviceInfoView : UIView
@property (weak, nonatomic) IBOutlet UILabel *NameLable;
@property (weak, nonatomic) IBOutlet UILabel *IdLabel;
@property (weak, nonatomic) IBOutlet UILabel *TypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *StatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *DescLabel;
-(void) load:(OznerDevice*)device;
@property (weak, nonatomic) IBOutlet DeviceInfoView *StackView;
+(instancetype)loadNibCell:(id)owner;
@end
