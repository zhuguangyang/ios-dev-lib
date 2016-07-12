//
//  AylaWifiStatus.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/25/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AylaWiFiConnectHistory;
@interface AylaWiFiStatus : NSObject

@property (nonatomic, copy) NSString *dsn;
@property (nonatomic, copy) NSString *deviceService;
@property (nonatomic, copy) NSString *mac;
@property (nonatomic, copy) NSNumber *ant;
@property (nonatomic, copy) NSNumber *rssi;
@property (nonatomic, copy) NSNumber *bars;
@property (nonatomic, copy) NSMutableArray *connectHistory;

- (id) initWiFiStatusWithDictionary:(NSDictionary *)dictionary;

@end
