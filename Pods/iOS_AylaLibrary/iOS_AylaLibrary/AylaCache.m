//
//  AylaCache.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 8/29/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "AylaSystemUtilsSupport.h"
#import <zlib.h>

@implementation AylaCache

static NSString * const AML_CACHE_LAN_CONFIG_PREFIX = @"lanConfig_";
static NSString * const AML_CACHE_DEVICE_PREFIX = @"allDevices";
static NSString * const AML_CACHE_PROPERTY_PREFIX = @"properties_";
static NSString * const AML_CACHE_NODE_PREFIX = @"nodes_";
static NSString * const AML_CACHE_SETUP_PREFIX = @"newDeviceConnected";
static NSString * const AML_CACHE_GROUP_PREFIX = @"";

static NSMutableDictionary *crcMap = nil;
static int caches = 0xFF;
+ (BOOL)cachingEnabled
{
    return (caches != 0x00);
}

+ (BOOL)cachingEnabled:(NSInteger)selection
{
    return (caches & selection) == selection;
}

+ (void)enable:(NSInteger)cachesToSet
{
    caches |= cachesToSet;
}

+ (void)disable:(NSInteger)cachesToDisable
{
    caches &= ~cachesToDisable;
}

+ (void)clearAll
{
    [AylaCache clear:AML_CACHE_ALL];
}

+ (NSInteger)caches
{
    return caches;
}

+ (void)clear:(NSInteger)cachesToClear
{
    NSFileManager *manager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *en = [manager enumeratorAtPath:[AylaSystemUtils deviceArchiversFilePath]];
    NSString *fileObj;
    
    saveToLog(@"%@, %@, %@: %d, %@", @"I", @"AylaCache", @"called", caches, @"clear");
    while(fileObj=[en nextObject]){
        if(([fileObj rangeOfString:AML_CACHE_LAN_CONFIG_PREFIX].location != NSNotFound && ((cachesToClear & AML_CACHE_LAN_CONFIG)!=0x00)) ||
           ([fileObj rangeOfString:AML_CACHE_PROPERTY_PREFIX].location != NSNotFound && ((cachesToClear & AML_CACHE_PROPERTY)!=0x00)) ||
           ([fileObj rangeOfString:AML_CACHE_NODE_PREFIX].location != NSNotFound && ((cachesToClear & AML_CACHE_NODE)!=0x00)) ||
           ([fileObj isEqualToString:@"AylaDevicesArchiver.arch"] && ((cachesToClear & AML_CACHE_DEVICE)!=0x00)) ||
           ([fileObj isEqualToString:@"newDeviceConnected.arch"] && ((cachesToClear & AML_CACHE_SETUP)!=0x00))){
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:[[AylaSystemUtils deviceArchiversFilePath] stringByAppendingPathComponent:fileObj] error:&error];
            if(error){
                saveToLog(@"%@, %@, %@:%ld, %@", @"E", @"AylaCache", @"errCode", (long)error.code, @"clear");
            }
            
            if ([fileObj isEqualToString:@"AylaDevicesArchiver.arch"])
                [crcMap removeObjectForKey:AML_CACHE_DEVICE_PREFIX];
            if ([fileObj isEqualToString:@"newDeviceConnected.arch"])
                [crcMap removeObjectForKey:AML_CACHE_SETUP_PREFIX];
            else
                [crcMap removeObjectForKey:[fileObj substringWithRange:NSMakeRange(0, fileObj.length - 5)]]; // - ".arch"
        }
    }
}

+ (void)clear:(NSInteger)cachesToClear withParams:(NSDictionary *)params
{
    NSFileManager *manager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *en = [manager enumeratorAtPath:[AylaSystemUtils deviceArchiversFilePath]];
    NSString *fileObj;
    NSString *fileName = nil;
    
    if((cachesToClear & AML_CACHE_PROPERTY) != 0) {
        fileName = AML_CACHE_PROPERTY_PREFIX;
        if(params && params[kAylaCacheParamDeviceDsn]) {
            NSString *dsn = params[kAylaCacheParamDeviceDsn];
            fileName = [NSString stringWithFormat:@"%@%@", AML_CACHE_PROPERTY_PREFIX, dsn];
        }
    }

    saveToLog(@"%@, %@, %@: %@, %@", @"I", @"AylaCache", @"called", fileName, @"clear");
    if(fileName) {
        while(fileObj=[en nextObject]){
            if([fileObj rangeOfString:fileName].location != NSNotFound ){
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:[[AylaSystemUtils deviceArchiversFilePath] stringByAppendingPathComponent:fileObj] error:&error];
                if(error){
                    saveToLog(@"%@, %@, %@:%ld, %@", @"E", @"AylaCache", @"errCode", (long)error.code, @"clear");
                }
                if ([fileObj isEqualToString:@"AylaDevicesArchiver.arch"])
                    [crcMap removeObjectForKey:AML_CACHE_DEVICE_PREFIX];
                if ([fileObj isEqualToString:@"newDeviceConnected.arch"])
                    [crcMap removeObjectForKey:AML_CACHE_SETUP_PREFIX];
                else
                    [crcMap removeObjectForKey:[fileObj substringWithRange:NSMakeRange(0, fileObj.length - 5)]]; // - ".arch"
            }
        }
    }
}

