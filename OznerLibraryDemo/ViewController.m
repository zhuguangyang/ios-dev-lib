//
//  ViewController.m
//  MxChip
//
//  Created by Zhiyongxu on 15/11/23.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "ViewController.h"
#import "BaseTableViewCell.h"


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
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
    NSString* name=[NSString stringWithUTF8String:object_getClassName(device)];
    BaseTableViewCell *cell = (BaseTableViewCell*)[tableView dequeueReusableCellWithIdentifier:name];
    if (!cell)
    {
        cell=[[BaseTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:name];
    }
    cell.device=device;
    [cell setNeedsDisplay];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 180;
}

@end
