//
//  AylaModuleScanResults.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/23/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaModuleScanResults.h"

@implementation AylaModuleScanResults

@synthesize ssid = _ssid;
@synthesize type = _type;
@synthesize chan = _chan;
@synthesize signal = _signal;
@synthesize bars = _bars;
@synthesize security = _security;
@synthesize bssid = _bssid;

- (id)initModuleScanResultWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self){
        _ssid = [dictionary valueForKeyPath:@"ssid"];
        _type = [dictionary valueForKeyPath:@"type"];
        _chan = [dictionary valueForKeyPath:@"chan"];
        _signal = [dictionary valueForKeyPath:@"signal"];
        _bars = [dictionary valueForKeyPath:@"bars"];
        _security = [dictionary valueForKeyPath:@"security"];
        _bssid = [dictionary valueForKeyPath:@"bssid"];
    }
    return self;
}

@end
