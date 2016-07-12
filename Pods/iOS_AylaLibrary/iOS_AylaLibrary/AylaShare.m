//
//  AylaShare.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 10/5/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaShare.h"
#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaErrorSupport.h"
#import "AylaShareUserProfile.h"

#define AML_SHARE_OPERATION_READ_ONLY @"read"
#define AML_SHARE_OPERATION_READ_AND_WRITE @"write"

@implementation AylaShare
@synthesize id = _id;
@synthesize grantId = _grantId;
@synthesize accepted = _accepted;
@synthesize acceptedAt = _acceptedAt;
@synthesize ownerId = _ownerId;
@synthesize operation = _operation;
@synthesize userId = _userId;
@synthesize userEmail = _userEmail;
@synthesize ownerProfile = _ownerProfile;
@synthesize userProfile = _userProfile;
@synthesize resourceId = _resourceId;
@synthesize roleName = _roleName;
@synthesize resourceName = _resourceName;
@synthesize createdAt = _createdAt;
@synthesize updatedAt = _updatedAt;
//@synthesize condition = _condition;
@synthesize startDateAt = _startDateAt;
@synthesize endDateAt = _endDateAt;

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(self && dictionary) {
        _id = [(NSNumber *)[dictionary objectForKey:attrNameId] stringValue];
        _grantId = [(NSNumber *)[dictionary objectForKey:attrNameGrantId] stringValue];
        _resourceId = [dictionary objectForKey:attrNameResourceId];
        _resourceName = [dictionary objectForKey:attrNameResourceName];
        _createdAt = [dictionary objectForKey:attrNameCreatedAt];
        _updatedAt = [dictionary objectForKey:attrNameUpdatedAt];
        
        _accepted = [[dictionary objectForKey:attrNameAccepted] boolValue];
        _acceptedAt = [dictionary objectForKey:attrNameAcceptedAt]!=[NSNull null]?[dictionary objectForKey:attrNameAcceptedAt]:nil;
        
        _ownerId = [(NSNumber *)[dictionary objectForKey:attrNameOwnerId] stringValue];
        
        _userId = [(NSNumber *)[dictionary objectForKey:attrNameUserId] stringValue];
        _userEmail = [dictionary objectForKey:attrNameUserEmail];
        
        _ownerProfile = [[AylaShareUserProfile alloc] initWithDictionary:dictionary[attrNameOwnerProfile]];
        _userProfile = [[AylaShareUserProfile alloc] initWithDictionary:dictionary[attrNameUserProfile]];
        
        _operation = [[dictionary objectForKey:attrNameOperation] isEqualToString:AML_SHARE_OPERATION_READ_ONLY]? AylaShareOperationReadOnly:AylaShareOperationReadAndWrite;
        
        _startDateAt = [dictionary objectForKey:attrNameStartDateAt]!=[NSNull null]?[dictionary objectForKey:attrNameStartDateAt]:nil;
        _endDateAt = [dictionary objectForKey:attrNameEndDateAt]!=[NSNull null]?[dictionary objectForKey:attrNameEndDateAt]:nil;
        NSDictionary *roleDictionary = [dictionary objectForKey:attrNameRoleDictionary];
        if ([roleDictionary isKindOfClass:[NSDictionary class]]) {
            _role = [[AylaRole alloc] initWithDictionary:roleDictionary];
        }
    }
    return self;
}

+ (NSOperation *)create:(AylaShare *)share object:(id)object
                success:(void (^)(AylaResponse *resp, AylaShare *share))successBlock
                failure:(void (^)(AylaError *error))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    AylaError *error = [AylaError new];
    error.errorCode = AML_USER_INVALID_PARAMETERS;
    
    if([object isKindOfClass:[AylaUser class]]) {
        //TBD
    } else
    if([object isKindOfClass:[AylaDevice class]]) {
        
        AylaDevice *device = object;
        share.resourceName = kAylaShareResourceNameDevice;
        share.resourceId = device.dsn;
        
        if(!device.dsn) {
            [errors setValue:@"is invalid." forKey:@"device"];
        }
        
        if (![device.deviceType isEqualToString:kAylaDeviceTypeWifi]) {
            [errors setValue:@"Gateway and node devices may not be shared" forKey:@"deviceType"];
        }
    } else {
        [errors setValue:@"unsupported object." forKey:@"object"];
    }
    
    if(!share.resourceName) {
        [errors setValue:@"can't be blank." forKey:attrNameResourceName];
    }
    if(!share.resourceId) {
        [errors setValue:@"can't be blank." forKey:attrNameResourceId];
    }
    if(!share.userEmail) {
        [errors setValue:@"can't be blank." forKey:attrNameUserEmail];
    }
    
    // ensure both start and end date if provided
    if((share.startDateAt && !share.endDateAt)||
       (!share.startDateAt && share.endDateAt)) {
        [errors setValue:@"can't be blank." forKey:@"start date & end date"];
    }
    
    if(errors.count > 0) {
        error.errorInfo = errors;
        failureBlock(error);
        return nil;
    }
    
    return [[AylaApiClient sharedUserServiceInstance] postPath: @"api/v1/users/shares.json" parameters:[share toServiceDictionary]
                   success:^(AylaHTTPOperation *operation, id responseObject) {
                       saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"getDeviceShares.getPath");
                       
                       AylaShare *share = [[AylaShare alloc] initWithDictionary:responseObject[@"share"]];
                       
                       successBlock(operation.response, share);
                   }
                   failure:^(AylaHTTPOperation *operation, AylaError *error) {
                       saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"shareDevice");
                       failureBlock(error);
                   }
            ];

}

