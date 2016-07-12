//
//  AylaReachabilitySupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 3/20/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaReachability(Support)

+(void) register:(void (^)(NSDictionary *)) rhandler;

+(BOOL) isInternetReachable;
+(BOOL) isWiFiEnabled;

//mDNS discovery
+(void) getDeviceIpAddressWithHostName: (NSString *)deviceHostName
                           resultBlock:(void(^)(NSString *, NSString*))resultBlock;

+(BOOL) isDeviceReachabilityExpired;
+(void) setIsDeviceReachabilityExpired:(BOOL) _isReachable;

+(BOOL) isServiceReachabilityExpired;
+(void) setIsServiceReachabilityExpired:(BOOL) _isReachable;

+(void) setDeviceReachability:(int) reachable;
+(void) setConnectivity:(int) reachable;

@end
