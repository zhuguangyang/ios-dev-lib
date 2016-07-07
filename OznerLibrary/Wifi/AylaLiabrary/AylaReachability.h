//
//  AylaReachability.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/11/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaReachability : NSObject

/**
 * This asynchronous method determines reachability status for the current service. Asynchronous results
   are returned to the registered reachabilityHandle. Handler.
 */
+ (void)determineReachability;

/**
 * @deprecate Deprecated. Will always return AML_REACHABILITY_REACHABLE unless WiFi is not enabled.
 */
+ (void)determineDeviceReachabilityWithBlock:(void(^)(int))block DEPRECATED_ATTRIBUTE;

/**
 * This method is used to asynchronously determine reachability to Device. Once new reachability is determined, block would be called with reachability status message.
 */
+ (void)determineDeviceReachability:(AylaDevice *)device completionBlock:(void(^)(int reachability))completionBlock;

/**
 * This method is used to asynchronously determine reachability to Service. Once new reachability is determined, block would be called with reachability status message.
 */
+ (void)determineServiceReachabilityWithBlock:(void(^)(int))block;

/**
 * @deprecate Deprecated. Will always return AML_REACHABILITY_REACHABLE.
 */
+ (int)getDeviceReachability DEPRECATED_ATTRIBUTE;

/**
 * This real-time method returns the current status for service reachability
 */
+ (int)getConnectivity;

/**
 * @deprecate Deprecated. Will always return Service reachability.
 */
+ (int)getReachability DEPRECATED_ATTRIBUTE;

@end
