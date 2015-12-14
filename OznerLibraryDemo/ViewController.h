//
//  ViewController.h
//  MxChip
//
//  Created by Zhiyongxu on 15/11/23.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OznerManager.h"
#import "../OznerLibrary/Wifi/MXChip/MQTTProxy.h"
@interface ViewController : UIViewController<OznerManagerDelegate,UITableViewDataSource,UITableViewDelegate>
{
    NSArray* devices;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

