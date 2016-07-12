//
//  AylaDeviceNode.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/11/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaDevice.h"
@class AylaDeviceGateway;
@interface AylaDeviceNode : AylaDevice

/** Node Type */
@property (strong, nonatomic) NSString *nodeType;

/** Gateway DSN */
@property (strong, nonatomic) NSString *gatewayDsn;
@property (weak, nonatomic) AylaDeviceGateway *gateway;

@property (strong, nonatomic) NSString *address;

+ (Class)deviceClassFromDeviceDictionary:(NSDictionary *)dictionary;

/**
 * Used to identify a node by blinking a light, making a sound, vibrating, etc
 *
 * @param callParams have two options
 *   WHEN set a indentify request:
 *   @p kAylaDeviceNodeParamIdentifyValue - may have a corresponding value of kAylaDeviceNodeParamIdentifyOn or kAylaDeviceNodeParamIdentifyOff
 *   @p kAylaDeviceNodeParamIdentifyTime - <NSNumber *>should have corresponding value from 0 to 255 in seconds
 *   WHEN get result:
 *   @p kAylaDeviceNodeParamIdentifyValue - should be set to kAylaDeviceNodeParamIdentifyResult.
 * @param success would be called with response when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @Return
 * 		NSOperation for this request
 * @note possbile result:
 *     {"id":"12345"} for the "On" and "Off" option, or
 *     {"id":"on_0x123456789abc","status":"success"} for the "Result" option
 *
 *      possible error:
 * 		401 - Unauthorized
 * 		404 - Node not found
 * 		405 - Not supported for this node
 */
- (NSOperation *)identifyWithParams:(NSDictionary *)callParams
                   success:(void (^)(AylaResponse *response, NSDictionary *responseParams))successBlock
                   failure:(void (^)(AylaError *err))failureBlock;

/**
 * Helpful method to check if current node is a generic node.
 * @return YES if this gateway supports generic gateway solution.
 */
- (BOOL)isGenericNode;

@end

extern NSString * const kAylaNodeTypeZigbee;
extern NSString * const kAylaNodeTypeGeneric;

extern NSString * const kAylaDeviceNodeParamIdentifyValue;
extern NSString * const kAylaDeviceNodeParamIdentifyTime;
extern NSString * const kAylaDeviceNodeParamIdentifyOn;
extern NSString * const kAylaDeviceNodeParamIdentifyOff;
extern NSString * const kAylaDeviceNodeParamIdentifyResult;

extern NSString * const kAylaDeviceNodeParamIdentifyId;
extern NSString * const kAylaDeviceNodeParamIdentifyStatus;