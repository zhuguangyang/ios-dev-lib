//
//  AylaDeviceSupport.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 3/20/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaDevice.h"
#import "AylaLanModule.h"
#import "AylaMessage.h"
@class AylaHTTPOperation;
@class AylaLanCommandEntity;
@class AylaMessage;
@class AylaLanMessage;
@class AylaMessageResponse;
@interface AylaDevice(Support)
@property (nonatomic, copy)     NSNumber *key;                       //Device key number
@property (nonatomic, strong)   AylaLanModeConfig* lanModeConfig;    //Lan mode support
@property (nonatomic, copy)     NSMutableArray *features;
@property (nonatomic, strong, readwrite) NSString *connectionStatus;
@property (nonatomic, strong, readwrite) AylaLanModule *lanModule;

- (id)   initDeviceWithDictionary:(NSDictionary *)dictionary;
- (void) updateWithDictionary:(NSDictionary *)deviceDictionary;
- (void) updateWithCopy:(AylaDevice *)device;

+ (instancetype) deviceFromDeviceDictionary:(NSDictionary *)deviceDictionary;

+ (void) getNewDeviceConnected:(NSString *)dsn
                    setupToken:(NSString *) setupToken
                       success:(void (^)(AylaResponse *response, NSDictionary *responce))successBlock
                       failure:(void (^)(AylaHTTPOperation *operation, AylaError *err))failureBlock;

- (void)          lanModeEnableWithType:(AylaLanModeSessionType)type;
- (BOOL)          isLanModeEnabled;
- (BOOL)          isLanModeActive;
- (AylaProperty*) findProperty:(NSString *)propertyName;
- (void)          getLanModeConfig;

- (BOOL)          initPropertiesFromCache;
+ (Class)         deviceClassFromDeviceDictionary:(NSDictionary *)dictionary;
+ (Class)         deviceClassFromClassName:(NSString *)className;

- (NSInteger)     updateWithPropertyName:(NSString *)propertyName andValue:(NSString *)value;
- (NSInteger)     lanModeWillSendCmdEntity:(AylaLanCommandEntity *)entity;
- (NSUInteger)    lanModeUpdateWithPropertyName:(NSString *)propertyName value:(id)value message:(AylaLanMessage *)message params:(NSDictionary *)params;
- (NSString *)    lanModeToDeviceUpdateWithCmdId:(__unused int)cmdId property:(AylaProperty *)property valueString:(NSString *)valueString;
- (NSString *)    lanModeToDeviceCmdWithCmdId:(int)cmdId messageType:(AylaMessageType)messageType requestMethod:(NSString *)method sourceLink:(NSString *)sourceLink uri:(NSString *)uri data:(NSString *)data;
- (AylaMessageResponse *) didReceiveMessage:(AylaMessage *)message;
- (AylaMessageResponse *) handleLanMessage:(AylaLanMessage *)message;
- (void)          incrementNotifyOutstandingCounter;
- (void)          decrementNotifyOutstandingCounter;
- (void)          resetNotifyOustandingCounter;

/*
 * This api will be called by AylaLanMode when device taged/untagged as current LME device.
 * Note this api doesn't guarantee a lan session could be succesfully eastablished.
 */
- (void)          didEnableLanMode;
- (void)          didDisableLanMode;

- (AylaDevice *)  lanModeDelegate;
- (AylaDevice *)  lanModeEdptFromDsn:(NSString *)dsn;
- (NSString *)    lanModePropertyNameFromEdptPropertyName:(NSString *)name;
- (AylaDevice *)  managedCopy;

@end


@interface AylaProperty(Support)
@property (nonatomic, copy) NSNumber *key;

@property (nonatomic, copy, readwrite) NSDate *ackedAt;
@property (nonatomic, assign, readwrite) NSInteger ackStatus;
@property (nonatomic, assign, readwrite) NSInteger ackMessage;

- (id)validatedValueFromDatapoint:(AylaDatapoint *)datapoint error:(AylaError * __autoreleasing *)error;

+ (NSOperation *) getProperties:(AylaDevice *)device callParams:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *response, NSArray *properties))successBlock
               failure:(void (^)(AylaError *err))failureBlock;

- (id)   initDevicePropertyWithDictionary:(NSDictionary *)propertyDictionary;
- (void) updateWithValue:(id)value params:(NSDictionary *)params;
- (void) updateDatapointFromProperty;
- (void) updateWithCopy:(AylaProperty *)property;
+ (void) setLastDsn:(NSString *) dsn;
- (void) lanModeEnable:(AylaDevice *)device;
- (void) lanModeEnable:(AylaDevice *)device property:(AylaProperty *)property;
+ (void) lanModeEnable:(AylaDevice *)device properties:(NSArray *)properties;
@end

@interface AylaDatapoint(Support)

- (id)initPropertyDatapointWithDictionary:(NSDictionary *)datapointDictionary;

- (void)updateWithProperty:(AylaProperty *)property params:(NSDictionary *)params;

+ (NSOperation *)createDatapoint:(AylaProperty *)thisProperty datapoint:(AylaDatapoint *)datapoint params:(NSDictionary *)callParams
                         success:(void (^)(AylaResponse *response, AylaDatapoint *datapoint))successBlock
                         failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) getDatapointsByActivity:(AylaProperty *)property callParams:(NSDictionary *)callParams
                         success:(void (^)(AylaResponse *response, NSArray *datapoints))successBlock
                         failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) getDatapointById:(NSString *)datapointId property:(AylaProperty *)property params:callParams
                          success:(void (^)(AylaResponse *response, AylaDatapoint *datapoint))successBlock
                          failure:(void (^)(AylaError *err))failureBlock;

@end

@interface AylaDatapointBlob(Support)

@property (nonatomic, strong) NSString *fileUrl;
@property (nonatomic, strong) NSString *location;

+ (NSOperation *) getBlobsByActvity:(AylaProperty *)property callParams:callParams
                   success:(void (^)(AylaResponse *response, NSArray *retrievedDatapoint))successBlock
                   failure:(void (^)(AylaError *err))failureBlock;

+ (void)getBlobSaveToFileWithDatapoint:(AylaDatapointBlob *)datapoint property:(AylaProperty *)property
                                params:(NSDictionary *)callParams
                               success:(void (^)(AylaResponse *response, NSString *retrievedBlobName))successBlock
                               failure:(void (^)(AylaError *err))failureBlock;

/*
 * @note: Only only upload once for each datapoint.
 */
+ (void)uploadBlobWithDatapoint:(AylaDatapointBlob *)datapoint params:(NSDictionary *)callParams
                        success:(void (^)(AylaResponse *response, AylaDatapointBlob *datapoint))successBlock
                        failure:(void (^)(AylaError *err))failureBlock;

+ (void) createBlobWithProperty:(AylaProperty *)property params:(NSDictionary *)callParams
                       success:(void (^)(AylaResponse *response, AylaDatapointBlob *retrievedBlobs))successBlock
                       failure:(void (^)(AylaError *err))failureBlock;

+ (NSOperation *) getBlobLocation:(AylaDatapointBlob *)datapoint
                         success:(void (^)(AylaResponse *response, AylaDatapointBlob *datapoint))successBlock
                         failure:(void (^)(AylaError *err))failureBlock;

- (NSOperation *) markFinished:(NSDictionary *)callParams
                      success:(void (^)(AylaResponse *response))successBlock
                      failure:(void (^)(AylaError *err))failureBlock;

@end

extern NSString * const kAylaDeviceClassNameGateway;
extern NSString * const kAylaDeviceClassNameNode;
extern NSString * const kAylaDeviceClassName;