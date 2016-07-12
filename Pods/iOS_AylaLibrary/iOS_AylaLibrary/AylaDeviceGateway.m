//
//  AylaDeviceGateway.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/11/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaDeviceGateway.h"
#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaDeviceSupport.h"
#import "AylaErrorSupport.h"
#import "AylaDeviceNode.h"
#import "AylaCacheSupport.h"
#import "AylaRegistration.h"
#import "AylaLanModeSupport.h"
#import "AylaNotify.h"
#import "AylaDeviceManager.h"
#import "AylaLanOperation.h"
#import "AylaConnectionOperationSupport.h"
#import "AylaLanCommandEntity.h"
#import "NSObject+AylaNetworks.h"
#import "AylaDefines_Internal.h"
#import "AylaLanMessage.h"
#import "AylaMessageResponse.h"
#import "NSString+AylaNetworks.h"
#import "AylaLanSession+Message.h"

@implementation AylaDeviceGateway

static NSString * const kAylaDeviceType = @"device_type";
static NSString * const kAylaGatewayType = @"gateway_type";

static NSString * const kAylaNodeType = @"node_type";

#pragma mark - init
//override
- (instancetype)initDeviceWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        [self updateWithDictionary:dictionary];
    }
    return self;
}

//override
- (void)updateWithDictionary:(NSDictionary *)deviceDictionary
{
    [super updateWithDictionary:deviceDictionary];
    NSDictionary *attributes = deviceDictionary[@"device"];
    self.gatewayType = [attributes objectForKey:kAylaGatewayType]?:nil;
}

+ (Class)deviceClassFromDeviceDictionary:(NSDictionary *)dictionary
{
    NSDictionary *attributes = dictionary[@"device"];
    Class deviceClass;
    if(attributes &&
       attributes[kAylaGatewayType]) {
        deviceClass = [AylaDeviceGateway deviceClassFromGatewayType:[attributes[kAylaGatewayType] nilIfNull]];
    }
    else if(attributes &&
            [kAylaDeviceTypeGateway isEqualToString:attributes[kAylaDeviceType]]) {
        deviceClass = [AylaDeviceGateway class];
    }
    return deviceClass?:[AylaDevice class];
}


//------------------------------ Gateway apis ---------------------------------
#pragma mark - gateway apis
- (NSOperation *)getNodes:(NSDictionary *)callParams
         success:(void (^)(AylaResponse *response, NSArray *nodes))successBlock
         failure:(void (^)(AylaError *err))failureBlock
{
    if(!self.key) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:@{kAylaDeviceTypeGateway: @"is invalid."}];
        failureBlock(error);
        return nil;
    }
    else if(!self.gatewayType) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:@{kAylaGatewayType: @"is invalid."}];
        failureBlock(error);
        return nil;
    }
    
    if(!self.nodes) {
        __unused BOOL retrievedFromCache = [self initNodesFromCache];
    }
    
    NSString *path = [NSString stringWithFormat:@"devices/%@/nodes.json", self.key];
    return [[AylaApiClient sharedDeviceServiceInstance] getPath:path parameters:nil
            success:^(AylaHTTPOperation *operation, id responseObject) {
                int i = 0;
                NSMutableDictionary *nodes = [NSMutableDictionary new];
                for(NSDictionary *nodeDictionary in responseObject) {
                    Class nodeClass = [AylaDeviceNode deviceClassFromDeviceDictionary:nodeDictionary];
                    AylaDeviceNode *node = [[nodeClass alloc] initDeviceWithDictionary:nodeDictionary];
                    if([node isKindOfClass:[AylaDeviceNode class]]){
                        node.gateway = self;
                        [nodes setObject:node forKey:node.dsn];
                    }
                    else {
                        NSDictionary *attributes = nodeDictionary[@"device"];
                        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaGateway", @"invalid node", attributes[@"dsn"], @"getNodes");
                    }
                    i++;
                }
                saveToLog(@"%@, %@, %@:%d, %@", @"I", @"AylaGateway", @"count", i, @"getNodes");
                [self updateNodesWithNodeList:nodes saveToCache:NO];
                
                [[AylaDeviceManager sharedManager] updateDevicesWithArray:nodes.allValues options:AylaDeviceManagerUpdateOptionSingleGatewayNodeList| AylaDeviceManagerUpdateOptionSaveToCache];
                
                successBlock(operation.response, nodes.allValues);
            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@:%ld, %@:%ld, %@", @"E", @"AylaGateway", @"NSError.code", (long)error.nativeErrorInfo.code, @"http", (long)operation.response.httpStatusCode, @"getNodes");
                error.errorCode = AML_AYLA_ERROR_FAIL;
                failureBlock(error);
            }];
}

