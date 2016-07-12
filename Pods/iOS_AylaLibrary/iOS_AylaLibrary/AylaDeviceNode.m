//
//  AylaDeviceNode.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/11/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaDeviceNode.h"
#import "AylaDevice.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceSupport.h"
#import "AylaSystemUtils.h"
#import "AylaNetworks.h"
#import "AylaError.h"
#import "AylaErrorSupport.h"
#import "NSObject+AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaDeviceSupport.h"
#import "AylaDeviceManager.h"
#import "AylaLanModeSupport.h"
#import "AylaLanMessage.h"
#import "AylaSystemUtilsSupport.h"
#import "NSString+AylaNetworks.h"

@implementation AylaDeviceNode : AylaDevice

static NSString * const kAylaDeviceType = @"device_type";
static NSString * const kAylaNodeType = @"node_type";

static NSString * const kAylaNodeParamGatewayDsn = @"gateway_dsn";

//override
- (instancetype)initDeviceWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        [self updateWithDictionary:dictionary];
        
        //TODO: SKIP because returned values are always null. check properties when init a new node instance, needs to be lan mode enabled
        /*
        dictionary =
        dictionary[@"device"]? dictionary[@"device"]: dictionary;
        
        NSArray *properties = [dictionary objectForKey:@"properties"];
        if(properties) {
            NSMutableDictionary *nodeProperties = [NSMutableDictionary dictionary];
            for(NSDictionary *propertyDictionary in properties) {
                AylaProperty *property = [[AylaProperty alloc] initDevicePropertyWithDictionary:propertyDictionary];
                if(property && property.name) {
                    [nodeProperties setObject:property forKey:property.name];
                }
            }
            self.properties = nodeProperties;
        }
        */
    }
    return self;
}

- (NSOperation *)identifyWithParams:(NSDictionary *)callParams
                   success:(void (^)(AylaResponse *response, NSDictionary *responseParams))successBlock
                   failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    NSMutableDictionary *params = [NSMutableDictionary new];
    if(!callParams) {
        [errors setObject:@"can not be blank." forKey:@"callParams"];
    }
    else {
        NSString *value = callParams[kAylaDeviceNodeParamIdentifyValue];
        if(value) {
            if([value isEqualToString:kAylaDeviceNodeParamIdentifyOn]) {
                
                NSNumber *duration = callParams[kAylaDeviceNodeParamIdentifyTime];
                if(duration &&
                   [duration isKindOfClass:[NSNumber class]]) {
                    [params setObject:duration forKey:kAylaDeviceNodeParamIdentifyTime];
                }
                else {
                    [errors setObject:@"can not be blank." forKey:kAylaDeviceNodeParamIdentifyTime];
                }
            }
            params[kAylaDeviceNodeParamIdentifyValue] = value;
        }
        else {
            [errors setObject:@"can not be blank." forKey:kAylaDeviceNodeParamIdentifyValue];
        }
    }
    if(errors.count > 0) {
        failureBlock([AylaError createWithCode:AML_AYLA_ERROR_FAIL httpCode:0 nativeError:nil andErrorInfo:errors]);
        return nil;
    }

    NSString *path = [NSString stringWithFormat:@"devices/%@/identify.json", self.key];
    saveToLog(@"%@, %@, %@:%@, %@:%@, %@", @"I", @"AylaNode", @"url", path, @"userValues", callParams, @"identifyWithParams");
    return
    [[AylaApiClient sharedDeviceServiceInstance] putPath:path parameters:params
                                                        success:^(AylaHTTPOperation *operation, id responseObject) {
                                                            successBlock(operation.response, responseObject);
                                                        } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                            saveToLog(@"%@, %@, %@, %@", @"E", @"AylaNode", error.logDescription,  @"identifyWithParams");
                                                            failureBlock(error);
                                                        }];
}

