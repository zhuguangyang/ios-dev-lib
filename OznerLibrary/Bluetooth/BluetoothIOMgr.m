//
//  BluetoothIOMgr.m
//  MxChip
//
//  Created by Zhiyongxu on 15/11/30.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "BluetoothIOMgr.h"
#import "ScanData.h"
#import "BluetoothSynchronizedObject.h"
#import "../Device/IOManager.hpp"
@implementation BluetoothIOMgr
- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    
}

-(void)applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
    
}

-(instancetype)init
{
    if (self=[super init])
    {
        [BluetoothSynchronizedObject initSynchronizedObject];
        const char *queueName = [@"bluetooth_queue" UTF8String];
        queue=dispatch_queue_create(queueName, NULL);
        centralManager=[[CBCentralManager alloc] initWithDelegate:self queue:queue];
        centralManager.delegate=self;
        addressList=[[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)scanThreadProc
{
    while (![[NSThread currentThread] isCancelled])
    {
        @synchronized([BluetoothSynchronizedObject synchronizedObject]) {
            if (!centralManager.isScanning)
            {
                [centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:UUID_Service]]
                                                       options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
                
            }
            sleep(2.0f);
            [centralManager stopScan];
        }
        sleep(1.0f);
    }
    NSLog(@"exit");
}

-(void)stopTimeScan
{
    [centralManager stopScan];
}


-(NSString*)getIdentifier:(CBPeripheral*)peripheral
{
    @synchronized(addressList) {
        NSString* identifier=[addressList objectForKey:[peripheral.identifier UUIDString]];
        if (!identifier)
        {
            return [peripheral.identifier UUIDString];
        }
        return identifier;
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString* name=[peripheral name];
    if (!name)
    {
        NSLog(@"found nil name");
    }
    ScanData* scanData;
    if ([advertisementData objectForKey:CBAdvertisementDataServiceDataKey])
    {
        NSDictionary* dict=[advertisementData objectForKey:CBAdvertisementDataServiceDataKey];
        CBUUID* uuid=[CBUUID UUIDWithString:@"FFF0"];
        NSData* data=[dict objectForKey:uuid];
        @try {
            scanData=[[ScanData alloc] init:data];
        }
        @catch (NSException *exception) {
            return;
        }
        
    }
    NSLog(@"found:%@",peripheral.name);
    if (scanData==nil)
    {
        if ([advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey])
        {
            if ([name isEqualToString:@"Ozner Cup"])
            {
                scanData=[[ScanData alloc] init:@"CP001" platform:@"C01" advertisement:[advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey]];
            }
        }else
            return ;
        
    }

    if (scanData)
    {
        BluetoothIO* io=(BluetoothIO*)[self getAvailableDevice:[self getIdentifier:peripheral]];
        if (!io)
        {
            io=[[BluetoothIO alloc] initWithPeripheral:peripheral Address:[self getIdentifier:peripheral] CentralManager:centralManager BluetoothData:scanData];
            @synchronized(addressList) {
                //设置mac和identifier uuid对应关系
                [addressList setObject:[NSString stringWithString:io.identifier] forKey:[peripheral.identifier UUIDString]];
            }
            io.name=peripheral.name;
        }
            
        [io updateScarnResponse:scanData.scanResponesType Data:scanData.scanResponesData];
        [self doAvailable:io];
    }
}



-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{

    BluetoothIO* io=(BluetoothIO*)[self getAvailableDevice:[self getIdentifier:peripheral]];
        NSLog(@"didConnectPeripheral:%@",io.identifier);
    [io updateConnectStatus:Connecting];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didDisconnectPeripheral:%@",[error debugDescription]);
    BluetoothIO* io=(BluetoothIO*)[self getAvailableDevice:[self getIdentifier:peripheral]];
    [io updateConnectStatus:Disconnect];
    [self doUnavailable:io];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"didFailToConnectPeripheral:%@",[error debugDescription]);
    BluetoothIO* io=(BluetoothIO*)[self getAvailableDevice:[self getIdentifier:peripheral]];
    [io updateConnectStatus:Disconnect];
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManpagerDidUpdateState Status:%d",(int)central.state);
    switch ([central state]) {
        case CBCentralManagerStatePoweredOn:
            if (!scanThread)
            {
                scanThread=[[NSThread alloc] initWithTarget:self selector:@selector(scanThreadProc) object:nil];
                [scanThread start];
            }
            break;
            
        case CBCentralManagerStatePoweredOff:
            if (scanThread)
            {
                [scanThread cancel];
                scanThread=nil;
            }
            break;
            
        case CBCentralManagerStateUnauthorized:
            break;
        case CBCentralManagerStateUnsupported:
            break;
        default:
            break;
    }
}

@end
