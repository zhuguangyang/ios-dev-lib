//
//  AylaWiFiConnectHistory.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/25/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaWiFiConnectHistory : NSObject

@property (nonatomic, copy) NSString *ssidInfo;
@property (nonatomic, copy) NSString *bssid;
@property (nonatomic, copy) NSNumber *error;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, copy) NSNumber *mtime;
@property (nonatomic, copy) NSString *ipAddr;
@property (nonatomic, copy) NSString *netmask;
@property (nonatomic, copy) NSString *defaultRoute;
@property (nonatomic, copy) NSArray *dnsServers;

- (id) initWiFiConnectionHistoryWithDictionary: (NSDictionary *)dictionary;
@end
