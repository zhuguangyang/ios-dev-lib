//
//  BluetoothIO.h
//  MxChip
//
//  Created by Zhiyongxu on 15/11/30.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../Device/BaseDeviceIO.h"
#import "ScanData.h"
#import <CoreBluetooth/CoreBluetooth.h>



@interface BluetoothIO : BaseDeviceIO<CBPeripheralDelegate>
{
    NSThread* runThread;
    CFRunLoopRef loop;
    CBPeripheral* peripheral;
    CBCharacteristic* input;
    CBCharacteristic* output;
    CBCentralManager * centralManager;
}

-(instancetype)initWithPeripheral:(CBPeripheral*)Peripheral Address:(NSString*)address
                   CentralManager:(CBCentralManager *)CentralManager BluetoothData:(ScanData *)scanData;
@property (nonnull,strong,readonly) NSDate* firmwareVersion;
@property (nonnull,copy,readonly) NSString* Platform;
@property (nonatomic,readonly) int scanResponseType;
@property (nonatomic,strong,readonly,nullable) NSData* scanResponseData;
-(BOOL)runJob:(nonnull SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait;
-(void)updateScarnResponse:(int)type Data:(nullable NSData*)data;
-(void)updateConnectStatus:(enum ConnectStatus)status;
@end
