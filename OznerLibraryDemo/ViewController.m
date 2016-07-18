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
#import "WaterPurifier_Ayla.h"
#import "AirPurifier_MxChip.h"
#import "AirPurifier_Bluetooth.h"
@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self->_tableView registerNib:[UINib nibWithNibName:@"WaterPurifier_TableViewCell" bundle:nil] forCellReuseIdentifier:NSStringFromClass([WaterPurifier class])];
    
    [self->_tableView registerNib:[UINib nibWithNibName:@"AirPurifier_MXChip_TableViewCell" bundle:nil] forCellReuseIdentifier:NSStringFromClass([AirPurifier_MxChip class])];
    
    [self->_tableView registerNib:[UINib nibWithNibName:@"AirPurifier_Bluetooth_TableViewCell" bundle:nil] forCellReuseIdentifier:NSStringFromClass([AirPurifier_Bluetooth class])];
    
    [self->_tableView registerNib:[UINib nibWithNibName:@"DeviceTableViewCell" bundle:nil] forCellReuseIdentifier:@"DeviceTableViewCell"];
    
 
}
-(void)viewDidAppear:(BOOL)animated
{
    [OznerManager instance].delegate=self;
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

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        OznerDevice* device=[devices objectAtIndex:indexPath.item];
        [[OznerManager instance] remove:device];
        [self update];
    }  
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete	;
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
    if ([device.class isSubclassOfClass:[WaterPurifier class]]||[device.class isSubclassOfClass:[WaterPurifier_Ayla class]])
    {
        return 200;
    }
    if ([device.class isSubclassOfClass:[AirPurifier_MxChip class]])
    {
        return 460;
    }
    if ([device.class isSubclassOfClass:[AirPurifier_Bluetooth class]])
    {
        return 370;
    }
    return 240;
}

@end
