//
//  OznerManager.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/2.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "OznerManager.h"

#import "Tap/TapManager.h"
#import "Cup/CupManager.h"
#import "WaterPurifier/WaterPurifierManager.h"

#import "Helper/Helper.h"


@implementation OznerManager

OznerManager* oznerManager=nil;

+(instancetype)instance
{
    if (!oznerManager)
    {
        oznerManager=[[OznerManager alloc] init];
    }
    return oznerManager;
}

-(NSString*)getOwnerTableName
{
    return [NSString stringWithFormat:@"A%@",[Helper md5:owner]];
}

-(instancetype)init
{
    if (self=[super init])
    {
        db=[[SqlLiteDB alloc] init:@"ozner" Version:1];
        devices=[[NSMutableDictionary alloc] init];
        _ioManager=[[IOManagerList alloc] init];
        _ioManager.bluetooth.delegate=self;
        deviceMgrList=[NSArray arrayWithObjects:
                       [[CupManager alloc] init],
                       [[TapManager alloc] init],
                       [[WaterPurifierManager alloc] init],
                       nil];
        
        oznerManager=self;
    }
    return self;
}
-(void)closeAll
{
    [self.ioManager closeAll];
}
-(void)setOwner:(NSString *)aOwner
{
    if (!aOwner) return;
    
    self->owner=[[NSString stringWithString:aOwner] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    @synchronized(devices) {
        [devices removeAllObjects];
    }
    [self closeAll];
    
    NSString* sql=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (identifier VARCHAR PRIMARY KEY NOT NULL,Type Text NOT NULL,JSON TEXT)",[self getOwnerTableName]];
    [db ExecSQLNonQuery:sql params:nil];
    [self.delegate OznerManagerDidOwnerChanged:self->owner];
    [self loadDevices];
    
}
-(OznerDevice*)getDevice:(NSString*)identifier;
{
    @synchronized(devices) {
        return [devices objectForKey:identifier];
    }
}


-(OznerDevice*)getDeviceByIO:(BaseDeviceIO*)io
{
    OznerDevice* device=nil;
    @synchronized(devices) {
        device=[devices objectForKey:io.identifier];
        if (device) return device;
    }

    for (BaseDeviceManager* mgr in deviceMgrList)
    {
        if ([mgr isMyDevice:io.type])
        {
            device=[mgr loadDevice:io.identifier Type:io.type Settings:@""];
            return device;
        }
    }
    return NULL;
}

-(NSArray*)getDevices
{
    @synchronized(devices) {
        return [NSArray arrayWithArray:[devices allValues]];
    }
}

-(NSArray*)getNotBindDevices
{
    NSMutableArray *array=[[NSMutableArray alloc] init];
    NSArray* list=[_ioManager getAvailableDevices];
    @synchronized(devices) {
        for (BaseDeviceIO* io in list)
        {
            if (![devices objectForKey:io.identifier])
            {
                [array addObject:io];
            }
        }
    }
    return array;
}

-(void)save:(OznerDevice *)device
{
    if (!devices) return;
    if (StringIsNullOrEmpty(owner)) return;
    bool isNew=false;
    
    @synchronized(devices) {
        if ([devices objectForKey:device.identifier]==NULL)
        {
            [devices setObject:device forKey:device.identifier];
            isNew=true;
        }else
            isNew=false;
    }
    NSString* sql=[NSString stringWithFormat:@"INSERT OR REPLACE INTO %@(identifier,Type,JSON) VALUES (?,?,?);",
                   [self getOwnerTableName]];
    [db ExecSQLNonQuery:sql params:[NSArray arrayWithObjects:device.identifier,device.type,[device.settings toJSON], nil]];
    
    [device updateSettings];
    if (isNew)
        [self.delegate OznerManagerDidAddDevice:device];
    else
        [self.delegate OznerManagerDidUpdateDevice:device];
}
-(void)loadDevices
{
    NSString* sql=[NSString stringWithFormat:@"select identifier,Type,JSON from %@",[self getOwnerTableName]];
    NSArray* arrays=[db ExecSQL:sql params:nil];
    @synchronized(devices) {
        for (NSArray* row in arrays)
        {
            NSString* identifier=[row objectAtIndex:0];
            NSString* type=[row objectAtIndex:1];
            NSString* json=[row objectAtIndex:2];
            for (BaseDeviceManager* mgr in deviceMgrList)
            {
                OznerDevice* device=[mgr loadDevice:identifier Type:type Settings:json];
                if (device)
                {
                    [devices setObject:device forKey:identifier];
                    
                    BaseDeviceIO* io=[_ioManager getAvailableDevice:identifier];
                    @try {
                        if (io)
                        {
                            [device bind:io];
                        }
                    }
                    @catch (NSException *exception) {
                        NSLog(@"exception:%@",[exception debugDescription]);
                    }
                }
            }
        }
    }
}
-(void)remove:(OznerDevice*)device
{
    @synchronized(devices) {
        if ([devices objectForKey:device.identifier]==NULL)
            return;
    }
    
    NSString* sql=[NSString stringWithFormat:@"delete form %@ where identifier=?",[self getOwnerTableName]];
    [db ExecSQLNonQuery:sql params:[NSArray arrayWithObjects:device.identifier, nil]];
    @synchronized(devices) {
        [devices removeObjectForKey:device.identifier];
    }
    [device bind:nil];
    [self.delegate OznerManagerDidRemoveDevice:device];
}

-(BOOL)checkisBindMode:(BaseDeviceIO*)io
{
    for (BaseDeviceManager* mgr in deviceMgrList)
    {
        if ([mgr isMyDevice:io.type])
        {
            return [mgr checkBindMode:io];
        }
    }
    return false;
}
-(void)IOManager:(IOManager *)ioManager Available:(BaseDeviceIO *)io
{
    if (io)
    {
        OznerDevice* device=nil;
        @synchronized(devices) {
            device=[devices objectForKey:io.identifier];
        }
        if (device)
        {
            [device bind:io];
        }else
        {
            [self performSelectorOnMainThread:@selector(doDidFoundDevice:) withObject:io waitUntilDone:true];
        }
    }
}
-(void)doDidFoundDevice:(BaseDeviceIO*)io;
{
    [self.delegate OznerManagerDidFoundDevice:io];
}

-(void)IOManager:(IOManager *)ioManager Unavailable:(BaseDeviceIO *)io
{
    NSLog(@"Unavailable:%@",[io description]);
    if (io)
    {
        OznerDevice* device=nil;
        @synchronized(devices) {
            device=[devices objectForKey:io.identifier];
        }
        if (device)
        {
            [device bind:nil];
        }
    }
}
@end