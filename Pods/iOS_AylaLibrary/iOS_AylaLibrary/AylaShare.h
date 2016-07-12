//
//  AylaShare.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 10/5/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AylaDeviceShareOperation) {
    AylaShareOperationReadOnly,
    AylaShareOperationReadAndWrite
};

@class AylaResponse;
@class AylaError;
@class AylaShareUserProfile;
@class AylaRole;
/**
 * Share a given resource between registered users.
 * By specifying a resource class and a unique resource identifier, these CRUD APIs support sharing the resource.
 * When a resource is shared by the owner, the resource for the target user will contain updated grant information.
 * See Device Service Grants for more information.
 *
 * Currently, only devices may be shared.
 * Only the owner to whom the device has been registered may share a device.
 * A resource may be shared to one or more registered user.
 * Share access controls access rights: read and write are supported.
 * Shares may include a start and end time-stamp.
 * Sharing supports custom email templates for share notification on creation.
 * A user can't have more than one share for the same resource_name and  resource_id.
 **/
@interface AylaShare : NSObject
@property (nonatomic, strong, readonly) NSString *id;               //The unique share id, Required except for create.
@property (nonatomic, assign)           BOOL accepted;              // If the share has been accepted by the recipient
@property (nonatomic, strong, readonly) NSString *acceptedAt;       // When the share has been accepted by the recipient
@property (nonatomic, strong, readonly) NSString *grantId;          //// The unique grant id associated with this share
@property (nonatomic, strong)           NSString *resourceName;     // Name of the resource class being shared. Ex: 'device', Required for create.
@property (nonatomic, strong)           NSString *resourceId;       // Unique identifier for the resource name being shared. Ex: 'AC000W0000001234', Required for create.
@property (nonatomic, strong)           NSString *roleName;         // Role name (to service).

@property (nonatomic, strong, readonly) AylaRole *role;             // Role (retrieved from service)

@property (nonatomic, strong, readonly) NSString *userId;           // The target user id that created this share. Returned with create/POST & update/PUT operations
@property (nonatomic, strong, readonly) NSString *ownerId;          // The owner user id that created this share. Returned with create/POST & update/PUT operations

@property (nonatomic, strong)           NSString *userEmail;        /// Unique email address of the Ayla registered target user to share the named resource with, Required

@property (nonatomic, strong)           AylaShareUserProfile *ownerProfile; // The owner of a shared resource info
@property (nonatomic, strong)           AylaShareUserProfile *userProfile;  // The user of a shared resource info

@property (nonatomic, assign)           AylaDeviceShareOperation operation; // Access permissions allowed: either read or write. Used with create/POST & update/PUT operations. Ex: 'write', Optional
                                                                            // If omitted, the default access permitted is read only

@property (nonatomic, strong, readonly) NSString *createdAt;        // When this object was created. Returned with create/POST & update/PUT operations
@property (nonatomic, strong, readonly) NSString *updatedAt;        // When this object was last updated. Returned with update/PUT operations
@property (nonatomic, strong)           NSString *startDateAt;      // When this named resource will be shared. Used with create/POST & update/PUT operations. Ex: '2014-03-17 12:00:00', Optional
                                                                    // If omitted, the resource will be shared immediately. UTC DateTime value.
@property (nonatomic, strong)           NSString *endDateAt;        // When this named resource will stop being shared. Used with create/POST & update/PUT operations. Ex: '2020-03-17 12:00:00', Optional
                                                                    // If omitted, the resource will be shared until the share or named resource is deleted. UTC DateTime value

- (id)initWithDictionary:(NSDictionary *)dictionary;

/**
 * create
 * Share a given resource between registered users.
 * By specifying a resource class and a unique resource identifier, these CRUD APIs support sharing the resource.
 * When a resource is shared by the owner, the resource for the target user will contain updated grant information.
 * See Device Service Grants for more information.
 *
 * Currently, only AylaDevices of deviceType kAylaDeviceTypeWifi may be shared.
 * Only the owner to whom the device has been registered may share a device.
 * A resource may be shared to one or more registered user.
 * Share access controls access rights: read and write are supported.
 * Shares may include a start and end time-stamp.
 * Sharing supports custom email templates for share notification on creation.
 * A user can't have more than one share for the same resource_name and resource_id.
 
 * Typical usage is to call this method from the owner pass-through methods in AylaDevice or AylaUser
 * @param object must be an AylaDevice object instance
 * @param success would be called with created share when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)create:(AylaShare *)share object:(id)object
                success:(void (^)(AylaResponse *resp, AylaShare *share))successBlock
                failure:(void (^)(AylaError *error))failureBlock;

/**
 * getWithId
 * This instance method is used to retrieve an existing share the Ayla Service based on a given id.
 * Typical usage is to call this method from the owner pass-through methods
 * @param id is the id whose value will be retrieved
 * @param success would be called with the retrieved share when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)getWithId:(NSString *)id
                success:(void (^)(AylaResponse *resp, AylaShare *share))successBlock
                failure:(void (^)(AylaError *error))failureBlock;

/**
 * get
 * This instance method is used to retrieve existing share objects from the Ayla Cloud Service
 * May be called from an owner pass-through method in AylaDevice to auto filter by class/type
 * @param object must be an AylaUser or AylaDevice object instance
 * @param callParams: one of the following filters:
 *            null: retrieve all share objects
 *            a "resource_name": the resource class/type to retrieve. Currently only "device" is supported
 *            a "resource_id": the specific resource id to be retrieved. Currently only a device.dsn is supported
 *              If resourceId is specified, resourceName is required.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)get:(id)object callParams:(NSDictionary *)callParams
             success:(void (^)(AylaResponse *resp, NSMutableArray *shares))successBlock
             failure:(void (^)(AylaError *error))failureBlock;

/**
 * getReceives
 * This instance method is used to retrieve existing share objects received from other users
 * May be called from an owner pass-through method in AylaDevice to auto filter by class/type
 * @param object must be an AylaUser or AylaDevice object instance
 * @param callParams: one of the following filters:
 *            null: retrieve all share objects
 *            a "resource_name": the resource class/type to retrieve. Currently only "device" is supported
 *            a "resource_id": the specific resource id to be retrieved. Currently only a device.dsn is supported
 *              If resourceId is specified, resourceName is required.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)getReceives:(id)object callParams:(NSDictionary *)callParams
             success:(void (^)(AylaResponse *resp, NSMutableArray *shares))successBlock
             failure:(void (^)(AylaError *error))failureBlock;

/**
 * update
 * This instance method is used to update a share on the Ayla Service.
 * Typical usage is to call this method from the owner pass-through methods in AylaDevice or AylaUser
 * @param success would be called with the updated share when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)update:(AylaShare *)share
                success:(void (^)(AylaResponse *response, AylaShare *updatedShare)) successBlock
                failure:(void (^)(AylaError *err))failureBlock;

/**
 * This instance method is used to delete an existing share on the Ayla Service.
 * Typical usage is to call this method from the owner pass-through methods AylaDevice or AylaUser
 * @param success would be called when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)delete:(AylaShare *)share
                success:(void (^)(AylaResponse *response)) successBlock
                failure:(void (^)(AylaError *err))failureBlock;
@end

extern NSString * const kAylaShareParamResourceId;
extern NSString * const kAylaShareParamResourceName;
extern NSString * const kAylaShareResourceNameDevice;

@interface AylaRole : NSObject
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@property (strong, nonatomic) NSString *name;
@end