- (void)updateNodesFromGlobalDeviceList:(NSArray *)devices
{
    NSMutableDictionary *nodes = [NSMutableDictionary new];
    [devices enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AylaDevice *device = obj;
        if([device isKindOfClass:[AylaDeviceNode class]]) {
            AylaDeviceNode *node = obj;
            if([node.gatewayDsn isEqualToString:self.dsn]) {
                node.gateway = self;
                [nodes setObject:node forKey:node.dsn];
            }
        }
    }];
    [self updateNodesWithNodeList:nodes saveToCache:YES];
}

//static final NSObject *nodesLock = [NSObject new];
- (void)updateNodesWithNodeList:(NSMutableDictionary *)nodes saveToCache:(BOOL)saveToCache
{
    if(!self.nodes) { self.nodes = nodes; }
    else {
        @synchronized(self.nodes) {
        //find one to be updated/ removed
            [self.nodes.allValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                AylaDeviceNode *node = obj;
                AylaDeviceNode *update = [nodes objectForKey:node.dsn];
                if(update) {
                    [self updateNode:node withNewNode:update];
                }
                else {
                    [self.nodes removeObjectForKey:node.dsn];
                }
            }];
            
            [nodes.allValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                AylaDeviceNode *update = obj;
                AylaDeviceNode *node = [self.nodes objectForKey:update.dsn];
                if(!node){
                    update.gateway = self;
                    [self.nodes setObject:update forKey:update.dsn];
                }
            }];
        };
    }
    if([AylaLanMode lanModeState] != DISABLED) {

        AylaDevice *device = [AylaLanMode device];
        if(device
           && [device isKindOfClass:[AylaDeviceGateway class]]
           && [device.dsn isEqualToString:self.dsn]
           && device != self) {
            AylaDeviceGateway *gateway = (AylaDeviceGateway *)device;
            [gateway updateNodesWithNodeList:[nodes mutableCopy] saveToCache:NO];
        }

        if(saveToCache) {
            [AylaCache save:AML_CACHE_NODE withIdentifier:self.dsn andObject:[nodes.allValues mutableCopy]];
        }
    }
}

- (void)updateNode:(AylaDeviceNode *)node withNewNode:(AylaDeviceNode *)update
{
    node.connectionStatus = update.connectionStatus;
    node.swVersion = update.swVersion;
    node.retrievedAt = update.retrievedAt;
}

- (BOOL)initNodesFromCache
{
    // Currently only use stored properties info to set default, would be deprecated later
    NSMutableArray *arr = [AylaCache get:AML_CACHE_NODE withIdentifier:self.dsn];
    
    // the properties have already been cached read it, otherwise go back to original steps
    if(arr){
        @synchronized(self.nodes){
            if(!self.nodes) {
                self.nodes = [NSMutableDictionary new];
            }
            
            for(AylaDeviceNode *node in arr){
                node.gateway = self;
                [self.nodes setValue:node forKey:node.dsn];
            }
        }
        
        saveToLog(@"%@, %@, %@, %@", @"I", @"AylaGateway", @"nodes", @"initNodesFromCache");
        return YES;
    }
    return NO;
}

