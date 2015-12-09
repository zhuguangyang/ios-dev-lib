//
//  BluetoothAddDeviceController.h
//  MxChip
//
//  Created by Zhiyongxu on 15/12/4.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "../OznerLibrary/OznerManager.h"

@interface BluetoothAddDeviceController : UIViewController<OznerManagerDelegate,UITableViewDataSource,UITableViewDelegate>
{
    OznerManager* oznerManager;
    NSArray* devices;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
