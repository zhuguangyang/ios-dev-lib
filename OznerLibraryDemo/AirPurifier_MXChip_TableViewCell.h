//
//  AirPurifier_MXChip_TableViewCell.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/16.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseTableViewCell.h"
#import "MyButton.h"
@interface AirPurifier_MXChip_TableViewCell : BaseTableViewCell
- (IBAction)PowerClick:(id)sender;
- (IBAction)SpeedClick:(id)sender;
- (IBAction)LockClick:(id)sender;
- (IBAction)ResetFilter:(id)sender;
- (IBAction)PowerTimerChange:(id)sender;
- (IBAction)StartTimeClick:(id)sender;
- (IBAction)EndTimeClick:(id)sender;
- (IBAction)WeekClick:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *PowerSwitch;
@property (weak, nonatomic) IBOutlet MyButton *StartTime;
@property (weak, nonatomic) IBOutlet MyButton *EndTime;
- (IBAction)SaveClick:(id)sender;
@end