//Light weight connection status request
- (NSOperation *)getNodesConnectionStatus:(NSDictionary *)callParams
                          success:(void (^)(AylaResponse *response, NSArray *connectionStatus))successBlock
                          failure:(void (^)(AylaError *err))failureBlock
{
    NSString * const kTextGatewayConnectionStatus = @"conn_status";

    // Currently only support up to 5 dsns in one command.
    const int maximumNodesInCommand = 5;
    
    if([self isLanModeActive]) {
        //in Lan Mode
        
        AylaDeviceGateway *managedCopy = (AylaDeviceGateway *)[self managedCopy];
        AylaLanSession *session = managedCopy.lanModule.session;
        NSArray *nodes = [[managedCopy nodes] allValues];
        
        if(nodes.count == 0) {
            AylaLanOperation *operation = [AylaLanOperation new];
            AylaResponse *resp = [AylaResponse new]; resp.httpStatusCode = 200;
            successBlock(resp, @[]);
            return operation;
        }
        
        NSString *source = [NSString stringWithFormat:@"%@%@", kTextGatewayConnectionStatus, AYLA_JSON_EXTENSION];

        NSMutableArray *commands = [NSMutableArray array];
        NSMutableArray *dsns = [NSMutableArray array];

        __block int totalCount;
        NSMutableArray *results = [NSMutableArray new];
        AylaLanCommandEntity *(^commandComposingBlock)(NSArray *dsns) = ^AylaLanCommandEntity *(NSArray *dsns) {
            NSError *error;
            NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"dsns":dsns} options:0 error:&error];
            NSString *dataInString =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (error) {
                saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaGateway", @"dsns", error.localizedDescription, @"getNodesConnectionStatus");
                return nil;
            }
            else {
                int cmdId = [session nextCommandOutstandingId];
                NSString *cmdStr = [managedCopy lanModeToDeviceCmdWithCmdId:cmdId messageType:AylaMessageTypeConnStatusGet requestMethod:AYLA_REQUEST_METHOD_GET sourceLink:source uri:[AylaLanPathNodePrefix stringByAppendingString:source] data:dataInString];

                AylaLanCommandEntity *cmd = [[AylaLanCommandEntity alloc] initWithParams:cmdId jsonString:cmdStr type:AYLA_LAN_COMMAND];
                [cmd setRespBlock:^(AylaLanCommandEntity *command, NSDictionary *resp, int status, AylaError *error) {
                    if(status >= 200 && status < 300) {
                        NSArray *connStatusArray = [resp objectForKey:@"connection"];
                        [results addObjectsFromArray:connStatusArray];
                        if(--totalCount == 0){
                            [command.parentOperation invokeCallbackBlockWithResponse:[AylaResponse new] responseObj:results error:nil];
                        }
                    }
                    else {
                        AylaError *error = [AylaError new];
                        error.httpStatusCode = status;
                        error.errorInfo = @{@"error" : [NSString stringWithFormat:@"Failed when retrieving conn_status %d", status]};
                        [command.parentOperation invokeCallbackBlockWithResponse:nil responseObj:nil error:error];
                    }
                }];
                return cmd;
            }
        };
        
        for(AylaDeviceNode *node in nodes) {
            [dsns addObject:node.dsn];
            if(dsns.count == maximumNodesInCommand) {
                AylaLanCommandEntity *cmd = commandComposingBlock(dsns);
                if(cmd) {
                    [commands addObject:cmd];
                }
                dsns = [NSMutableArray array];
            }
        }
        
        if(dsns.count > 0) {
            AylaLanCommandEntity *cmd = commandComposingBlock(dsns);
            if(cmd) {
                [commands addObject:cmd];
            }
        }
        
        totalCount = (int)commands.count;
        if(totalCount > 0) {
            AylaLanOperation *operation = [AylaLanOperation operationWithsubType:AylaLanOperationTypeCommand commands:commands callbackBlock:nil];
            // allocate more time for this operation request
            [operation setTimeoutInterval:[operation suggestedTimeoutInterval]];
            [operation setCallbackBlock:^(AylaResponse *response, id responseObj, AylaError *error) {
                if(!error) {
                    //success
                    NSArray *array = [self updateNodesConnStatusWithArray:responseObj toBeNotified:NO];
                    AylaResponse *resp = [AylaResponse new];
                    resp.httpStatusCode = AML_ERROR_ASYNC_OK;
                    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"AylaDeviceGateway", @"LAN", @"succeeded", @"getNodesConnectionStatus");
                    successBlock(resp, array);
                }
                else {
                    saveToLog(@"%@, %@, %@:%d, %@:%d, %@", @"E", @"AylaDeviceGateway", @"LAN", (int)error.httpStatusCode, @"code", (int)error.errorCode, @"getNodesConnectionStatus");
                    failureBlock(error);
                }
            }];
            
            if(![operation startOnSession:session]) {
                saveToLog(@"%@, %@, %@:%@, %@", @"E", @"Properties", @"LAN", @"FailedToStartOnSession", @"getNodesConnectionStatus");
            }
            return operation;
        }
        else {
            AylaError *error = [AylaError createWithCode:AML_ERROR_FAIL httpCode:400 nativeError:nil andErrorInfo:@{@"error": @"Failed to start on session"}];
            failureBlock(error);
            return [AylaLanOperation new];
        }
    }
    else {
        return
        [self getNodes:nil
            success:^(AylaResponse *response, NSArray *nodes) {
                NSMutableArray *connectionStatus = [NSMutableArray new];
                [nodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    AylaDeviceNode *node = obj;
                    if(node.dsn && node.connectionStatus) {
                        [connectionStatus addObject:@{
                                                      @"dsn": node.dsn?:@"",
                                                      @"status": node.connectionStatus
                                                      }];
                    }
                    else {
                        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaGateway", @"node", @"invalid node object", @"getNodesConnectionStatus");
                    }
                }];
                successBlock(response, connectionStatus);
            } failure:^(AylaError *err) {
                failureBlock(err);
            }];
    }
}

