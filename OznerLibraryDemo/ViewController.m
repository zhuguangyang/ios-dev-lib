//
//  ViewController.m
//  MxChip
//
//  Created by Zhiyongxu on 15/11/23.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "ViewController.h"
#import "DeviceViewCell.h"

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    mqtt=[[MQTTProxy alloc] init];
    
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self->devices count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    DeviceViewCell *cell = (DeviceViewCell*)[tableView dequeueReusableCellWithIdentifier:@"deviceCell"];
    if (!cell)
    {
        cell=[DeviceViewCell loadNibCell];
    }
    cell.device=[devices objectAtIndex:indexPath.item];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

@end
