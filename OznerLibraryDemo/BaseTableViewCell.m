//
//  BaseTableViewCell.m
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/15.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import "BaseTableViewCell.h"

@implementation BaseTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

//-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
//{
//    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier])
//    {
//        deviceInfo=[DeviceInfoView loadNib:self];
//        deviceInfo.frame=CGRectMake(0, 0, deviceInfo.frame.size.width, deviceInfo.frame.size.height);
//        //deviceInfo.translatesAutoresizingMaskIntoConstraints = NO;
//        //self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
//        [self addSubview:deviceInfo];
//        //[self addSubview:deviceInfo];
//        @try {
//            NSArray* array=[[NSBundle mainBundle] loadNibNamed:reuseIdentifier owner:self options:nil];
//            if (array!=nil)
//            {
//                deviceView=[array lastObject];
//                deviceView.frame=CGRectMake(0, deviceInfo.frame.size.height, deviceView.frame.size.width, deviceView.frame.size.height);
//                //deviceView.translatesAutoresizingMaskIntoConstraints = NO;
//                [self addSubview:deviceView];
//                //[self addSubview:deviceView];
//            }
//        }
//        @catch (NSException *exception) {
//        }
//        self.selectionStyle = UITableViewCellSelectionStyleNone;
//    }
//    return self;
//}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self=[super initWithCoder:aDecoder])
    {
        _deviceInfo=[self viewWithTag:100];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}
-(void)OznerDeviceSensorUpdate:(OznerDevice *)device
{
    [self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:false];
    
    //[self update];
}


-(void)OznerDeviceStatusUpdate:(OznerDevice *)device
{
    [self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:false];
    
    //[self update];
}

-(void)update
{
    [_deviceInfo load:_device];
}

-(void)setDevice:(OznerDevice *)device
{
    _device=device;
    _device.delegate=self;
    
    [self update];
}

-(void)printSendStatusSel:(NSError *)error
{
    [_deviceInfo printSendStatus:error];
}

-(void)printSendTextSel:(NSString *)text
{
    [_deviceInfo printStatus:text];
}

-(void)printText:(NSString *)text
{
    [self performSelectorOnMainThread:@selector(printSendTextSel:) withObject:text waitUntilDone:false];
}
-(void)printSendStatus:(NSError *)error
{
    [self performSelectorOnMainThread:@selector(printSendStatusSel:) withObject:error waitUntilDone:false];
}
@end
