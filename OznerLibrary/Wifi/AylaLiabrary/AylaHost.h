//
//  AylaHost.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/22/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"

@interface AylaHost: NSObject 

+ (void) connectToNewDevice:
                    /*success:*/(void (^)(AylaResponse *response, AylaModule *newDevice))successBlock
                    failure:(void (^)(AylaError *err))failureBlock;
+ (NSString *) returnHostNetworkConnection;
+ (Boolean) matchDeviceSsidRegex: (NSString *)ssid;
+ (Boolean) isNewDeviceConnected;

@end