- (BOOL)isGenericNode
{
    return [[self.nodeType nilIfNull] isEqualToString:kAylaNodeTypeGeneric];
}

//override
- (void)updateWithDictionary:(NSDictionary *)deviceDictionary
{
    [super updateWithDictionary:deviceDictionary];
    NSDictionary *attributes = deviceDictionary[@"device"];
    self.nodeType = [[attributes objectForKey:kAylaNodeType] nilIfNull];
    self.gatewayDsn = [[attributes objectForKey:kAylaNodeParamGatewayDsn] nilIfNull];
    self.address = [[attributes objectForKey:@"address"] nilIfNull];
}

+ (Class)deviceClassFromDeviceDictionary:(NSDictionary *)dictionary
{
    NSDictionary *attributes = dictionary[@"node"]?:dictionary[@"device"];
    Class deviceClass;
    if(attributes &&
       attributes[kAylaNodeType]) {
        deviceClass = [AylaDeviceNode deviceClassFromNodeType:[attributes[kAylaNodeType] nilIfNull]];
    }
    else if(attributes &&
            [kAylaDeviceTypeNode isEqualToString:attributes[kAylaDeviceType]]) {
        deviceClass = [AylaDeviceNode class];
    }
    return deviceClass?:[AylaDevice class];
}

static NSString * const kAylaDeviceNodeClassNameZigbee = @"AylaDeviceZigbeeNode";
+ (Class)deviceClassFromNodeType:(NSString *)nodeType
{
    static Class AylaDeviceNodeClassZigbee;
    static Class AylaDeviceNodeClass;
    static Class AylaDeviceClass;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AylaDeviceClass = [AylaDevice deviceClassFromClassName:kAylaDeviceClassName];
        AylaDeviceNodeClass = [AylaDevice deviceClassFromClassName:kAylaDeviceClassNameNode];
        AylaDeviceNodeClassZigbee = [AylaDevice deviceClassFromClassName:kAylaDeviceNodeClassNameZigbee];
    });
    
    if(AylaDeviceNodeClassZigbee &&
       nodeType &&
       [nodeType isEqualToString:kAylaNodeTypeZigbee]) {
        return AylaDeviceNodeClassZigbee;
    }
    return AylaDeviceNodeClass;
}

//override
- (void)lanModeEnable
{
    saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaDeviceNode", @"lanMode", @"add lan mode implementation on gateway level", @"lanModeEnable");
}

//override
- (void)lanModeDisable
{
    saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaDeviceNode", @"lanMode", @"add lan mode implementation on gateway level", @"lanModeEnable");
}

//@override
- (BOOL)isLanModeActive
{
    AylaDeviceNode *lanDevice = (AylaDeviceNode *)[self managedCopy];
    if(lanDevice
       && [lanDevice properties]
       && [lanDevice.gateway isLanModeActive]
       ) {
        return YES;
    }
    return NO;
}

//override
- (enum lanModeSession)lanModeState
{
    AylaDevice *lanGateway = [[AylaDeviceManager sharedManager] deviceWithDsn:self.gatewayDsn];
    return lanGateway.lanModule.session.sessionState;
}

//override
- (NSString *)lanModeToDeviceCmdWithCmdId:(int)cmdId messageType:(AylaMessageType)messageType requestMethod:(NSString *)method sourceLink:(NSString *)sourceLink uri:(NSString *)uri data:(NSString *)data
{
    // Generic Gateway specific commands
    NSString * const AylaLocalNodePropertyUri = [NSString stringWithFormat:@"%@%@%@", AylaLanPathLocalLanPrefix, AylaLanPathNodePrefix, AylaLanPathDatapoint];
    switch (messageType) {
        case AylaMessageTypePropertyGet:
            sourceLink = [@"node_" stringByAppendingString:sourceLink];
            uri = AylaLocalNodePropertyUri;
            if(self.dsn) {
                data = [NSString stringWithFormat:@"{\"dsn\":\"%@\"}", self.dsn];
            }
            else {
                saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaDeviceNode", @"dsn", @"is missing", @"lanModeToDeviceCmdWithCmdId");
            }
            break;
        default:
            break;
    }
    
    return [AylaLanMode buildToDeviceCommand:method cmdId:cmdId resourse:sourceLink data:data uri:uri];
}

