//
//  AylaDeviceManager.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/20/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaDeviceManager.h"
#import <UIKit/UIKit.h>
#import "AylaDevice.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceNode.h"
#import "AylaDeviceSupport.h"
#import "AylaCache.h"
#import "AylaCacheSupport.h"
#import "AylaDefines_Internal.h"
#import "NSObject+AylaNetworks.h"
@interface AylaDeviceManager () {
    NSLock *_listLock;
    NSLock *_backgroundLock;
    BOOL _isLanModeRecorded;
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
}

@property (strong, nonatomic) NSMutableDictionary *lanIpLookUpBook;

@property (strong, nonatomic) NSArray *lastEnabledDeviceList;

@end

static const NSTimeInterval DefaultBackgroundTimerInterval = 30;

@implementation AylaDeviceManager

+ (instancetype)sharedManager
{
    static AylaDeviceManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[AylaDeviceManager alloc] init];
    });
    return shared;
}

- (id)init
{
    self = [super init];
    if(!self) return nil;
    
    _listLock = [[NSLock alloc] init];
    _backgroundLock = [[NSLock alloc] init];
    _devices = [NSMutableDictionary dictionary];
    _lanIpLookUpBook = [NSMutableDictionary dictionary];
    
    [self _setAllFromCache];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    return self;
}

- (void)_setAllFromCache
{
    NSArray *cachedDevices = [AylaCache get:AML_CACHE_DEVICE];
    
    //setup each device
    for (AylaDevice *device in cachedDevices) {
        if([device isKindOfClass:[AylaDeviceGateway class]]) {
            
            NSString *dsn = device.dsn;
            NSArray *cachedNodes = [AylaCache get:AML_CACHE_NODE withIdentifier:dsn];
            
            [self _updateDevice:device associativeObj:nil];
            
            [self _updateDevicesWithArray:cachedNodes options:AylaDeviceManagerUpdateOptionSingleGatewayNodeList];
            
        }
        else if([device isKindOfClass:[AylaDeviceNode class]]) {
            //skip
        }
        else {
            [self _updateDevice:device associativeObj:nil];
        }
    }
}

- (NSArray *)bufferedDeviceList
{
    return [_devices allValues];
}

- (NSArray *)copyOfBufferedDeviceList
{
    NSMutableArray *copiedList = [NSMutableArray array];
    for(AylaDevice *device in _devices.allValues) {
        
        if([device isKindOfClass:[AylaDeviceGateway class]]) {
            AylaDeviceGateway *copiedDevice = (AylaDeviceGateway *)[device copy];
            copiedDevice.nodes = [NSMutableDictionary dictionary];
            [copiedList addObject:copiedDevice];
            
            for(AylaDeviceNode *node in [(AylaDeviceGateway *)device nodes].allValues) {
                AylaDeviceNode *copiedNode = [node copy];
                [copiedDevice.nodes setObject:copiedNode forKey:copiedNode.dsn];
                [copiedList addObject:copiedNode];
            }
        }
    }
    return copiedList;
}

- (AylaDevice *)deviceWithDsn:(NSString *)dsn
{
    return [self deviceWithDsn:dsn recursiveCheck:NO];
}

- (AylaDevice *)deviceWithDsn:(NSString *)dsn recursiveCheck:(BOOL)recursiveCheck
{
    AylaDevice *device = nil;
    [_listLock lock];
    device = [self _deviceWithDsn:dsn recursiveCheck:recursiveCheck];
    [_listLock unlock];
    return device;
}

- (AylaDevice *)_deviceWithDsn:(NSString *)dsn
{
    return [self _deviceWithDsn:dsn recursiveCheck:NO];
}

- (AylaDevice *)_deviceWithDsn:(NSString *)dsn recursiveCheck:(BOOL)recursiveCheck
{
    AylaDevice *device = nil;
    
    if(dsn) {
        
        if(!recursiveCheck) {
            device = [_devices objectForKey:dsn];
        }
        else {
            NSArray *lanDevices = [_devices allValues];
            AylaDevice *endpoint = nil;
            for (AylaDevice *dev in lanDevices) {
                endpoint = [dev lanModeEdptFromDsn:dsn];
                if(endpoint) {
                    device = endpoint;
                    break;
                }
            }
        }
    }
    
    return device;
}

- (AylaDevice *)deviceWithLanIp:(NSString *)lanIp
{
    NSString *dsn = [_lanIpLookUpBook objectForKey:lanIp];
    return [self deviceWithDsn:dsn];
}

- (BOOL)addDevice:(AylaDevice *)device skipUpdate:(BOOL)skipUpdate
{
    NSAssert(![device isKindOfClass:[AylaDeviceNode class]], @"Must add top level devices to organizer.");
    if(skipUpdate) {
        //Only update device if this device is not showing in list
        [_listLock lock];
        
        AylaDevice *buffered = [self.devices objectForKey:device.dsn];
        if(!buffered) {
            AylaDeviceNode *copy = (AylaDeviceNode *)[device copy];
            [_devices setObject:copy forKey:[device.dsn copy]];
            [self initializeDevice:copy];
        }
        [_listLock unlock];
    }
    else {
        [self updateDevice:device];
    }
    return YES;
}

