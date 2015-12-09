//
//  BluetoothAddDeviceController.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/4.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "BluetoothAddDeviceController.h"
#import "IODeviceViewCell.h"
@interface BluetoothAddDeviceController ()

@end

@implementation BluetoothAddDeviceController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent=NO;
    //navigationController.navigationBar.translcuent = NO;
    [OznerManager instance].delegate=self;
    self->devices=[[OznerManager instance] getNotBindDevices];
}
-(void)update
{
    self->devices=[[OznerManager instance] getNotBindDevices];
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
    [self update];
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
    
    IODeviceViewCell *cell = (IODeviceViewCell*)[tableView dequeueReusableCellWithIdentifier:@"deviceCell"];
    if (!cell)
    {
        cell=[IODeviceViewCell loadNibCell];
    }
    cell.io= [self->devices objectAtIndex:indexPath.item];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
