//
//  BluetoothIOMgr.h
//  MxChip
//
//  Created by Zhiyongxu on 15/11/30.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "../Device/IOManager.h"
#import "BluetoothIO.h"
#define UUID_Service @"FFF0"
#define UUID_CHAR_INPUT @"FFF2"
#define UUID_CHAR_OUTPUT @"FFF1"
#define UUID_DESC_CLINET_CFG @"2902"

@interface BluetoothIOMgr : IOManager<CBCentralManagerDelegate>
{
    bool bleScaning;
    CBCentralManager * centralManager;
    dispatch_queue_t queue;
    NSThread* scanThread;
    NSMutableDictionary* addressList;
}
-(instancetype)init;

@end
