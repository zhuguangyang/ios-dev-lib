//
//  AylaConnectionOperation.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/9/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AML_CONNECTION_OPERATION_DEFAULT_TIMEOUT 30

typedef NS_ENUM(uint8_t, AylaConnectionOperationType) {
    AylaConnectionOperationTypeUnknown,
    AylaConnectionOperationTypeCloudHTTP,
    AylaConnectionOperationTypeLan
};

@class AylaConnectionOperation;
@class AylaResponse;
@class AylaError;

typedef void (^AylaConnectionOperationCallbackBlock)(AylaResponse *response, id responseObj, AylaError *error);

/**
 *  Abstract class for connection operations
 */
@interface AylaConnectionOperation : NSOperation

/** Connection operation type */
@property (nonatomic, assign, readonly)   AylaConnectionOperationType type;

/** timeout interval of this operation */
@property (nonatomic, assign)   NSUInteger timeoutInterval;

/** is current operation timed out */
@property (assign, readonly, getter=isTimeout)    BOOL timeout;

/** Operation completion block */
@property (nonatomic, copy)     AylaConnectionOperationCallbackBlock callbackBlock;

- (NSUInteger)suggestedTimeoutInterval;

@end
