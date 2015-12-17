//
//  ViewController.m
//  MxChip
//
//  Created by Zhiyongxu on 15/11/23.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "ViewController.h"
#import "BaseTableViewCell.h"
#import "WaterPurifier.h"
#import "AirPurifier_MxChip.h"

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [OznerManager instance].delegate=self;
    [self->_tableView registerNib:[UINib nibWithNibName:@"WaterPurifier_TableViewCell" bundle:nil] forCellReuseIdentifier:NSStringFromClass([WaterPurifier class])];
    
    [self->_tableView registerNib:[UINib nibWithNibName:@"AirPurifier_MXChip_TableViewCell" bundle:nil] forCellReuseIdentifier:NSStringFromClass([AirPurifier_MxChip class])];
    
    [self->_tableView registerNib:[UINib nibWithNibName:@"DeviceTableViewCell" bundle:nil] forCellReuseIdentifier:@"DeviceTableViewCell"];
    
    [self update];
}

-(void)update
{
    self->devices=[[OznerManager instance] getDevices];
    [self.tableView reloadData];
}

-(void)OznerManagerDidAddDevice:(OznerDevice *)device
{
    [self update];
    
}
-(void)OznerManagerDidOwnerChanged:(NSString *)owner
{
    [self update];
    
}
-(void)OznerManagerDidRemoveDevice:(OznerDevice *)device
{
    [self update];
    
}
-(void)OznerManagerDidFoundDevice:(BaseDeviceIO *)io
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(BOOL)tableView:(UITableView *)tableView canFocusRowAtIndexPath:(NSIndexPath *)indexPath
{
    return false;
}
-(void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self->devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OznerDevice* device=[devices objectAtIndex:indexPath.item];
    NSString* name=NSStringFromClass(device.class);
    BaseTableViewCell *cell = (BaseTableViewCell*)[tableView dequeueReusableCellWithIdentifier:name];
    if (cell==nil)
    {
        cell = (BaseTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"DeviceTableViewCell"];
    }
    cell.device=device;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OznerDevice* device=[devices objectAtIndex:indexPath.item];
    if ([device.class isSubclassOfClass:[WaterPurifier class]])
    {
        return 200;
    }
    if ([device.class isSubclassOfClass:[AirPurifier_MxChip class]])
    {
        return 390;
    }
    return 240;
}

@end