//override
- (NSString *)lanModeToDeviceUpdateWithCmdId:(int)cmdId property:(AylaProperty *)property valueString:(NSString *)valueString
{
    NSString *jsonString = nil;
    if(!property.owner) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"AylaDeviceNode", @"dsn", @"is missing", @"lanModeToDeviceUpdateWithCmdId");
        return @"";
    }
    
//    NSDictionary *message = @{
//                              @"property" : @{
//                                      @"name" : property.name?:[NSNull null],
//                                      @"value" : [AylaSystemUtils jsonEscapedStringFromString:valueString],
//                                      @"base_type": property.baseType?:[NSNull null],
//                                      @"id" : (optional, based on the "needs ack" template attribute)
//                                      }
//                              };
    
    NSString *escapedValueString = [property.baseType isEqualToString:@"string"]? [NSString stringWithFormat:@"\"%@\"", [AylaSystemUtils jsonEscapedStringFromString:valueString]]: valueString;
    NSString *metadataInString = [AylaSystemUtils stringFromJsonObject:property.metadata]?:@"{}";
    NSMutableString *optionalParamsInString = [NSMutableString new];
    if(property.ackEnabled) {
        [optionalParamsInString appendFormat:@",\"%@\":\"%d\"", @"id", cmdId];
    }
    jsonString =[NSString stringWithFormat:@"{\"property\":{\"dsn\":\"%@\",\"name\":\"%@\",\"value\":%@,\"base_type\":\"%@\",\"metadata\":%@%@}}",
                 property.owner,
                 property.name,
                 escapedValueString,
                 property.baseType,
                 metadataInString,
                 optionalParamsInString];
    return jsonString;
}

//override
- (AylaDevice *)lanModeDelegate
{
    return [[AylaDeviceManager sharedManager] deviceWithDsn:self.gatewayDsn];
}

- (NSString *)lanModePropertyNameFromEdptPropertyName:(NSString *)name
{
    //No property switch required here
    return AYLA_EMPTY_STRING;
}

//--------------------caching helper methods----------------------

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_nodeType forKey:@"nodeType"];
    [encoder encodeObject:_gatewayDsn forKey:@"gatewayDsn"];
    [encoder encodeObject:_address forKey:@"address"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    AylaDeviceNode *node = [super initWithCoder:decoder];
    node.nodeType = [decoder decodeObjectForKey:@"nodeType"];
    node.gatewayDsn = [decoder decodeObjectForKey:@"gatewayDsn"];
    node.address = [decoder decodeObjectForKey:@"address"];
    
    return node;
}

//--------------------------helpful methods----------------------------
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    if (copy) {
        AylaDeviceNode *_copy = copy;
        _copy.nodeType = [_nodeType copy];
        _copy.gatewayDsn = [_gatewayDsn copy];
        _copy.address = [_address copy];
    }
    return copy;
}
@end

NSString * const kAylaNodeTypeZigbee = @"Zigbee";
NSString * const kAylaNodeTypeGeneric = @"Generic";

NSString * const kAylaDeviceNodeParamIdentifyValue = @"value";
NSString * const kAylaDeviceNodeParamIdentifyTime = @"time";
NSString * const kAylaDeviceNodeParamIdentifyOn = @"On";
NSString * const kAylaDeviceNodeParamIdentifyOff = @"Off";
NSString * const kAylaDeviceNodeParamIdentifyResult = @"Result";

NSString * const kAylaDeviceNodeParamIdentifyId = @"id";
NSString * const kAylaDeviceNodeParamIdentifyStatus = @"status";