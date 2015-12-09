//
//  IODeviceViewCell.h
//  MxChip
//
//  Created by Zhiyongxu on 15/12/4.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../OznerLibrary/Device/BaseDeviceIO.h"
@interface IODeviceViewCell : UITableViewCell
{
}
@property (weak, nonatomic) IBOutlet UILabel *identifier;
@property (weak, nonatomic) IBOutlet UILabel *type;
@property (weak, nonatomic) IBOutlet UILabel *info;
@property (weak, nonatomic) BaseDeviceIO* io;
+(instancetype)loadNibCell;
- (IBAction)bindDown:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *bind;
@end