- (BOOL)updateDevice:(AylaDevice *)device;
{
    [_listLock lock];
    
    [self _updateDevice:device associativeObj:nil];
    
    [_listLock unlock];
    return YES;
}

- (BOOL)updateDevice:(AylaDevice *)device options:(AylaDeviceManagerUpdateOption)options
{
    [_listLock lock];
    
    [self _updateDevice:device associativeObj:nil];
    
    [_listLock unlock];
    return YES;
}

- (BOOL)_updateDevice:(AylaDevice *)device associativeObj:(id)object
{
    AylaDevice *buffered = nil;
    if([device isKindOfClass:[AylaDeviceNode class]]) {
        AylaDeviceGateway *gateway = object;
        if(!gateway) gateway = (AylaDeviceGateway *)[self _deviceWithDsn:[(AylaDeviceNode *)device gatewayDsn]];
        if(gateway) {
            
            buffered = [gateway.nodes objectForKey:device.dsn];
            if(!buffered) {
                if(!gateway.nodes) gateway.nodes = [NSMutableDictionary dictionary];
                else if([device.mac nilIfNull] &&
                        [gateway.gatewayType isEqualToString:kAylaGatewayTypeZigbee]) {
                    // Fix an issue in zigbee solution: there is a possbility that incoming device
                    // is a copy of the one buffered in lib but with a new dsn assigned from cloud.
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.mac == %@", device.mac];
                    NSArray *matchedDevices = [gateway.nodes.allValues filteredArrayUsingPredicate:predicate];
                    
                    // Remove all matched devices from nodes list
                    [self _removeDevices:matchedDevices];
                }
                
                AylaDeviceNode *copy = (AylaDeviceNode *)[device copy];
                [gateway.nodes setObject:copy forKey:[device.dsn copy]];
                [self initializeDevice:copy];
                copy.gateway = gateway;
            }
            else {
                [buffered updateWithCopy:device];
            }
        }
    }
    else {
        buffered = [self _deviceWithDsn:device.dsn];
        if(!buffered) {
            AylaDevice *copy = [device copy];
            [_devices setObject:[device copy] forKey:[device.dsn copy]];
            [self initializeDevice:copy];
        }
        else {
            [buffered updateWithCopy:device];
        }
    }
    
    [self updateLanIp:device.lanIp ForDevice:device.dsn];
    return YES;
}

- (void)removeDevices:(NSArray *)devices
{
    if(devices.count > 0) {
        [_listLock lock];
        [self _removeDevices:devices];
        [_listLock unlock];
    }
}

- (void)_removeDevices:(NSArray *)devices
{
    [devices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([obj isKindOfClass:[AylaDeviceNode class]]){
            AylaDeviceNode *node = (AylaDeviceNode *)obj;
            AylaDeviceGateway *gw = (AylaDeviceGateway *)[self _deviceWithDsn:node.gatewayDsn];
            [gw.nodes removeObjectForKey:node.dsn];
        }
        else {
            AylaDevice *device = obj;
            [self.devices removeObjectForKey:device.dsn];
        }
    }];
}

- (void)updateLanIp:(NSString *)lanIp ForDevice:(NSString *)dsn
{
    if(lanIp) {
        AylaDevice *found = self.devices[dsn];
        found.lanIp = lanIp;
        
        [self.lanIpLookUpBook setObject:dsn forKey:lanIp];
    }
}

- (void)initializeDevice:(AylaDevice *)device
{
    //Do a lan mode check for input device
    if(!device.properties) {
        [device initPropertiesFromCache];
    }
}

- (void)updateDevicesWithArray:(NSArray *)deviceArray options:(AylaDeviceManagerUpdateOption)options
{
    [_listLock lock];
    
    [self _updateDevicesWithArray:deviceArray options:options];
    
    [_listLock unlock];
}