+ (NSOperation *)getWithId:(NSString *)objId
                success:(void (^)(AylaResponse *resp, AylaShare *share))successBlock
                failure:(void (^)(AylaError *error))failureBlock
{

    if(!objId){
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.nativeErrorInfo = nil; err.errorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    
    // https://user.aylanetworks.com/api/v1/users/shares/1.json
    NSString *url = [NSString stringWithFormat:@"api/v1/users/shares/%@.json", objId, nil];
    return [[AylaApiClient sharedUserServiceInstance] getPath:url parameters:nil
                  success:^(AylaHTTPOperation *operation, id responseObject) {
                      saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"getDeviceShares.getPath");
                      
                      AylaShare *share = [[AylaShare alloc] initWithDictionary:responseObject[@"share"]];
                      successBlock(operation.response, share);
                  }
                  failure:^(AylaHTTPOperation *operation, AylaError *error) {
                      saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"getDeviceShares.getPath");
                      failureBlock(error);
                  }
            ];
}

+ (NSOperation *)get:(id)object callParams:(NSDictionary *)callParams
             success:(void (^)(AylaResponse *resp, NSMutableArray *shares))successBlock
             failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaShare getOwnsOrReceivesWithObject:object params:callParams getReceived:NO success:successBlock failure:failureBlock];
}

+ (NSOperation *)getReceives:(id)object callParams:(NSDictionary *)callParams
                     success:(void (^)(AylaResponse *resp, NSMutableArray *shares))successBlock
                     failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaShare getOwnsOrReceivesWithObject:object params:callParams getReceived:YES success:successBlock failure:failureBlock];
}

+ (NSOperation *)getOwnsOrReceivesWithObject:(id)object
                                      params:(NSDictionary *)callParams
                                 getReceived:(BOOL)getReceived
                                     success:(void (^)(AylaResponse *resp, NSMutableArray *shares))successBlock
                                     failure:(void (^)(AylaError *error))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    AylaError *error = [AylaError new];
    error.errorCode = AML_USER_INVALID_PARAMETERS;
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSString *url = getReceived? @"api/v1/users/shares/received.json": @"api/v1/users/shares.json";

    if ([object isKindOfClass:[AylaUser class]]) {
        // https://user.aylanetworks.com/api/v1/users/shares.json
        
    }
    else
    if ([object isKindOfClass:[AylaDevice class]]) {
        // https://user.aylanetworks.com/api/v1/users/shares.json
        AylaDevice *device = object;
        if(!device.dsn) {
            [errors setValue:@"is invalid." forKey:@"device"];
        }
        else {
            [params setObject:device.dsn forKey:attrNameResourceId];
            [params setObject:kAylaShareResourceNameDevice forKey:attrNameResourceName];
        }
    }
    
    if(errors.count > 0) {
        error.errorInfo = errors;
        failureBlock(error);
        return nil;
    }
    
    if(callParams) {
        if([callParams objectForKey:attrNameResourceName]){
            [params setObject:[callParams objectForKey:attrNameResourceName] forKey:attrNameResourceName];
        }
        if([callParams objectForKey:attrNameResourceId]) {
            [params setObject:[callParams objectForKey:attrNameResourceId] forKey:attrNameResourceId];
        }
    }
    return [[AylaApiClient sharedUserServiceInstance] getPath:url parameters:params
                  success:^(AylaHTTPOperation *operation, id responseObject) {
                      saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"getDeviceShares.getPath");
                      
                      NSMutableArray *arrayOfShares = [NSMutableArray new];
                      
                      for(NSDictionary *dict in responseObject) {
                          AylaShare *share = [[AylaShare alloc] initWithDictionary:dict[@"share"]];
                          [arrayOfShares addObject:share];
                      }
                      
                      successBlock(operation.response, arrayOfShares);
                  }
                  failure:^(AylaHTTPOperation *operation, AylaError *error) {
                      saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"getDeviceShares.getPath");
                      failureBlock(error);
                  }
            ];
}