+ (id)get:(AML_CACHE)cacheType
{
    NSString *id = nil;
    switch (cacheType) {
        case AML_CACHE_DEVICE:
            id = AML_CACHE_DEVICE_PREFIX;
            break;
        case AML_CACHE_SETUP:
            id = AML_CACHE_SETUP_PREFIX;
            break;
        case AML_CACHE_PROPERTY:
        case AML_CACHE_LAN_CONFIG:
        case AML_CACHE_NODE:
        case AML_CACHE_GROUP:
        default:
            break;
    }
    
    if(id){
        return [AylaCache loadCache:id];
    }
    return nil;
}

+ (id)get:(AML_CACHE)cacheType withIdentifier:(NSString *)uniqueId
{
    NSString *id = nil;
    switch (cacheType) {
        case AML_CACHE_DEVICE:
        case AML_CACHE_SETUP:
            break;
        case AML_CACHE_PROPERTY:
            id = [NSString stringWithFormat:@"%@%@", AML_CACHE_PROPERTY_PREFIX, uniqueId];
            break;
        case AML_CACHE_LAN_CONFIG:
            id = [NSString stringWithFormat:@"%@%@", AML_CACHE_LAN_CONFIG_PREFIX, uniqueId];
            break;
        case AML_CACHE_NODE:
            id = [NSString stringWithFormat:@"%@%@", AML_CACHE_NODE_PREFIX, uniqueId];
            break;
        case AML_CACHE_GROUP:
        default:
            break;
    }
    
    if(id){
        return [AylaCache loadCache:id];
    }
    return nil;
}

+ (BOOL)save:(AML_CACHE)cacheType withObject:(id)values
{
    if(![AylaCache cachingEnabled:cacheType]) {
        return NO;
    }
    
    NSString *id = nil;
    switch (cacheType) {
        case AML_CACHE_DEVICE:
            id = AML_CACHE_DEVICE_PREFIX;
            break;
        case AML_CACHE_SETUP:
            id = AML_CACHE_SETUP_PREFIX;
            break;
        case AML_CACHE_PROPERTY:
        case AML_CACHE_LAN_CONFIG:
        case AML_CACHE_NODE:
        case AML_CACHE_GROUP:
        default:
            break;
    }
    if(id){
        return [AylaCache saveCache:id object:values];
    }
    return NO;
}

+ (BOOL)save:(AML_CACHE)cacheType withIdentifier:(NSString *)uniqueId andObject:(NSMutableArray *)values
{
    if(![AylaCache cachingEnabled:cacheType]) {
        return NO;
    }

    NSString *id = nil;
    switch (cacheType) {
        case AML_CACHE_DEVICE:
        case AML_CACHE_SETUP:
            break;
        case AML_CACHE_PROPERTY:
            id = [NSString stringWithFormat:@"%@%@", AML_CACHE_PROPERTY_PREFIX, uniqueId];
            break;
        case AML_CACHE_LAN_CONFIG:
            id = [NSString stringWithFormat:@"%@%@", AML_CACHE_LAN_CONFIG_PREFIX, uniqueId];
            break;
        case AML_CACHE_NODE:
            id = [NSString stringWithFormat:@"%@%@", AML_CACHE_NODE_PREFIX, uniqueId];
            break;
        case AML_CACHE_GROUP:
        default:
            break;
    }
    
    if(id){
        return [AylaCache saveCache:id object:values];
    }
    return NO;
}


+ (id)loadCache:(NSString *)name
{
    if([name isEqualToString:AML_CACHE_DEVICE_PREFIX]){
        if((caches & AML_CACHE_DEVICE) == 0x00) {
            return nil;
        }
        id root = [NSKeyedUnarchiver unarchiveObjectWithFile:[AylaSystemUtils devicesArchiversFilePath]];
        if(root == NULL) return nil;
        NSMutableDictionary *devices = root;
        return devices;
    }
    else if(([name rangeOfString:AML_CACHE_LAN_CONFIG_PREFIX].location!= NSNotFound && ((caches & AML_CACHE_LAN_CONFIG)!= 0x00)) ||
            ([name rangeOfString:AML_CACHE_PROPERTY_PREFIX].location!= NSNotFound && ((caches & AML_CACHE_PROPERTY)!= 0x00)) ||
            ([name rangeOfString:AML_CACHE_NODE_PREFIX].location!= NSNotFound && ((caches & AML_CACHE_NODE)!= 0x00)) ){
        //saveToLog(@"I, Settings, Path:%@\n", [NSString stringWithFormat:@"%@/%@%@",_deviceArchiverFilePath, name, @".arch"]);
        id root = [NSKeyedUnarchiver unarchiveObjectWithFile: [NSString stringWithFormat:@"%@/%@%@",[AylaSystemUtils deviceArchiversFilePath], name, @".arch"]];
        return root == NULL? nil: root;
    }
    else if([name isEqualToString:AML_CACHE_SETUP_PREFIX] && ((caches & AML_CACHE_SETUP)!= 0x00)){
        id root = [NSKeyedUnarchiver unarchiveObjectWithFile: [NSString stringWithFormat:@"%@/%@%@",[AylaSystemUtils deviceArchiversFilePath], name, @".arch"]];
        return root == NULL? nil: root;
    }
    return nil;
}

