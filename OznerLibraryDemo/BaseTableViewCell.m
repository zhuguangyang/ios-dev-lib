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
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        deviceInfo=[DeviceInfoView loadNibCell:self];
        infoHeight=deviceInfo.frame.size.height;
        [self addSubview:deviceInfo];
        @try {
            NSArray* array=[[NSBundle mainBundle] loadNibNamed:reuseIdentifier owner:self options:nil];
            if (array!=nil)
            {
                deviceView=[array lastObject];
                CGRect r=deviceView.frame;
                r.origin.y=infoHeight;
                deviceView.frame=r;
                [self addSubview:deviceView];
                
            }
        }
        @catch (NSException *exception) {
            
        }
        
        
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
    [deviceInfo load:_device];
}

-(void)setDevice:(OznerDevice *)device
{
    deviceView.device=device;
    _device=device;
    _device.delegate=self;
    [self update];
}
@end
