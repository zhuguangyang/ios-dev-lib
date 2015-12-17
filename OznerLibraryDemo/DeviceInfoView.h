//
//  WaiterPurifierTableViewCell.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/15.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OznerManager.h"
@interface DeviceInfoView : UIStackView
{
    UILabel *NameLable;
    UILabel *IdLabel;
    UILabel *TypeLabel;
    UILabel *StatusLabel;
    UILabel *DescLabel;
    UILabel *SendStatus;
    
}
-(void) printSendStatus:(NSError*)error;
-(void) load:(OznerDevice*)device;
-(void)startSend;

@end
