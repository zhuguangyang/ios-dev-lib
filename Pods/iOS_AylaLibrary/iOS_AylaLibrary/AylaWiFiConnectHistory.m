//
//  AylaWiFiConnectHistory.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/25/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaWiFiConnectHistory.h"

@implementation AylaWiFiConnectHistory

@synthesize ssidInfo = _ssidInfo;
@synthesize bssid = _bssid;
@synthesize error = _error;
@synthesize msg = _msg;
@synthesize mtime = _mtime;
@synthesize ipAddr = _ipAddr;
@synthesize netmask = _netmask;
@synthesize defaultRoute = _defaultRoute;
@synthesize dnsServers = _dnsServers;

- (id) initWiFiConnectionHistoryWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self){
        _ssidInfo= [dictionary valueForKeyPath:@"ssid_info"];
        _bssid = [dictionary valueForKeyPath:@"bssid"];
        _error = [dictionary valueForKeyPath:@"error"];
        _msg = [dictionary valueForKeyPath:@"msg"];
        _mtime = [dictionary valueForKeyPath:@"mtime"];
        _ipAddr = [dictionary valueForKeyPath:@"ip_addr"];
        _netmask = [dictionary valueForKeyPath:@"netmask"];
        _defaultRoute = [dictionary valueForKeyPath:@"default_route"];        
        _dnsServers = [[NSMutableArray alloc] initWithArray:[dictionary valueForKeyPath:@"dns_servers"]];
    }
    return self;
}

@end
