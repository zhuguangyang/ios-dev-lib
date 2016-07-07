//
//  AylaDiscovery.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 3/6/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaNetworks.h"
@interface AylaDiscovery : NSObject

+ (void) getDeviceIpAddressWithHostName: (NSString *)deviceHostName timeout:(float)timeout
                        andResultBlock:(void(^)(NSString *lanIp, NSString *deviceHostName))resultBlock;
+ (void) cancelDiscovery;

@end