+ (BOOL)saveCache:(NSString *)name object:(NSMutableArray *)values
{
    if(!crcMap) {
        crcMap = [NSMutableDictionary new];
    }
    
    if(!values && [crcMap objectForKey:name]) {
        [crcMap removeObjectForKey:name];
    }
    
    NSUInteger newCrc = crc32(0L, NULL, 0);
    if(values) {
        NSData *data = [[values description] dataUsingEncoding:NSUTF8StringEncoding];
        newCrc =  crc32(newCrc,  data.bytes, (uInt)data.length);
        if([crcMap objectForKey:name]) {
            NSUInteger crc = ((NSNumber *)[crcMap objectForKey:name]).unsignedIntegerValue;
            if(crc == newCrc) {
                return YES;
            }
            
        }
    }
    
    
    if(values == nil){  // Delete cache
        if([name isEqualToString:AML_CACHE_DEVICE_PREFIX]){
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:[AylaSystemUtils devicesArchiversFilePath] error:&error];
            if(error && error.code != 4){
                saveToLog(@"I, Settings, saveSetting, error: %@, Fail", error);
                return FAIL;
            }
        }
        else if ([name rangeOfString:AML_CACHE_LAN_CONFIG_PREFIX].location!= NSNotFound ||
                 [name rangeOfString:AML_CACHE_PROPERTY_PREFIX].location!= NSNotFound ||
                 [name rangeOfString:AML_CACHE_NODE_PREFIX].location!= NSNotFound) {
            //saveToLog(@""I, Settings, Path:%@\n", [NSString stringWithFormat:@"%@/%@%@",_deviceArchiverFilePath, name, @".arch"]);
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@%@",[AylaSystemUtils deviceArchiversFilePath], name, @".arch"] error:&error];
            if(error && error.code != 4){
                saveToLog(@"I, Settings, saveSetting, error: %@, Fail", error);
                return FAIL;
            }
        }
        else if ([name isEqualToString:AML_CACHE_SETUP_PREFIX]) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@%@",[AylaSystemUtils deviceArchiversFilePath], name, @".arch"] error:&error];
            if(error && error.code != 4){
                saveToLog(@"I, Settings, saveSetting, error: %@, Fail", error);
                return FAIL;
            }
        }
        return SUCCESS;
    }
    else {
        [crcMap setObject:[NSNumber numberWithUnsignedInteger:newCrc] forKey:name];
        if([name isEqualToString:AML_CACHE_DEVICE_PREFIX]){
            /*
            if((caches & AML_CACHE_DEVICE) == 0x00) {
                return FAIL;
            }
            */
            [NSKeyedArchiver archiveRootObject:(NSMutableArray *)values toFile:[AylaSystemUtils devicesArchiversFilePath]];
            return SUCCESS;
        }
        else if([name rangeOfString:AML_CACHE_LAN_CONFIG_PREFIX].location!= NSNotFound ||
                [name rangeOfString:AML_CACHE_PROPERTY_PREFIX].location!= NSNotFound ||
                [name rangeOfString:AML_CACHE_NODE_PREFIX].location!= NSNotFound){
            /*
            if((caches & AML_CACHE_LAN_CONFIG) == 0x00 && [name rangeOfString:AML_CACHE_LAN_CONFIG_PREFIX].location!= NSNotFound) {
                return FAIL;
            }
            if((caches & AML_CACHE_PROPERTY) == 0x00 && [name rangeOfString:AML_CACHE_PROPERTY_PREFIX].location!= NSNotFound) {
                return FAIL;
            }
            */
            //saveToLog(@"I, Settings, Path:%@\n", [NSString stringWithFormat:@"%@/%@%@",_deviceArchiverFilePath, name, @".arch"]);
            [NSKeyedArchiver archiveRootObject:values toFile:[NSString stringWithFormat:@"%@/%@%@",[AylaSystemUtils deviceArchiversFilePath], name, @".arch"]];
            return SUCCESS;
        }
        else if([name isEqualToString:AML_CACHE_SETUP_PREFIX]){
            /*
            if((caches & AML_CACHE_SETUP) == 0x00) {
                return FAIL;
            }
            */
            [NSKeyedArchiver archiveRootObject:values toFile:[NSString stringWithFormat:@"%@/%@%@",[AylaSystemUtils deviceArchiversFilePath], name, @".arch"]];
            return SUCCESS;
        }
    }
    return FAIL;
}
@end

NSString * const kAylaCacheParamDeviceDsn = @"dsn";