- (void)_updateDevicesWithArray:(NSArray *)deviceArray options:(AylaDeviceManagerUpdateOption)options
{
    if(!deviceArray) return;
    
    BOOL doNodeUpdateWithGateway = NO;
    AylaDeviceGateway *gateway = nil;
    
    if((options & AylaDeviceManagerUpdateOptionSingleGatewayNodeList) != 0 &&
       deviceArray.count > 0) {
        
        //retrieve first node
        AylaDeviceNode *node = deviceArray[0];
        NSAssert([node isKindOfClass:[AylaDeviceNode class]], @"Must input node array when has option AylaDeviceManagerUpdateOptionSingleGatewayNodeList");
        
        gateway = self.devices[node.gatewayDsn];
        
        if(gateway) {
            doNodeUpdateWithGateway = YES;
        }
    }
    
    for(AylaDevice *device in deviceArray) {
        
        // Check if device class has been modified for input device
        AylaDevice *buffered = [self _deviceWithDsn:device.dsn recursiveCheck:YES];
        if(buffered &&
           [buffered class] != [device class]) {
            // directly remove the buffered version
            [self _removeDevices:@[buffered]];
        }
        
        if(doNodeUpdateWithGateway) {
            [self _updateDevice:device associativeObj:gateway];
        }
        else if([device isKindOfClass:[AylaDeviceGateway class]]) {
            
            // update gateway
            [self _updateDevice:device associativeObj:nil];
            
            if((options & AylaDeviceManagerUpdateOptionIncludeNodeListInGateway) != 0) {
                //update node list in gateway
                [self _updateDevicesWithArray:[(AylaDeviceGateway *)device nodes].allValues options:AylaDeviceManagerUpdateOptionSingleGatewayNodeList];
            }
        }
        else if ([device isKindOfClass:[AylaDeviceNode class]]) {
            
            if((options & AylaDeviceManagerUpdateOptionSkipTopLevelNodes) == 0) {
                //node to be updated
                [self _updateDevice:device associativeObj:nil];
            }
        }
        else {
            [self _updateDevice:device associativeObj:nil];
        }
        
    }
    
    if((options & AylaDeviceManagerUpdateOptionSaveToCache) != 0)
        [AylaCache save:AML_CACHE_DEVICE withObject:deviceArray];
    
}

- (void)closeAllSessions
{
    [AylaLanMode closeAllSessions];
}

- (void)resetFromCache:(BOOL)fromCache
{
    [self closeAllSessions];
    [_listLock lock];
    
    _devices = [NSMutableDictionary dictionary];
    _lanIpLookUpBook = [NSMutableDictionary dictionary];
    if(fromCache) [self _setAllFromCache];
    
    [_listLock unlock];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, devices: %@>", NSStringFromClass([self class]), self, self.devices];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
- (void)appDidBecomeActive:(NSNotification *)notification
{
    [self stopBackgroundTask];
    [self restoreLanModeIfNecessary];
}

- (void)appDidEnterBackground:(NSNotification *)notification
{
    [self startBackgroundTask];
}

- (void)startBackgroundTask
{
    AYLAssert([NSThread isMainThread], @"deviceManager.startBackgroudTasks must be called from main thread.");
    NSTimeInterval delay = DefaultBackgroundTimerInterval;
    
    // End current background task and redo a new one.
    if(_backgroundTaskIdentifier != 0) [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];

    void(^expirationHandler)() = ^(){
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(backgroundTimerHandler)
                                                   object:nil];
        [self recordAndDisableLanModeIfNecessary];
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = 0;
    };
    
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if([[UIApplication sharedApplication] respondsToSelector:@selector(beginBackgroundTaskWithName:expirationHandler:)]) {
        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"com.aylanetworks.deviceManager.bgTask"
                                                                                 expirationHandler:expirationHandler];
    }
    else {
        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:expirationHandler];
    }
#else
    _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:expirationHandler];
#endif
    
    // Schedule a lan mode selector with delay
    [self performSelector:@selector(backgroundTimerHandler)
               withObject:nil
               afterDelay:delay];

}

- (void)stopBackgroundTask
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(backgroundTimerHandler)
                                               object:nil];
    if(_backgroundTaskIdentifier != 0) {
        AylaLogD(@"DeviceManager", 0, @"canceled bg timers. task %ld", _backgroundTaskIdentifier);
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = 0;
    }
}

- (void)backgroundTimerHandler
{
    [self recordAndDisableLanModeIfNecessary];
    [self stopBackgroundTask];
}

- (void)recordAndDisableLanModeIfNecessary
{
    [_backgroundLock lock];
    if([AylaLanMode isEnabled]) {
        _isLanModeRecorded = YES;
        NSMutableArray *array = [NSMutableArray array];
        for(AylaDevice *device in self.devices.allValues) {
            if([device.lanModule.session isTimerOn]) {
                [array addObject:device.dsn];
            }
        }
        _lastEnabledDeviceList = array;
        AylaLogD(@"DeviceManager", 0, @"recorded devices:%@, %@", _lastEnabledDeviceList, @"recordLanMode");
    }
    [AylaLanMode disable];
    [_backgroundLock unlock];
}

- (void)restoreLanModeIfNecessary
{
    [_backgroundLock lock];
    if(_isLanModeRecorded) {
        [AylaLanMode enable];
        for (NSString *dsn in _lastEnabledDeviceList) {
            AylaDevice *lanDevice = [self deviceWithDsn:dsn];
            [lanDevice lanModeEnable];
        }
        _isLanModeRecorded = NO;
        AylaLogD(@"DeviceManager", 0, @"restored devices:%@, %@", _lastEnabledDeviceList, @"restoreLanMode");
    }
    [_backgroundLock unlock];
}

@end