- (NSArray *)updateNodesConnStatusWithArray:(NSArray *)connStatusArray toBeNotified:(BOOL)toBeNotified
{
    static NSString *kTextConnectionStatusOnline = @"Online";
    static NSString *kTextConnectionStatusOffline = @"Offline";
    
    NSMutableArray *connectionStatus = [NSMutableArray array];
    [connStatusArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *connStatus = obj;
        NSString *status = [[connStatus objectForKey:@"status"] boolValue]? kTextConnectionStatusOnline: kTextConnectionStatusOffline;
        [connectionStatus addObject:@{
                              @"dsn": [connStatus objectForKey:@"dsn"],
                              @"status": status
                              }];
    }];
 
    if(toBeNotified &&
       connectionStatus.count > 0) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self incrementNotifyOutstandingCounter];
            NSDictionary *returnNotify = [AylaNotify initNotifyDictionaryWithType:AML_NOTIFY_TYPE_NODE dsn:self.dsn status:200 description:nil key:@"conn_status" values:connectionStatus];
            [AylaNotify returnNotify:returnNotify];
        });
    }
    
    return connectionStatus;
}

//---------------------------- enrollment apis -----------------------
#pragma mark - enrollment apis
- (NSOperation *)getCandidates:(NSDictionary *)callParams
                       success:(void (^)(AylaResponse *response, NSArray *candidates))successBlock
                       failure:(void (^)(AylaError *err))failureBlock
{
    if(!self.dsn) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:@{kAylaDeviceTypeGateway: @"is invalid."}];
        failureBlock(error);
        return nil;
    }
    
    return
    [AylaRegistration getRegistrationCandidatesWithDsn:self.dsn andRegistrationType:AML_REGISTRATION_TYPE_NODE params:callParams success:successBlock failure:failureBlock];
}

- (NSOperation *)registerCandidate:(AylaDeviceNode *)candidate
                         success:(void (^)(AylaResponse *response, AylaDevice *regiseredNode))successBlock
                         failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaRegistration registerDevice:candidate.dsn regToken:nil setupToken:nil success:successBlock failure:failureBlock];
}

//---------------------------- node pass-through apis --------------------------
#pragma mark - node pass-through apis
/**
 * It's better to have all node apis called here. 
 * NOTE All pass-through apis will first try to find the corresponding node/property from called gateway instance. Only when it can't be found, apis will use user input node/property object instead.
 */
- (NSOperation *)getNodePropertiesWithNode:(AylaDeviceNode *)requestNode
                                   params:(NSDictionary *)callParams
                           success:(void (^)(AylaResponse *response, NSArray *properties))successBlock
                           failure:(void (^)(AylaError *err))failureBlock
{
    // If node info was found in gateway object, use that object to send request. Otherwise use request node.
    AylaDeviceNode *node = [self findNodeWithDsn:requestNode.dsn]?:requestNode;
    if(!node) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                            httpCode:0
                                         nativeError:nil
                                        andErrorInfo:@{@"node": @"is invalid."}];
        failureBlock(error);
        return nil;
    }
    return [node getProperties:callParams success:successBlock failure:failureBlock];
}

