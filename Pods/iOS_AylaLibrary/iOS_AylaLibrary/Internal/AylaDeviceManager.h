//
//  AylaDeviceManager.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/20/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AylaLanCommandEntity;
@class AylaDevice;
typedef NS_OPTIONS(int, AylaDeviceManagerUpdateOption) {
    AylaDeviceManagerUpdateOptionNone = 0x00,
    AylaDeviceManagerUpdateOptionSkipTopLevelNodes = 0x01, //Skip showing nodes in the list
    AylaDeviceManagerUpdateOptionSingleGatewayNodeList = 0x02, //Input is a node list of a gateway
    AylaDeviceManagerUpdateOptionIncludeNodeListInGateway = 0x04, //Also update with each gateway.nodes
    AylaDeviceManagerUpdateOptionSaveToCache = 0x08 //Save to cache
};

@class AylaLanModule;
@interface AylaDeviceManager : NSObject

@property (strong, readonly, nonatomic) NSMutableDictionary *devices;

+ (instancetype)sharedManager;

- (AylaDevice *)deviceWithDsn:(NSString *)dsn;
- (AylaDevice *)deviceWithDsn:(NSString *)dsn recursiveCheck:(BOOL)recursiveCheck;

- (AylaDevice *)deviceWithLanIp:(NSString *)lanIp;

- (NSArray *)bufferedDeviceList;
- (NSMutableArray *)copyOfBufferedDeviceList;

- (BOOL)addDevice:(AylaDevice *)device skipUpdate:(BOOL)skipUpdate;
- (BOOL)updateDevice:(AylaDevice *)device;
- (void)removeDevices:(NSArray *)devices;

/**
 * Helpful method to update buffered devices with device array and options.
 * @note Param deviceArray has to be following indicated options.<br/><br/> Corner case: When pass in a combined nodes/gateways/devices list and AylaDeviceManagerUpdateOptionSkipTopLevelNodes is not set. Make sure gateways are showing before nodes in the list.
 */
- (void)updateDevicesWithArray:(NSArray *)deviceArray options:(AylaDeviceManagerUpdateOption)options;

- (void)updateLanIp:(NSString *)lanIp ForDevice:(NSString *)dsn;

- (void)resetFromCache:(BOOL)fromCache;

@end