+ (NSOperation *)update:(AylaShare *)share
                success:(void (^)(AylaResponse *response, AylaShare *updatedShare)) successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    if(!share.id) {
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.errorInfo = nil; err.nativeErrorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    
    return [[AylaApiClient sharedUserServiceInstance] putPath:[NSString stringWithFormat:@"api/v1/users/shares/%@.json", share.id] parameters:[share toServiceDictionary]
                   success:^(AylaHTTPOperation *operation, id responseObject) {
                       saveToLog(@"%@, %@, %@, %@", @"I", @"AylaShare", @"none", @"update.putPath");
                       
                       NSDictionary *resp = responseObject;
                       AylaShare *newShare = [[AylaShare alloc] initWithDictionary:resp[@"share"]];
                       
                       successBlock(operation.response, newShare);
                   }
                   failure:^(AylaHTTPOperation *operation, AylaError *error) {
                       saveToLog(@"%@, %@, %@, %@", @"E", @"AylaShare", error.logDescription, @"update.putPath");
                       failureBlock(error);
                   }
            ];
}

+ (NSOperation *)delete:(AylaShare *)share
                success:(void (^)(AylaResponse *response)) successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    if(!share.id) {
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.errorInfo = nil; err.nativeErrorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    
    return [[AylaApiClient sharedUserServiceInstance] deletePath:[NSString stringWithFormat:@"api/v1/users/shares/%@.json", share.id] parameters:nil
                  success:^(AylaHTTPOperation *operation, id responseObject) {
                      saveToLog(@"%@, %@, %@, %@", @"I", @"AylaShare", @"none", @"delete");
                      successBlock(operation.response);
                  }
                  failure:^(AylaHTTPOperation *operation, AylaError *error) {
                      saveToLog(@"%@, %@, %@, %@", @"E", @"AylaShare", error.logDescription, @"delete");
                      failureBlock(error);
                  }
            ];
}

- (NSDictionary *)toServiceDictionary
{
    NSParameterAssert(self.resourceName);
    NSMutableDictionary *toServiceDictionary = [NSMutableDictionary new];
    [toServiceDictionary setObject:self.resourceName forKey:attrNameResourceName];
    [toServiceDictionary setObject:self.resourceId?:[NSNull null] forKey:attrNameResourceId];
    [toServiceDictionary setObject:self.roleName?:[NSNull null] forKey:attrNameRoleName];
    [toServiceDictionary setObject:self.userEmail?:[NSNull null] forKey:attrNameUserEmail];
    [toServiceDictionary setObject:@(self.accepted) forKey:attrNameAccepted];
    
    [toServiceDictionary setObject:self.startDateAt?:[NSNull null] forKey:attrNameStartDateAt];
    [toServiceDictionary setObject:self.endDateAt?:[NSNull null] forKey:attrNameEndDateAt];
    [toServiceDictionary setObject:self.operation == AylaShareOperationReadOnly?attrNameReadOnly:attrNameReadWrite forKey:attrNameOperation];
    
    return @{@"share":toServiceDictionary};
}


static NSString * const attrNameId = @"id";
static NSString * const attrNameUserId = @"user_id";
static NSString * const attrNameOwnerId = @"owner_id";
static NSString * const attrNameResourceName = @"resource_name";
static NSString * const attrNameResourceId = @"resource_id";
static NSString * const attrNameRoleName = @"role_name"; //key for the "role_name" string

static NSString * const attrNameRoleDictionary = @"role"; //key for the "role" dictionary returned when fetching received shares
static NSString * const attrNameRoleDictionary_Name = @"name"; //key inside the "role" dictionary for the "name" string
static NSString * const attrNameUserEmail = @"user_email";
static NSString * const attrNameOperation = @"operation";
static NSString * const attrNameStatus = @"operation";
static NSString * const attrNameStartDateAt = @"start_date_at";
static NSString * const attrNameEndDateAt = @"end_date_at";
static NSString * const attrNameCreatedAt = @"created_at";
static NSString * const attrNameUpdatedAt = @"updated_at";

static NSString * const attrNameAccepted = @"accepted";
static NSString * const attrNameAcceptedAt = @"accepted_at";
static NSString * const attrNameOwnerProfile = @"owner_profile";
static NSString * const attrNameUserProfile = @"user_profile";

static NSString * const attrNameGrantId = @"grant_id";

static NSString * const attrNameReadWrite = @"write";
static NSString * const attrNameReadOnly = @"read";

@end

NSString * const kAylaShareParamResourceId = @"resource_id";
NSString * const kAylaShareParamResourceName = @"resource_name";
NSString * const kAylaShareResourceNameDevice = @"device";

@implementation AylaRole

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        _name = dictionary[attrNameRoleDictionary_Name];
    }
    return self;
}

@end