- (NSOperation *)createNodeDatapoint:(AylaDatapoint *)datapoint
                              onNode:(AylaDeviceNode *)requestNode
                            property:(AylaProperty *)requestProperty
                             success:(void (^)(AylaResponse *response, AylaDatapoint *datapoint))successBlock
                             failure:(void (^)(AylaError *err))failureBlock
{
    // If node info was found in gateway object, use that object to send request. Otherwise use request node.
    AylaDeviceNode *node = [self findNodeWithDsn:requestNode.dsn]?:requestNode;
    if(!node) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                            httpCode:0
                                         nativeError:nil
                                        andErrorInfo:@{@"node": @"is invalid."}];
        failureBlock(error);
        return nil;
    }
    AylaProperty *property = [node findProperty:requestProperty.name]?:requestProperty;
    if(!property) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                            httpCode:0
                                         nativeError:nil
                                        andErrorInfo:@{@"property": @"is invalid."}];
        failureBlock(error);
        return nil;
    }
    return [property createDatapoint:datapoint success:successBlock failure:failureBlock];
}

- (NSOperation *)getDatapointsByActivity:(NSDictionary *)callParams
                              withNode:(AylaDeviceNode *)requestNode
                            property:(AylaProperty *)requestProperty
                             success:(void (^)(AylaResponse *response, NSArray *dataPoints))successBlock
                             failure:(void (^)(AylaError *err))failureBlock
{
    // If node info was found in gateway object, use that object to send request. Otherwise use request node.
    AylaDeviceNode *node = [self findNodeWithDsn:requestNode.dsn]?:requestNode;
    if(!node) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                            httpCode:0
                                         nativeError:nil
                                        andErrorInfo:@{@"node": @"is invalid."}];
        failureBlock(error);
        return nil;
    }
    AylaProperty *property = [node findProperty:requestProperty.name]?:requestProperty;
    if(!property) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                            httpCode:0
                                         nativeError:nil
                                        andErrorInfo:@{@"property": @"is invalid."}];
        failureBlock(error);
        return nil;
    }
    return [property getDatapointsByActivity:callParams success:successBlock failure:failureBlock];
}

- (AylaDeviceNode *)findNodeWithDsn:(NSString *)nodeDsn
{
    if(!self.nodes) {
        return nil;
    }
    if([self.nodes objectForKey:nodeDsn]) {
        return [self.nodes objectForKey:nodeDsn];
    }
    return nil;
}

- (BOOL)isGenericGateway
{
    return [[self.gatewayType nilIfNull] isEqualToString:kAylaGatewayTypeGeneric];
}

- (AylaDeviceNode *)findNodeWithMacAddress:(NSString *)macAddr
{
    for(AylaDeviceNode *node in self.nodes.allValues) {
        if([macAddr isEqualToString:node.mac]) {
            return node;
        }
    }
    return nil;
}

- (AylaDevice *)lanModeEdptFromDsn:(NSString *)dsn
{
    AylaDevice *device = nil;
    if([dsn isEqualToString:self.dsn]) {
        device = self;
    }
    else {
        device = [self findNodeWithDsn:dsn];
    }
    return device;
}

static NSString * const kAylaDeviceGatewayClassNameZigbee = @"AylaDeviceZigbeeGateway";
+ (Class)deviceClassFromGatewayType:(NSString *)gatewayType
{
    static Class AylaDeviceGatewayClassZigbee;
    static Class AylaDeviceGatewayClass;
    static Class AylaDeviceClass;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AylaDeviceClass = [AylaDevice deviceClassFromClassName:kAylaDeviceClassName];
        AylaDeviceGatewayClass = [AylaDevice deviceClassFromClassName:kAylaDeviceClassNameGateway];
        AylaDeviceGatewayClassZigbee = [AylaDevice deviceClassFromClassName:kAylaDeviceGatewayClassNameZigbee];
    });

    if(AylaDeviceGatewayClassZigbee &&
       gatewayType &&
       [gatewayType isEqualToString:kAylaGatewayTypeZigbee]) {
        return AylaDeviceGatewayClassZigbee;
    }
    return AylaDeviceGatewayClass;
}

