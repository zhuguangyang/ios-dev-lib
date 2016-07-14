//
//  WifiAddViewController.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/14.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../OznerLibrary/Wifi/MXChip/WifiPair.h"
@interface WifiAddViewController : UIViewController<WifiPairDelegate>
{
    NSDate* startTime;
    WifiPair* pair;
    MXChipIO* foundIO;
    NSLayoutConstraint* selfHeightConstraint;
}
@property (weak, nonatomic) IBOutlet UITextField *SSID;
@property (weak, nonatomic) IBOutlet UITextField *Password;
@property (weak, nonatomic) IBOutlet UIButton *StartButton;
@property (weak, nonatomic) IBOutlet UILabel *Status;
@property (weak, nonatomic) IBOutlet UIStackView *StatusView;
@property (weak, nonatomic) IBOutlet UIStackView *DeviceView;


@property (weak, nonatomic) IBOutlet UIButton *CancelButton;
@property (weak, nonatomic) IBOutlet UILabel *MAC;
@property (weak, nonatomic) IBOutlet UILabel *Type;
@property (weak, nonatomic) IBOutlet UILabel *Name;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
- (IBAction)startPair:(id)sender;
- (IBAction)cancelPair:(id)sender;
@end
