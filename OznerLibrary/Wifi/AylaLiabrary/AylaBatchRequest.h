//
//  AylaBatchRequest.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 9/30/15.
//  Copyright © 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class AylaDevice;
@class AylaProperty;
@class AylaDatapoint;
@class AylaError;

/**
 *  Abstract class of batch requests.
 *
 *  Batch requests provide a way for applications to send multiple commands simultaneously in one HTTP 
 *  request or one LAN Mode request.
 *
 *  When utilizing a batch-enabled method, applications should initialize each commands as an instance
 *  of AylaBachRequest subclasses and append requests to a container which will be passed as a parameter
 *  to the method.
 */
@interface AylaBatchRequest : NSObject
@property (nonatomic, readonly, nullable) id requestObject;

/**
 *  Validate current request.
 *
 *  @return Return YES if validation is succeeded. Otherwise return NO and set error parameter if error is not NULL.
 */
- (BOOL)validateSelf:(AylaError * __autoreleasing __nullable * __nullable)error;

/**
 *  Return to-cloud JSON object.
 *  
 *  @return Generated JSON object. If JSON object can not be created and error is not NULL, set error parameter.
 */
- (id)toCloudJSONObject:(AylaError * __autoreleasing __nullable * __nullable)error;
@end

/**
 *  AylaDatapointBatchRequest is a concrete class inherited from AylaBatchRequest.
 *
 *  Each AylaDatapointBatchRequest represents a datapoint batch request. Applications must utilize
 *  a datapoint and a property to create an instance.
 */
@interface AylaDatapointBatchRequest : AylaBatchRequest

/** The property to process current request. */
@property (nonatomic, readonly, nullable) AylaProperty *property;

/** The datapoint that is going to be created. */
@property (nonatomic, readonly, nullable) AylaDatapoint *datapoint;

/**
 *  Use this method to create a new AylaDatapointBatchRequest instance
 *
 *  @param datapoint The datapoint that is going to be created.
 *  @param property The property to process this request.
 *  @return Created AylaDatapointBatchRequest instance.
 */
+ (instancetype)requestWithDatapoint:(AylaDatapoint *)datapoint
                          toProperty:(AylaProperty *)property;

@end

NS_ASSUME_NONNULL_END
