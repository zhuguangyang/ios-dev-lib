//
//  AylaWifiStatus.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/25/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"

@implementation AylaWiFiStatus
@synthesize dsn = _dsn;
@synthesize deviceService = _deviceService;
@synthesize mac = _mac;
@synthesize ant = _ant;
@synthesize rssi = _rssi;
@synthesize bars = _bars;
@synthesize connectHistory =_connectHistory;

- (id) initWiFiStatusWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self){
         _dsn= [dictionary valueForKeyPath:@"dsn"];
        _mac = [dictionary valueForKeyPath:@"mac"];
        _deviceService = [dictionary valueForKeyPath:@"device_service"];
        _ant = [dictionary valueForKeyPath:@"ant"];
        _rssi = [dictionary valueForKeyPath:@"rssi"];
        _bars = [dictionary valueForKeyPath:@"bars"];

        _connectHistory = [[NSMutableArray alloc] init];
        if( [dictionary valueForKeyPath:@"connect_history"] != [NSNull null]){
            NSArray* arr = [dictionary valueForKeyPath:@"connect_history"];
                for(NSDictionary *history in arr){
                    AylaWiFiConnectHistory *connHistory = [[AylaWiFiConnectHistory alloc] initWiFiConnectionHistoryWithDictionary:history];
                    [_connectHistory addObject:connHistory];
                }
        }
    }
    return self;
}
@end
