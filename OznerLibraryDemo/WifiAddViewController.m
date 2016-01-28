//
//  WifiAddViewController.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/14.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "WifiAddViewController.h"
#import "../OznerLibrary/OznerManager.h"
#import "../OznerLibrary/Helper/Helper.h"
@interface WifiAddViewController ()

@end

@implementation WifiAddViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    pair=[[MXChipPair alloc] init];
    pair.delegate=self;
    NSString* ssid=[MXChipPair getWifiSSID];
    self.SSID.text=ssid;
    if (!StringIsNullOrEmpty(ssid))
    {
        NSUserDefaults* settings=[NSUserDefaults standardUserDefaults];
        NSString* pwd=[settings stringForKey:[NSString stringWithFormat:@"SSID_%@",ssid]];
        if (!StringIsNullOrEmpty(pwd))
        {
            self.Password.text=pwd;
        }
     }
    [self regNotification];
    selfHeightConstraint=[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.view.frame.size.height];
    
    [self.view addConstraint:selfHeightConstraint];
    for (NSLayoutConstraint* c in self.view.constraints)
    {
        NSLog(@"constraint:%@",[c description]);
    }
    //c89346c04dc2
    //MXChipIO* io=[[OznerManager instance].ioManager.mxchip createMXChipIO:@"C8:93:46:4F:84:03" Type:@"FOG_HAOZE_AIR"];
    //MXChipIO* io=[[OznerManager instance].ioManager.mxchip createMXChipIO:@"C8:93:46:4F:89:CF" Type:@"FOG_HAOZE_AIR"];
    
    //OznerDevice* device= [[OznerManager instance] getDeviceByIO:io];
    //[[OznerManager instance]save:device];
}
-(void)dealloc
{
    [self unregNotification];

}
-(void)showStatus:(NSString*)status
{
    self.StatusView.hidden=false;
    self.indicator.hidden=false;
    [self.indicator startAnimating];
    [self.Status setText:status];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)complete:(MXChipIO *)io
{
    NSDate* date=[NSDate dateWithTimeIntervalSinceNow:0];
    NSString* log=[NSString stringWithFormat:@"配网成功,耗时:%f秒",
                   [date timeIntervalSince1970]-[startTime timeIntervalSince1970]
                   ];
    [self showStatus:log];
    self.DeviceView.hidden=false;
    self.Name.text=[NSString stringWithFormat:@"Name:%@",io.name];
    self.Type.text=[NSString stringWithFormat:@"Type:%@",io.type];
    self.MAC.text=[NSString stringWithFormat:@"MAC:%@",io.identifier];
    
    [self.StartButton setTitle:@"Next" forState:UIControlStateNormal];

    
    
    foundIO=io;
    [self.indicator stopAnimating];
    self.indicator.hidden=true;
    self.CancelButton.enabled=false;
    self.StartButton.enabled=true;
    
}
-(void)mxChipComplete:(MXChipIO *)io
{
    [self complete:io];
}
-(void)doFailure
{
    [self showStatus:@"配网失败"];
    [self.indicator stopAnimating];
    self.indicator.hidden=true;
    self.CancelButton.enabled=false;
    self.StartButton.enabled=true;
}
-(void)mxChipFailure
{
    [self performSelectorOnMainThread:@selector(doFailure) withObject:nil waitUntilDone:false];
}
-(void)mxChipPairActivate
{
    [self performSelectorOnMainThread:@selector(showStatus:) withObject:@"等待设备激活" waitUntilDone:false];
}
-(void)mxChipPairSendConfiguration
{
    [self performSelectorOnMainThread:@selector(showStatus:) withObject:@"正在发送配置信息" waitUntilDone:false];
}
-(void)mxChipPairWaitConnectWifi
{
    [self performSelectorOnMainThread:@selector(showStatus:) withObject:@"等待设备连接wifi"waitUntilDone:false];
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)regNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)unregNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}


- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect beginKeyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat yOffset = beginKeyboardRect.origin.y-endKeyboardRect.origin.y;
    
    CGRect selfRect = self.view.frame;
    selfHeightConstraint.constant=selfRect.size.height-yOffset;
    
    //selfRect.size.height -= yOffset;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view updateConstraintsIfNeeded];
    }];
}

- (IBAction)startPair:(id)sender {
    if (foundIO)
    {
        OznerDevice* device=[[OznerManager instance] getDeviceByIO:foundIO];
        [[OznerManager instance] save:device];
        [self popoverPresentationController];
    }
    else
    {
        NSString* ssid=self.SSID.text;
        NSString* pwd=self.Password.text;
        if (StringIsNullOrEmpty(ssid))
        {
            UIAlertController* alert=[UIAlertController alertControllerWithTitle:@"错误"
                                                                         message:@"请输入SSID"
                                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的"
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        NSUserDefaults* settings=[NSUserDefaults standardUserDefaults];
        [settings setObject:self.Password.text forKey:[NSString stringWithFormat:@"SSID_%@",ssid]];
        [settings synchronize];
        startTime=[NSDate dateWithTimeIntervalSinceNow:0];
        self.StartButton.enabled=false;
        self.CancelButton.enabled=true;
        [pair start:ssid Password:pwd];
        [self showStatus:@"开始配网"];
    }
}
- (IBAction)cancelPair:(id)sender {
    if (pair.isRuning)
    {
        [pair cancel];
        self.StartButton.titleLabel.text=@"Start";
        [self showStatus:@"canceled"];
        [self.indicator stopAnimating];
        self.indicator.hidden=true;
        self.StartButton.enabled=true;
        self.CancelButton.enabled=false;
    }
    
}
@end
