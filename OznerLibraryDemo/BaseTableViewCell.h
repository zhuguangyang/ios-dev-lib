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
#import "BaseDeviceView.h"
@interface BaseTableViewCell : UITableViewCell<OznerDeviceDelegate>
{
    DeviceInfoView* deviceInfo;
    BaseDeviceView* deviceView;
    int infoHeight;
}

@property (weak,nonatomic) OznerDevice* device;
-(void)update;
@end
