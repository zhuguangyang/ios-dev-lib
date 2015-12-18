//
//  AirPurifier_Bluetooth_TableViewCell.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/18.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../OznerLibrary/OznerManager.h"
#import "../OznerLibrary/AirPurifier/Bluetooth/AirPurifier_Bluetooth.h"
#import "BaseTableViewCell.h"
@interface AirPurifier_Bluetooth_TableViewCell : BaseTableViewCell
{
    AirPurifier_Bluetooth* air;
    BOOL updated;
}

@property (weak, nonatomic) IBOutlet UISlider *SpeedSlider;

@property (weak, nonatomic) IBOutlet UILabel *SpeedValue;

- (IBAction)SilderChanged:(id)sender;

- (IBAction)PowerClick:(id)sender;
- (IBAction)SetClick:(id)sender;

@end
