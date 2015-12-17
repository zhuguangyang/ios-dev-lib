//
//  BaseTableViewCell.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/15.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OznerManager.h"
#import "DeviceInfoView.h"
@interface BaseTableViewCell : UITableViewCell<OznerDeviceDelegate>
{
    //DeviceInfoView* deviceInfo;
    //int infoHeight;
}
@property (weak, nonatomic) IBOutlet DeviceInfoView *deviceInfo;
@property (weak,nonatomic) OznerDevice* device;
-(void)update;
-(void)printSendStatus:(NSError*)error;

@end

