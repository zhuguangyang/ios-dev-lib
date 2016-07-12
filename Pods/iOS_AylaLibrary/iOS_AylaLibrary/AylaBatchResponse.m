//
//  AylaBatchResponse.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 9/30/15.
//  Copyright © 2015 AylaNetworks. All rights reserved.
//

#import "AylaBatchResponse.h"
#import "AylaDevice.h"
#import "AylaDeviceSupport.h"
#import "NSObject+AylaNetworks.h"

@implementation AylaBatchResponse

- (instancetype)init
{
    return [self initWithJSONDictionary:@{@"status": @(0)}];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(!self) return nil;
    
    _statusCode = [dictionary[@"status"] nilIfNull];
    
    return self;
}

@end

@implementation AylaDatapointBatchResponse

- (instancetype)initWithJSONDictionary:(NSDictionary *)dictionary
{
    self = [super initWithJSONDictionary:dictionary];
    if(!self) return nil;
    
    _deviceDsn = dictionary[@"dsn"];
    _propertyName = dictionary[@"name"];
    _datapoint = [[AylaDatapoint alloc] initPropertyDatapointWithDictionary:dictionary];
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, dsn: %@, name: %@, datapoint: %@, status: %@> ",
            NSStringFromClass([self class]),
            self,
            self.deviceDsn,
            self.propertyName,
            self.datapoint,
            self.statusCode];
}

@end