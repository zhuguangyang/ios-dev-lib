//
//  AylaLanModule.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 3/6/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaLanMode.h"
@class AylaDevice;
@class AylaTimer;
@class AylaLanModeConfig;
@class AylaEncryption;
@class AylaLanSession;
@class AylaHTTPOperation;

//FIXME: to be deprecated
typedef void (^LanCommandRespBlock)(AylaLanCommandEntity *command, NSDictionary *resp, int status);


typedef NS_ENUM(uint8_t, AylaLanModeSessionType) {

    AylaLanModeSessionTypeNormal,
    AylaLanModeSessionTypeSetup
};

typedef NS_ENUM(int, AylaLanModeErrorCode) {
    AylaLanModeErrorCodeNoErr = 0,

    AylaLanModeErrorCodeRequireCloudReachability = 3000,
    AylaLanModeErrorCodeLanNotEnabled = 3001 ,
    AylaLanModeErrorCodeInvalidConfigFile = 3002,
    AylaLanModeErrorCodeLanConfigEmptyOnCloud = 3003,
    AylaLanModeErrorCodeLanConfigNotEnabled = 3004,
    AylaLanModeErrorCodeUnmatchedKeyInfo = 3005,
    
    AylaLanModeErrorCodeMobileSessionMsgTimeOut = 3020,
    AylaLanModeErrorCodeDeviceNotSupport = 3021,
    AylaLanModeErrorCodeDeviceDifferentLan = 3022,
    AylaLanModeErrorCodeDeviceResponseError = 3023,
    
    AylaLanModeErrorCodeLibraryNilDevice = 3050,
    AylaLanModeErrorCodeLibraryInvalidParam = 3051,
    AylaLanModeErrorCodeCloudInvalidResp = 3052
};

@interface AylaLanModule : NSObject

@property (strong, getter=dsn, nonatomic) NSString *dsn;

@property (weak, nonatomic) AylaDevice *device;

@property (strong, nonatomic) AylaLanSession *session;

@property (strong, nonatomic) AylaLanModeConfig *lanConfig;

@property (strong, readonly, nonatomic) NSString * lanIp;

@property (assign, nonatomic) uint8_t lastestErrorCode;

@property (assign, nonatomic) BOOL inSetupMode;

- (instancetype)initWithDevice:(AylaDevice *)device;

#pragma mark - lan session
- (void)lanModeEnable;
- (void)lanModeDisable;

- (void)lanModeEnableWithType:(AylaLanModeSessionType)sessionType;

//- (void)extendLanModeSession:(int)method haveDataToSend:(BOOL)haveDataToSend;

- (BOOL)isLanModeEnabled;

#pragma mark - Lan Notify
- (void)deliverLanError:(AylaLanModeErrorCode)errorCode httpStatusCode:(NSInteger)httpStatusCode;
- (void)deliverLanMessageWithType:(NSString *)type httpStatusCode:(NSInteger)httpStatusCode key:(NSString *)key values:(NSArray *)values;

@end

@class AylaError;
@class AylaLanOperation;
@interface AylaLanSession : NSObject

@property (weak, nonatomic) AylaLanModule *module;

@property (strong, nonatomic) AylaTimer *sessionTimer;

@property (assign, setter = setSessionState:, nonatomic) enum lanModeSession sessionState;

@property (strong, nonatomic) AylaEncryption *sessionEncryption;

@property (assign, nonatomic) AylaLanModeErrorCode lastestErrorCode;

@property (assign, nonatomic) AylaLanModeSessionType type;

- (instancetype)initWithLanModule:(AylaLanModule *)module;

#pragma mark - lan session
- (void)eastablish;
- (void)close;

- (BOOL)isEnabled;
- (BOOL)isTimerOn;

- (void)updateSessionState:(enum lanModeSession)sessionState
                  withCode:(AylaLanModeErrorCode)code
            httpStatusCode:(NSUInteger)httpStatusCode
                sendNotify:(BOOL)sendNotify;

- (void)extendLanModeSession:(int)method haveDataToSend:(BOOL)haveDataToSend;

//private api call
- (NSOperation *)sendExtensionMessage:(int)method params:(NSDictionary *)msgParams withTimeout:(int)timeout
                              success:(void (^)(AylaHTTPOperation *operation, id responseObject))successBlock
                              failure:(void (^)(AylaHTTPOperation *operation, AylaError *error))failureBlock;

#pragma mark - lan config
- (void)didUpdateLanModeConfig:(AylaLanModeConfig *)config;
- (void)didUpdateLanIp;

#pragma mark - timer
- (void)startTimer;
- (void)stopTimer;

#pragma mark - setup
- (BOOL)inSetupMode;

#pragma mark - session operations
- (void)pushOperation:(AylaLanOperation *)operation;

#pragma mark - queue
- (void)enQueue:(int)cmdId baseType:(int)baseType jsonString:(NSString *)jsonString;

- (void)enQueue:(AylaLanCommandEntity *)command;

- (AylaLanCommandEntity *)nextInQueue;

- (AylaLanCommandEntity *)deQueue;
- (AylaLanCommandEntity *)deQueueTillNextValidCommand;

#pragma mark - sequence num
- (int)nextCommandOutstandingId;

- (int)nextSequenceNum;
- (void)resetSequenceNum;

#pragma mark - command oustanding
- (AylaLanCommandEntity *)getOutstandingCommand:(NSString *)cmdId;
- (void)putOutstandingCommand:(AylaLanCommandEntity *)command;
- (void)removeOutstandingCommand:(NSString *)cmdId;

@end



