//
//  AylaBatchRequest.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 9/30/15.
//  Copyright © 2015 AylaNetworks. All rights reserved.
//

#import "AylaBatchRequest.h"
#import "AylaDevice.h"
#import "AylaError.h"
#import "AylaErrorSupport.h"
#import "NSObject+AylaNetworks.h"
#import "AylaDeviceSupport.h"
@implementation AylaBatchRequest

- (id)toCloudJSONObject:(AylaError * __nullable __autoreleasing *)error
{
    // By default
    if(error != NULL) {
        *error = nil;
    }
    return @{};
}

- (BOOL)validateSelf:(AylaError * __nullable __autoreleasing *)error
{
    if(error != NULL) {
        *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                  httpCode:0
                               nativeError:nil
                              andErrorInfo:@{kAylaErrorInfoDescription: @"Invalid request"}];
    }
    return NO;
}

@end

static NSArray * DefaultBannedToCloudPropertyBaseTypes;

@interface AylaDatapointBatchRequest ()

@property (nonatomic, copy) id validatedDatapointValue;

@end

@implementation AylaDatapointBatchRequest

+ (void)initialize
{
    if (self == [AylaDatapointBatchRequest self]) {
        DefaultBannedToCloudPropertyBaseTypes = @[@"file", @"stream"];
    }
}

- (id)requestObject
{
    return self.datapoint;
}

- (instancetype)initWithDatapoint:(AylaDatapoint *)datapoint
                         property:(AylaProperty *)property
{
    self = [super init];
    if(!self) return nil;
    
    _datapoint = datapoint;
    _property = property;
    
    return self;
}

+ (instancetype)requestWithDatapoint:(AylaDatapoint *)datapoint
                          toProperty:(AylaProperty *)property
{
    return [[[self class] alloc] initWithDatapoint:datapoint property:property];
}

-(BOOL)validateSelf:(AylaError * __nullable __autoreleasing *)error
{
    if(![self.property.owner nilIfNull]) {
        
        // No device dsn found in property object
        if(error != NULL) {
            *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                      httpCode:0
                                   nativeError:nil
                                  andErrorInfo:@{kAylaErrorInfoDescription: @"Invalid request",
                                                 NSStringFromSelector(@selector(property)): @"Name is missing"}];
        }
        return NO;
    }

    if(![self.property.name nilIfNull]) {
        
        // No property name found in property object
        if(error != NULL) {
            *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                      httpCode:0
                                   nativeError:nil
                                  andErrorInfo:@{kAylaErrorInfoDescription: @"Invalid request",
                                                 NSStringFromSelector(@selector(property)): @"DSN is missing"}];
        }
        return NO;
    }
    
    else if (![self.property.baseType nilIfNull] ||
             [DefaultBannedToCloudPropertyBaseTypes containsObject: self.property.baseType]) {
    
        // Invalid baseType in property object
        if(error != NULL) {
            *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                      httpCode:0
                                   nativeError:nil
                                  andErrorInfo:@{kAylaErrorInfoDescription: @"Invalid request",
                                                 NSStringFromSelector(@selector(property)): @"is not supported in datapoint batch request"}];
        }
        return NO;
    }
    
    AylaError *dpError;
    id value = [self.property validatedValueFromDatapoint:self.datapoint error:&dpError];
    
    if(!value) {
        
        // No valid value found in datapoint object
        self.validatedDatapointValue = nil;
        if(error != NULL) {
            *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS
                                      httpCode:0
                                   nativeError:nil
                                  andErrorInfo:@{kAylaErrorInfoDescription: @"Invalid request",
                                                 NSStringFromSelector(@selector(datapoint)): @"is invalid"}];
        }
        return NO;
    }
    
    self.validatedDatapointValue = value;
    return YES;
}

/**
 *  Note: This method always uses current known values to compose JSON Object, which means a JSON object will
 *   always be returned from this method. Also input error parameter will never be updated in this method.
 */
- (id)toCloudJSONObject:(AylaError * __nullable __autoreleasing *)error
{
    return @{
             @"datapoint": @{
                     @"value": self.validatedDatapointValue?:[NSNull null],
                     },
             @"name": self.property.name?:[NSNull null],
             @"dsn": self.property.owner?:[NSNull null]
             };
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, dsn: %@, prop.name: %@, prop.baseType:%@, datapoint: <%@>> ",
            NSStringFromClass([self class]),
            self,
            self.property.owner,
            self.property.name,
            self.property.baseType,
            self.datapoint];
}

@end