//----------------------- Message handler -----------------------
- (AylaMessageResponse *)didReceiveMessage:(AylaMessage *)message
{
    return [super didReceiveMessage:message];
}

- (AylaMessageResponse *)handleLanMessage:(AylaLanMessage *)message
{
    AylaMessageResponse *resp;
    if(message.type == AylaMessageTypeDatapointAck) {
        resp = [super handleLanMessage:message];
    }
    else
    if([message.urlString AYLA_containsString:AylaLanPathNodePrefix]) {
        // handle node message update
        NSDictionary *data = [message.contents objectForKey:kAylaLanMessageParamData];
        switch (message.type) {
            case AylaMessageTypeConnStatusUpdate:
            {
                message.contents = data;
                if([message isCallback]) {
                    AylaLanSession *session = message.contextHandler;
                    resp = [session invokeOperationForMessage:message];
                }
                else {
                    [self updateNodesConnStatusWithArray:data[@"connection"] toBeNotified:YES];
                    resp = [AylaMessageResponse responseOfMessage:message httpStatusCode:AML_ERROR_ASYNC_OK];
                    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"AylaGateway", @"conn_sta", @"update", @"handleLanMessage");
                }
            }
            break;
            default:
            {
                AylaDeviceNode *node = [self findNodeWithDsn:data[@"dsn"]];
                if(node) {
                    resp = [node handleLanMessage:message];
                }
                else {
                    saveToLog(@"%@, %@, %@:%@, %@", @"W", @"AylaGateway", @"node", @"not found", @"handleLanMessage");
                    AylaLanSession *session = message.contextHandler;
                    resp = [session invokeOperationForMessage:message];
                }
            }
            break;
        }
    }
    
    if(!resp) {
        resp = [super handleLanMessage:message];
    }
    
    return resp;
}

//@override
- (void)lanModeDisable
{
    [super lanModeDisable];
    
    // Clean notify counters in all nodes.
    AylaDeviceGateway *copy = (AylaDeviceGateway *)[self managedCopy];
    for (AylaDeviceNode *node in copy.nodes.allValues) {
        [node resetNotifyOustandingCounter];
    }
}

//@override
- (NSInteger)lanModeWillSendCmdEntity:(AylaLanCommandEntity *)entity
{
    if(entity && entity.baseType == AYLA_LAN_NODE_PROPERTY){
        if(entity.tag == AylaMessageTypeDatapointUpdateWithAck) {
            return AML_ERROR_ASYNC_OK;
        }
        AylaLanSession *session = self.lanModule.session;
        NSString *strId = [NSString stringWithFormat:@"%d", entity.cmdId];
        AylaLanCommandEntity *command =  [session getOutstandingCommand:strId];
        [session removeOutstandingCommand:strId];
        
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_BEGIN
        AylaLanCommandRespBlock respBlock = command.respBlock;
        if(respBlock && ![command isCancelled]) {
            NSDictionary *re = [[NSDictionary alloc] initWithObjectsAndKeys:@"success", @"status",nil];
            command.respBlock(command, re, AML_ERROR_ASYNC_OK, nil);
        }
        AYLA_RUN_ASYNC_ON_MAIN_QUEUE_END
    }
    else {
        [super lanModeWillSendCmdEntity:entity];
    }

    return 200;
}

//--------------------caching helper methods----------------------

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_gatewayType forKey:@"gatewayType"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    AylaDeviceGateway *gateway = [super initWithCoder:decoder];
    gateway.gatewayType = [decoder decodeObjectForKey:@"gatewayType"];
    
    return gateway;
}

//--------------------------helpful methods----------------------------
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    if (copy) {
        AylaDeviceGateway *_copy = copy;
        _copy.gatewayType = [_gatewayType copy];
    }
    return copy;
}

@end

NSString * const kAylaGatewayTypeZigbee = @"Zigbee";
NSString * const kAylaGatewayTypeGeneric = @"Generic";

NSString * const kAylaDeviceGatewayRegWindowDuration = @"duration";
