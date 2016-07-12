//
//  AylaModuleScanResults.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/23/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaModuleScanResults : NSObject

@property (nonatomic, copy) NSString *ssid;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSNumber *chan;
@property (nonatomic, copy) NSNumber *signal;
@property (nonatomic, copy) NSNumber *bars;
@property (nonatomic, copy) NSString *security;
@property (nonatomic, copy) NSString *bssid;

- (id) initModuleScanResultWithDictionary: (NSDictionary *)dictionary;

@end
