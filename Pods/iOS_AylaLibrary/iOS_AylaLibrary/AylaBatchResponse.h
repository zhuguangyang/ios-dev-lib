//
//  AylaBatchResponse.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 9/30/15.
//  Copyright © 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AylaDatapoint;
/**
 *  Abstract class of batch response.
 *
 *  Batch response contains processing result of corresponding batch request. Normally, once completed, batch enabled
 *  methods will return a list of batch response to the callback set by caller. Caller needs check statusCode of each 
 *  batch response to determine result of each batch request.
 */
@interface AylaBatchResponse : NSObject

/** Status code of corresponding batch request */
@property (nonatomic, readonly) NSNumber *statusCode;

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

@end

/**
 *  AylaDatapointBatchResponse is a concrete class inherited from AylaBatchResponse
 *
 *  An instance of this class represents a response to a datapoint batch request.
 */
@interface AylaDatapointBatchResponse : AylaBatchResponse

/** Dsn of the device */
@property (nonatomic, readonly) NSString *deviceDsn;

/** Name of the property */
@property (nonatomic, readonly) NSString *propertyName;

/** The requested datapoint */
@property (nonatomic, readonly) AylaDatapoint *datapoint;

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END