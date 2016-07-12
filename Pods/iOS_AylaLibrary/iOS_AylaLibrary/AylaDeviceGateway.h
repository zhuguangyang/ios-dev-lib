//
//  AylaDeviceGateway.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/11/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaDevice.h"
@class AylaDeviceNode;
@interface AylaDeviceGateway : AylaDevice

@property (strong, nonatomic) NSString *gatewayType; // Describes the GW type: Zigbee, Zwave, BLE, etc
@property (strong, nonatomic) NSMutableDictionary *nodes; // Nodes associated with this gateway

+ (Class)deviceClassFromDeviceDictionary:(NSDictionary *)dictionary;

/**
 * Get one or more gateway nodes from the Ayla Cloud Service. If the application has been LAN Mode enabled,
 * the nodes are read from cache, rather than the Ayla field service.
 * @param callParams Not required.
 * @param successBlock Block which would be called with array of nodes when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getNodes:(NSDictionary *)callParams
                  success:(void (^)(AylaResponse *response, NSArray *nodes))successBlock
                  failure:(void (^)(AylaError *err))failureBlock;


/**
 * Get one or more gateway nodes connection status from the Ayla Cloud Service. 
 * @note This is a LME api.
 * @param callParams Not required.
 * @param successBlock Block which would be called with an array of nodes when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getNodesConnectionStatus:(NSDictionary *)callParams
                                  success:(void (^)(AylaResponse *response, NSArray *connectionStatus))successBlock
                                  failure:(void (^)(AylaError *err))failureBlock;

/**
 * Pass-through method to get node properties. This api is recommanded for gateway solutions.
 * @note This is a LME api.
 * @param requestNode The node to be requested
 * @param callParams follows callParams requirements as in api getProperties:success:failure: .
 * @param successBlock Block which would be called with an array of nodes when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getNodePropertiesWithNode:(AylaDeviceNode *)requestNode
                                    params:(NSDictionary *)callParams
                                   success:(void (^)(AylaResponse *response, NSArray *properties))successBlock
                                   failure:(void (^)(AylaError *err))failureBlock;

/**
 * Pass-through method to create datapoint for a node property. This api is recommanded for gateway solutions.
 * @note This is a LME api.
 * @param datapoint is the datapoint to be created.
 * @param requestNode The node to requested.
 * @param requestProperty The property new datapoint would be created to.
 * @param successBlock Block which would be called with created datapoint when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)createNodeDatapoint:(AylaDatapoint *)datapoint
                              onNode:(AylaDeviceNode *)requestNode
                            property:(AylaProperty *)requestProperty
                             success:(void (^)(AylaResponse *response, AylaDatapoint *datapoint))successBlock
                             failure:(void (^)(AylaError *err))failureBlock;

/**
 * Pass-through method to get datapoints for a node property. This api is recommanded for gateway solutions.
 * @note This is a LME api.
 * @param callParams follows callParams requirements as in api getDatapointsByActivity:success:failure: .
 * @param requestNode The node to be requested.
 * @param requestProperty The property where datapoints to be retrieved.
 * @param successBlock Block which would be called with an array of datapoints when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getDatapointsByActivity:(NSDictionary *)callParams
                                withNode:(AylaDeviceNode *)requestNode
                                property:(AylaProperty *)requestProperty
                                 success:(void (^)(AylaResponse *response, NSArray *dataPoints))successBlock
                                 failure:(void (^)(AylaError *err))failureBlock;

/**
 * Get registrable candidates.
 * @param callParams callParams:
 *  @p kAylaRegistrationParamWindowLength : <NSNumber *> Length of time window to be tracked back. This param is in minutes. By default, this value is set to be 5.
 * @param successBlock Block which would be called with an array of candidates when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getCandidates:(NSDictionary *)callParams
                       success:(void (^)(AylaResponse *response, NSArray *candidates))successBlock
                       failure:(void (^)(AylaError *err))failureBlock;

/**
 * Register a candidate to user account.
 * @param candidate The candidate to be registered.
 * @param successBlock Block which would be called with the registered candidate when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)registerCandidate:(AylaDeviceNode *)candidate
                           success:(void (^)(AylaResponse *response, AylaDevice *regiseredNode))successBlock
                           failure:(void (^)(AylaError *err))failureBlock;


/**
 * Helpful methods to find node based on the input mac address. Api will go though gateway.nodes to find the match one.
 * @param macAddr is the mac address of the node.
 * @return node which matches the input mac address. Is nil when node could not be found.
 */
- (AylaDeviceNode *)findNodeWithMacAddress:(NSString *)macAddr;

/**
 * Helpful methods to find node based on the input node dsn. Api will go though gateway.nodes to find the match one.
 * @param nodeDsn dsn of the node.
 * @return node which matches the input dsn. Is nil when node could not be found.
 */
- (AylaDeviceNode *)findNodeWithDsn:(NSString *)nodeDsn;

/**
 * Helpful method to check if current gateway is a generic gateway.
 * @return YES if this gateway supports generic gateway solution.
 */
- (BOOL)isGenericGateway;

@end

extern NSString * const kAylaGatewayTypeZigbee;
extern NSString * const kAylaGatewayTypeGeneric;

extern NSString * const kAylaDeviceGatewayRegWindowDuration;