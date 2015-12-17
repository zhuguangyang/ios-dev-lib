//
//  WaterPurifier_TableViewCell.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/16.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseTableViewCell.h"

@interface WaterPurifier_TableViewCell : BaseTableViewCell
- (IBAction)PowerClick:(id)sender;
- (IBAction)HotClick:(id)sender;
- (IBAction)CoolClick:(id)sender;
- (IBAction)SterilizationClick:(id)sender;
@end
