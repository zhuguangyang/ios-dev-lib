//
//  AylaDevice.h
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 5/30/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaDefines.h"

@class AylaProperty;
@class AylaDatapoint;
@class AylaDatapointBlob;
@class AylaPropertyTrigger;
@class AylaApplicationTrigger;
@class AylaLanModeConfig;
@class AylaSchedule;
@class AylaResponse;
@class AylaError;
@class AylaTimeZone;
@class AylaDatum;
@class AylaDeviceNotification;
@class AylaShare;
@class AylaGrant;

//------------------------------------- AylaDevice --------------------------
extern NSString * const kAylaDeviceTypeWifi;
extern NSString * const kAylaDeviceTypeGateway;
extern NSString * const kAylaDeviceTypeNode;

@interface AylaDevice : NSObject <NSCopying, NSCoding>

/** Device Product Name */
@property (nonatomic, copy) NSString *productName;

/** Device Module */
@property (nonatomic, copy) NSString *model;

/** Device Serial Number */
@property (nonatomic, copy) NSString *dsn;

/** Device OEM Model */
@property (nonatomic, copy) NSString *oemModel;

/** Device Type */
@property (nonatomic, copy) NSString *deviceType;

/** Device last connected time */
@property (nonatomic, copy) NSString *connectedAt;

/** Device MAC address */
@property (nonatomic, copy) NSString *mac;

/** Device Local IP */
@property (nonatomic, copy) NSString *lanIp;

/** Software version running on the device */
@property (nonatomic, copy) NSString *swVersion;

/** SSID of the AP the device is connected to */
@property (nonatomic, copy) NSString *ssid;

/** Device Product Class */
@property (nonatomic, copy) NSString *productClass;

/** Does this device have properties */
@property (nonatomic, strong) NSNumber *hasProperties;

/** Public external WAN IP Address */
@property (nonatomic, copy) NSString *ip;

/** Is LAN Mode enabled on the service */
@property (nonatomic, copy) NSNumber *lanEnabled;

/** Near realtime indicator of device to service connectivity. Values are "Online" or "OffLine" */
@property (nonatomic, strong, readonly) NSString *connectionStatus;

/** Template Id associated with this device */
@property (nonatomic, strong, readonly) NSNumber *templateId;

/** Latitude coordinate */
@property (nonatomic, strong, readonly) NSString *lat;

/** Longitude coordinate */
@property (nonatomic, strong, readonly) NSString *lng;

/** User Id who has registered this device */
@property (nonatomic, strong, readonly) NSNumber *userId;

/** When any attribute updated last time */
@property (nonatomic, strong, readonly) NSString *moduleUpdatedAt;

/** Device Registration Type */
@property (nonatomic, copy) NSString *registrationType;

/** Device Registration Token */
@property (nonatomic, copy) NSString *registrationToken;

/** Device Setup Token */
@property (nonatomic, copy) NSString *setupToken;

/** Last Retrieval Time */
@property (nonatomic, strong) NSDate *retrievedAt;

/** Device Properties */
@property (nonatomic) NSMutableDictionary *properties;  //Device Properties

@property (nonatomic) AylaProperty *property;
@property (nonatomic, copy) NSMutableDictionary *schedules;
@property (nonatomic) AylaSchedule *schedule;
@property (nonatomic) NSMutableArray *deviceNotifications;
@property (nonatomic) AylaDeviceNotification *deviceNotification;
@property (nonatomic) NSMutableArray *shares;
@property (nonatomic) AylaShare *share;
@property (nonatomic) AylaGrant *grant;

@property (nonatomic, assign) NSInteger notifyOutstandingCounter;

/**
 * Method to get one or more registered devices from the Ayla Cloud Service.
 * @param callParams Not required.
 * @param success Block which would be called with a mutable array of user's devices when request is succeeded.
 * @param failure Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *) getDevices:(NSDictionary *)callParams
            success:(void (^)(AylaResponse *response, NSArray *devices))success
            failure:(void (^)(AylaError *err))failure;

/**
 * Method to get a device with device DSN from the Ayla Cloud Service. If requested device is not accessbile by current user. 401 will returned from the Ayla Cloud service.
 * @param dsn The dsn of requested device.
 * @param success Block which would be called with an "AylaDevice" object when request is succeeded.
 * @param failure Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *) getDeviceDetailWithDSN:(NSString *)dsn
                                 success:(void (^)(AylaResponse *response, AylaDevice *device))successBlock
                                 failure:(void (^)(AylaError *err))failureBlock;

/**
 * This instance method will instantiate a new registered device object from the Ayla Cloud Service and retrieve its associated properties.
 * Use this call only if additional device detail is required. In almost all cases, using the getProperties method is the preferred and more
 * efficient call
 * @param callParams Not required.
 * @param success Block which would be called with an "AylaDevice" object when request is succeeded.
 * @param failure Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getDeviceDetail:(NSDictionary *)callParams
                 success:(void (^)(AylaResponse *response, AylaDevice *deviceUpdated))success
                 failure:(void (^)(AylaError *err))failure;

/**
 * This instance method supports to update module information.
 * @discussion Current library only supports to update product name.
 * @param callParams Used to specify module information required to be changed.
 * @param success Block which would be called with an "AylaDevice" object when request is succeeded.
 * @param failure Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) update:(NSDictionary *)callParams
        success:(void (^)(AylaResponse *response, AylaDevice *deviceUpdated))success
        failure:(void (^)(AylaError *err))failure;

/**
 * Gets all properties summary objects associated with the device from Ayla device Service. Use getProperties when ordering is not important.
 * @param callParams allows for specifying the property names of a subset of properties to retrieve. These callParams are ignored for calls
 *        made to the Ayla field service and all properties are retrieved.
 * @param successBlock Block which would be called with an array of retrieved device properties when request is succeeded.
 * @param failureBlock Block which would be called with a AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getProperties:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *response, NSArray *properties))successBlock
               failure:(void (^)(AylaError *err))failureBlock;

/**
 * Device Registration provides a way to easily register a device once it has successfully completed the Setup process. Devices must be registered
 * before they can be accessed by the Device Service methods.
 * @param targetDevice The device users want to register to their account. If it is set to nil, Ayla Cloud Service will attempt to find most possible
 *        one to try registraion.
 * @param successBlock Block which would be called with that registered device when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (void) registerNewDevice:(AylaDevice *)targetDevice
                   success:(void (^)(AylaResponse *response, AylaDevice *registeredDevice))successBlock
                   failure:(void (^)(AylaError *err))failureBlock;

/**
 * This method will unregister a device from a user account. There are no call parameters required for this method at this time, so supply nil for now.
 * @param callParams Not required.
 * @param successBlock Block which would be called with an array of retrieved device properties when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) unregisterDevice:(NSDictionary *)callParams
                  success:(void (^)(AylaResponse *response))successBlock
                  failure:(void (^)(AylaError *err))failureBlock;

/**
 * This method will do factory reset for current device. There are no call parameters required for this method at this time, so supply nil for now.
 * @param callParams Not required.
 * @param successBlock Block which would be called when fatory reset is processed
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) factoryReset:(NSDictionary *)callParams
                      success:(void (^)(AylaResponse *response))successBlock
                      failure:(void (^)(AylaError *err))failureBlock;

/**
 * This method results in all schedules for a given device object being return to successBlock. Each AylaSchedule array member instance includes only
 * the schedule properties and not the associated Schedule Actions. This method is typically used to provide a top-level listing of available schedules
 * from which the end user selects.
 * @param callParams Not required.
 * @param successBlock Block which would be called with an array of retrieved schedules when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getAllSchedules:(NSDictionary *)callParams
                success:(void (^)(AylaResponse *response, NSArray *schedules))successBlock
                failure:(void (^)(AylaError *err))failureBlock;

/**
 * The method results in the schedule matching the given name being returned to the handler. The AylaSchedule instance includes the schedule properties
 * and the asssociated Schedule Actions. This method is typically used to provide complete schedule information for a top-level schedule selected from a
 * list populated by the getAllSchedules method.
 * @param scheduleName is the given name returned schedule should match.
 * @param successBlock Block which would be called with a schedule matching @param sheduleName when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getScheduleByName:(NSString *)scheduleName
                success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
                failure:(void (^)(AylaError *err))failureBlock;

/**
 * This updateSchedule method is used to update/change schedule object and associated Schedule Action properties. When using the Full Template Schedule
 * Model,(schedules and Actions are pre-created in the OEM template), this method will PUT the data to existing schedule and action instances passed in 
 * as parameters. When using the Dynamic Template Schedule Model, (schedules are precreated in the OEM template, Schedule Actions are dynamically created
 * and deleted), this method will create and delete the Actions as required if newly allocated scheduleAction object(s) are passed in as parameters.
 * @param schedule is the current schedule object set to desired values.
 * @param successBlock Block which would be called with this updated schedule when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) updateSchedule:(AylaSchedule *)schedule
               success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
               failure:(void (^)(AylaError *err))failureBlock;

/**
 * The clearSchedule method will delete the Schedule Actions associated with the Schedule instance and also set the schedule.active value to false. Consider 
 * the clear method a virtual delete method for the Dynamic Action Schedule Model. DO NOT use clear when implementing the Full Template model as it will 
 * delete the Actions. Instead, simply set schedule.active (and optionally the associated scheduleAction[].active values) to false using the updateSchedule 
 * method.
 * @param schedule is the Schedule to be cleared.
 * @param successBlock Block which would be called with this cleared schedule when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) clearSchedule:(AylaSchedule *)schedule
              success:(void (^)(AylaResponse *response, AylaSchedule *schedule))successBlock
              failure:(void (^)(AylaError *err))failureBlock;

//------------------ Device notification pass-through methods ---------------
/**
 * A pass-through method to a new device notification to the Ayla Cloud Service.
 * @param params Not required.
 * @param successBlock Block which would be called with this retrieved device notifications when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getNotifications:(NSDictionary *)params
              success:(void (^)(AylaResponse *response, NSMutableArray *deviceNotifications))successBlock
              failure:(void (^)(AylaError *err))failureBlock;

/**
 * A pass-through method to get all the Device Notifications for this device from the Ayla Cloud Service.
 * @param deviceNotification The device notification to be created
 * @param successBlock Block which would be called with this created device notifications when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) createNotification:(AylaDeviceNotification *)deviceNotification
              success:(void (^)(AylaResponse *response, AylaDeviceNotification *createdDeviceNotification))successBlock
              failure:(void (^)(AylaError *err))failureBlock;

/**
 * A pass-through method to update an instantiated Device Notifications for this device from the Ayla Cloud Service.
 * @param deviceNotification The device notification to be updated
 * @param successBlock Block which would be called with this updated device notifications when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) updateNotification:(AylaDeviceNotification *)deviceNotification
              success:(void (^)(AylaResponse *response, AylaDeviceNotification *updatedDeviceNotification))successBlock
              failure:(void (^)(AylaError *err))failureBlock;

/**
 * A pass-through method to remove an instantiated Device Notifications for this device from the Ayla Cloud Service.
 * @param deviceNotification The device notification to be removed
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) destroyNotification:(AylaDeviceNotification *)deviceNotification
               success:(void (^)(AylaResponse *response))successBlock
               failure:(void (^)(AylaError *err))failureBlock;

//-------------------- Time Zone Support -----------------------
/**
 * This method gets the existing timezone information from the Ayla Device Service for this device.
 * @param callParams Not required.
 * @param successBlock Block which would be called with retrieved time zone information of this device when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getTimeZoneLocation:(NSDictionary *)callParams
            success:(void (^)(AylaResponse *response, AylaTimeZone *timeZone))successBlock
            failure:(void (^)(AylaError *err))failureBlock;

/**
 * This method updates the existing timezone information from the Ayla Device Service for this device.
 * @param timeZone The device's time zone to be updated.
 * @param successBlock Block which would be called with the updated time zone information when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) updateTimeZoneLocation:(AylaTimeZone *)timeZone
            success:(void (^)(AylaResponse *response, AylaTimeZone *updatedTimeZone))successBlock
            failure:(void (^)(AylaError *err))failureBlock;

//-------------------- Device datum pass-through ------------------
/**
 * This method instantiates a metadata object on the Ayla Device Cloud Service for the this device.
 * @param datum A valid datum which contains a key-value pair.
 * @param successBlock Block which would be called with created datum when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) createDatum:(AylaDatum *)datum
                              success:(void (^)(AylaResponse *response, AylaDatum *newDatum))successBlock
                              failure:(void (^)(AylaError *err))failureBlock;

/**
 * This method retrieves an existing metadata object on the Ayla Device Cloud Service for the current device based on the input key.
 * @param key The key of the metadata object to retrieve.
 * @param successBlock Block which would be called with retrieved datum when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getDatumWithKey:(NSString *)key
                         success:(void (^)(AylaResponse *response, AylaDatum *datum))successBlock
                         failure:(void (^)(AylaError *error))failureBlock;

/**
 * This method updates an existing metadata object on the Ayla Device Cloud Service for the current device.
 * @param datum The datum to be deleted.
 * @param successBlock Block which would be called with updated datum when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) updateDatum:(AylaDatum *)datum
                      success:(void (^)(AylaResponse *response, AylaDatum *updatedDatum))successBlock
                      failure:(void (^)(AylaError *err))failureBlock;

/**
 * This method removes an existing metadata object on the Ayla Device Cloud Service for the current device.
 * @param datum The datum to be removed.
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)deleteDatum:(AylaDatum *)datum
                     success:(void (^)(AylaResponse *response))successBlock
                     failure:(void (^)(AylaError *error))failureBlock;


//--------------------- User share pass-through methods --------------------------

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
 * A user can't have more than one share for the same resource_name and resource_id.
 *
 * @param share The share object to be created
 * @param successBlock Block which would be called with created share when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)createShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *resp, AylaShare *share))successBlock
                     failure:(void (^)(AylaError *error))failureBlock;

/**
 * This instance method is used to retrieve an existing share the Ayla Service based on a given id.
 * @param id The id whose value will be retrieved
 * @param successBlock Block which would be called with the retrieved share when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getShareWithId:(NSString *)id
                    success:(void (^)(AylaResponse *resp, AylaShare *share))successBlock
                    failure:(void (^)(AylaError *error))failureBlock;

/**
 * This instance method is used to retrieve existing share objects from the Ayla Cloud Service
 * May be called from an owner pass-through method in AylaDevice to auto filter by class/type
 * @param successBlock Block which would be called with the retrieved shares when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getSharesWithSuccess:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                   failure:(void (^)(AylaError *err))failureBlock;

/**
 * This class method is used to retrieve all existing "device" type share objects from the Ayla Cloud Service
 * @param successBlock Block which would be called with the retrieved shares when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)getAllSharesWithSuccess:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                                 failure:(void (^)(AylaError *err))failureBlock;

/**
 * getReceivedShares
 * This instance method is used to retrieve existing received share objects from the Ayla Cloud Service
 * May be called from an owner pass-through method in AylaDevice to auto filter by class/type
 * @param successBlock Block which would be called with the retrieved shares when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getReceivedSharesWithSuccess:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                              failure:(void (^)(AylaError *err))failureBlock;

/**
 * This class method is used to retrieve all existing received "device" type share objects from other users
 * @param successBlock Block which would be called with the retrieved shares when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)getAllReceivedSharesWithSuccess:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                                         failure:(void (^)(AylaError *err))failureBlock;

/**
 * This instance method is used to update a share on the Ayla Service.
 * @param share The share object to be updated
 * @param successBlock Block which would be called with the updated share when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 */
- (NSOperation *)updateShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *resp, AylaShare *updatedShare))successBlock
                     failure:(void (^)(AylaError *error))failureBlock;

/**
 * This instance method is used to delete an existing share on the Ayla Service.
 * @param share The share object to be deleted
 * @param successBlock which would be called when request is succeeded.
 * @param failureBlock which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 */
- (NSOperation *)deleteShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *response)) successBlock
                     failure:(void (^)(AylaError *err))failureBlock;

//------------------------------ Grant ----------------------------
/**
 * Use this method to check whether this device is owned by current user.
 * @return true if the registered/currentUser is the owner of this device
 */
- (BOOL)amOwner;

//------------------------------ Lan Mode ------------------------------

/**
 * This method enables direct communication with the device after the application/activity has been LAN enabled. Call this message before any other
 * AylaDevice methods to leverage direct communication. If the direct communication with the device is determined, a standard SUCCESS/FAILURE message is
 * sent to the AylaLanMode notification handler. Subsequent calls to get property values should wait until LAN Mode enablement has been determined. If
 * successful direct communication with the device is established, the receipt of a SUCCESS message by the notification handler will signal property changes
 * from the device. The notification is generic and does not specify the nature of the change. Therefore, the application should immediately perform
 * getProperties to assess the impact of the changes. See section LAN Mode Support of iAyla Mobile Library document for details.
 */
- (void) lanModeEnable;

/**
 * This method is called when LAN mode connection to LME device is no longer required. Then library will stop responding any message from or to this device.
 * All requests will be sent to service after this method is called. See section LAN Mode Support of iAyla Mobile Library document for details.
 */
- (void) lanModeDisable;

/**
 * Cancel a read-from-memory flag. Must be used when property change(s) from the module is notified to app and app is not going to take this/these change(s) from library.
 */
- (void) notifyAcknowledge;

/**
 *  Get current lan mode state of this device
 */
- (enum lanModeSession) lanModeState;

/**
 * Cancel all outstanding requests.
 */
+ (void) cancelAllOutstandingRequests;

@end

//------------------------------------- AylaProperty --------------------------
@interface AylaProperty : NSObject

// Device Property Properties
/** Base type */
@property (nonatomic, copy) NSString *baseType;

/** Property Name */
@property (nonatomic, copy) NSString *name;

/** Property Type */
@property (nonatomic, copy, readonly) NSString *type;

/** Direction (From device or To device) */
@property (nonatomic, copy) NSString *direction;

/** Last Retrieval Time */
@property (nonatomic, copy) NSDate   *retrievedAt;

/** Value */
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *dataUpdatedAt;

/** Property Display Name*/
@property (nonatomic, copy) NSString *displayName;

/** Dsn of property owner */
@property (nonatomic, copy) NSString *owner;

/** If Datapoint Ack has been enabled for current property  */
@property (nonatomic, readonly) BOOL ackEnabled;

/** Timestamp indicating when datapoint ack is received. */
@property (nonatomic, copy, readonly) NSDate *ackedAt;

/** Datapoint ack status */
@property (nonatomic, readonly) NSInteger ackStatus;

/** Datapoint ack message */
@property (nonatomic, readonly) NSInteger ackMessage;

// Overided datapoints and datapoint setters
/** Latest known datapoint */
@property (nonatomic, copy) AylaDatapoint *datapoint;
@property (nonatomic, copy) NSMutableArray *datapoints;

@property (nonatomic, copy) AylaPropertyTrigger *propertyTrigger;
@property (nonatomic, copy) NSArray *propertyTriggers;

/** Metadata of property */
@property (nonatomic, strong) NSMutableDictionary *metadata;

/**
 * This instance method will instantiate a new property detail object from the Ayla device service and retrieve its associated triggers.  Use this call
 * only if additional property detail is required. Note that callParams will be applied to qualify the property triggers associated with this property.
 * In almost all cases, using the getDatapoints or getTriggers method with properties summary object are the preferred and more efficient calls.
 * @param callParams is not required.
 * @param successBlock Block which would be called with this property when request is succeeded.
 * @param successBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getPropertyDetail:(NSDictionary *)callParams
                   success:(void (^)(AylaResponse *response, AylaProperty *propertyUpdated))successBlock
                   failure:(void (^)(AylaError *err))failureBlock;

/**
 * Upon successful completion this instance method will post the value to the Ayla device service and instantiate a new datapoint object.
 * @param datapoint is the datapoint to be created
 * @param successBlock Block which would be called with this created datapoint when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) createDatapoint:(AylaDatapoint *)datapoint
                 success:(void (^)(AylaResponse *response, AylaDatapoint *datapointCreated))successBlock
                 failure:(void (^)(AylaError *err))failureBlock;

/**
 * Upon successful completion this instance method will post the value to the Ayla device service and instantiate a new datapoint object.
 * @note If this datapoint is created for an ACK enabled property, this request will trigger an additional step to poll ACK status.
 *  HTTP error code AML_ERROR_REQUEST_TIMEOUT would be returned when all retries are exhausted and ACK status is still unkown.
 * @param datapoint is the datapoint to be created
 * @param callParams can contain following available parameters:
 *      @p kAylaPropertyParamDatapointPollingRetries - <NSNumber *> Number of retries. This param will be ignored if property is not ACK enabled.
 *      @p kAylaPropertyParamDatapointPollingTimeInterval - <NSNumber *> Time interval between retries. This param will be igonred if property is not ACK enabled.
 * @param successBlock Block which would be called with this created datapoint when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) createDatapoint:(AylaDatapoint *)datapoint params:(NSDictionary *)callParams
                          success:(void (^)(AylaResponse *response, AylaDatapoint *datapointCreated))successBlock
                          failure:(void (^)(AylaError *err))failureBlock;

/**
 * Upload a file to Ayla Service.
 * Support to upload from a file or from a NSData object.
 * @param callParams needs to pass one of following two params:
 *   @p kAylaBlobFileData - <NSData *> file data.
 *   @p kAylaBlobFileUrl - <NSUrl *> absolute file path, including file name & extension.
 * @param successBlock Block which would be called with a created blob datapoint when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (void) createBlob:(NSDictionary *)callParams
        success:(void (^)(AylaResponse *response, AylaDatapointBlob *datapointCreated))successBlock
        failure:(void (^)(AylaError *err))failureBlock;

/**
 * This instance method returns datapoints for a given property. getDatapointsByActivity returns datapoints in the order they were created.
 * @param callParams is applied to qualify the datapoints returned and the maximum number of datapoints returned per query will be limited to maxCount in AylaSystemUtils. Time range filter are provided by setting the following parameters:
 *    @p kAylaPropertyParamDatapointSinceDate - <NSString *> since created time of datapionts with format "YYYY-MM-DD HH:mm:ss"
 *    @p kAylaPropertyParamDatapointEndDate   - <NSString *> end created time of datapionts with format "YYYY-MM-DD HH:mm:ss"
 * @param successBlock Block which would be called with array of retrieved datapoints when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getDatapointsByActivity:(NSDictionary *)callParams
                         success:(void (^)(AylaResponse *response, NSArray *datapoints))successBlock
                         failure:(void (^)(AylaError *err))failureBlock;

/**
 * This instance method returns a datapoint which matching the given id for current property.
 * @param callParams is not in-use. Set to be nil.
 * @param successBlock Block which would be called with retrieved datapoint when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getDatapointById:(NSString *)datapointId params:(NSDictionary *)callParams
                           success:(void (^)(AylaResponse *response, AylaDatapoint *datapoint))successBlock
                           failure:(void (^)(AylaError *err))failureBlock;

/**
 *  Download blob datapoints of a stream/file property
 *  @param callParams could contain following available params:
 *  @param successBlock Block which would be called with array of retrieved blob datapoints when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
- (NSOperation *) getBlobsByActivity:(NSDictionary *)callParams
                         success:(void (^)(AylaResponse *response, NSArray *retrievedDatapoints))successBlock
                         failure:(void (^)(AylaError *err))failureBlock;

/**
 *  Download stream file from a stream/file blob datapoint.
 *  @param callParams could contain following available params:
 *      @p kAylaBlobFileLocalPath - declare a local dir where downloaded file will be stored. by default, it would be stored in default main folder.
 *      @p kAylaBlobFileSuffixName - declare the suffix name of the downloaded file. by default it's BlobStream
 *  @return retrievedBlobs will return the file name of the file downloaded. file name will follow the format Blob_<suffix name>. App needs to follow its declared local path to reach the file.
 *  @note: this api only works for a datapoint belonging to a stream/file type property
 */
- (void) getBlobSaveToFlie:(AylaDatapointBlob *)datapoint params:(NSDictionary *)callParams
                    success:(void (^)(AylaResponse *response, NSString *retrieveBlobFileName))successBlock
                    failure:(void (^)(AylaError *err))failureBlock;


/**
 * Post a new property trigger associated with this property. See section Device Service – Property Triggers in iAyla Mobile Library document for details.
 * @param propertyTrigger is the property trigger to be created
 * @param successBlock Block which would be called with "created AylaProperyTrigger" object when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) createTrigger:(AylaPropertyTrigger *)propertyTrigger
               success:(void (^)(AylaResponse *response, AylaPropertyTrigger *propertyTriggerCreated))successBlock
               failure:(void (^)(AylaError *err))failureBlock;

/**
 * Get all the property triggers associated with the property.
 * @param callParams is not required.
 * @param successBlock Block which would be called with a mutable array of property triggers when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getTriggers:(NSDictionary *)callParams
             success:(void (^)(AylaResponse *response, NSArray *propertyTriggers))successBlock
             failure:(void (^)(AylaError *err))failureBlock;

/**
 * Update one property trigger associated with the property.
 * @param propertyTrigger is the property trigger to be updated.
 * @param successBlock Block which would be called with the updated trigger when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) updateTrigger:(AylaPropertyTrigger *)propertyTrigger
                       success:(void (^)(AylaResponse *response, AylaPropertyTrigger *propertyTrigger))successBlock
                       failure:(void (^)(AylaError *err))failureBlock;

/**
 * Call this method to destroy a dedicated property trigger.
 * @param propertyTrigger is the property trigger to be destroyed.
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) destroyTrigger:(AylaPropertyTrigger *)propertyTrigger
                success:(void (^)(AylaResponse *response))successBlock
                failure:(void (^)(AylaError *err))failureBlock;

@end

extern NSString * const kAylaRegistrationParamWindowLength;

extern NSString * const kAylaPropertyParamDatapointCount;
extern NSString * const kAylaPropertyParamDatapointIsAcked;
extern NSString * const kAylaPropertyParamDatapointAckStatus;
extern NSString * const kAylaPropertyParamDatapointPollingRetries;
extern NSString * const kAylaPropertyParamDatapointPollingTimeInterval;
extern NSString * const kAylaPropertyParamDatapointSinceDate;
extern NSString * const kAylaPropertyParamDatapointEndDate;

//------------------------------------- AylaDatapoint --------------------------
@class AylaDatapointBatchRequest;
@class AylaDatapointBatchResponse;
@interface AylaDatapoint : NSObject

/** Id of datapoint */
@property (nonatomic, copy, readonly) NSString *id;

/** Value of datapoint */
@property (nonatomic, copy) NSString *value;

/** When datapoint is created. */
@property (nonatomic, copy) NSString *createdAt;

/** Value of datapoint for following types: boolean, integer, decimal, float */
@property (nonatomic, copy) NSNumber *nValue;

/** Value of datapoint for following types: string */
@property (nonatomic, copy) NSString *sValue;

/** Value of datapoint for following types: string */
@property (nonatomic, strong) NSMutableDictionary *metadata;

/** Retrival time */
@property (nonatomic, copy) NSDate *retrievedAt;

/** Timestamp indicating when datapoint ack is received. */
@property (nonatomic, copy, readonly) NSDate *ackedAt;

/** Datapoint ack status */
@property (nonatomic, readonly) NSInteger ackStatus;

/** Datapoint ack message */
@property (nonatomic, readonly) NSInteger ackMessage;

/** Created at time generated by device */
@property (nonatomic, copy, readonly) NSDate *createdAtFromDevice;

/**
 *  Call this method to create datapoints to multiple properties. These properties must belong to
 *  one device.
 *  
 *  @note This method only supports Cloud flow. Any requests passed into this method will always
 *  be transfered to Cloud service. Library/Cloud will return two possible http status code once
 *  this request is accepted: 201 or 206. 201 means all batch requests have been processed and
 *  accepted; 206 means some requests has been accepted and some are not. Application has to check
 *  statusCode of each batch response to find out which requests have been rejected. Status code
 *  included in each response follows the same rule as http status code returned in create datapoint
 *  api call.
 *
 *  This method will call failure block either local validation has been failed for any batch requests
 *  or the whole request has been fully rejected by Cloud service. Library will set code as 
 *  AML_USER_INVALID_PARAMETERS in returned err to indicate this issue comes from local validation. Then
 *  application can query err.errorInfo for details.
 *
 *  @attention When creating datapoints to ack enabled properties, different to method 
 *  createDatapoint:success:failure, this method will directly invoke callbacks after current request has
 *  been completed. Application has to query with datapoint id to obtatin ack information of a datapoint.
 *
 *  @param request List of datapoint batch requests.
 *  @param successBlock Block which would be called with array of retrieved batch response when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
+ (NSOperation *)createDatapointsWithBatchRequests:(NSArray AYLA_GENERIC(AylaDatapointBatchRequest *) *)requests
                                           success:(void (^)(AylaResponse *response, NSArray AYLA_GENERIC(AylaDatapointBatchResponse *) *))successBlock
                                           failure:(void (^)(AylaError *err))failureBlock;

@end

@interface AylaDatapointBlob : AylaDatapoint

/** Cloud url of the datapoint. */
@property (nonatomic, strong) NSString *url;

/** Declare if file has been uploaded completely. */
@property (nonatomic, assign) BOOL closed;

/**
 * Mark a blob datapoint file as fetched
 * @note: After a file got downloaded. This api could be used to mark the file as fetched. Once a file file marked as fetched. 
 *  It will no longer be retrieved from api getBlobsByActivity:success:failure
 * @param callParams Not required.
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)markFetched:(NSDictionary *)callParams
                     success:(void (^)(AylaResponse *response))successBlock
                     failure:(void (^)(AylaError *err))failureBlock;

@end

extern NSString * const kAylaBlobFileLocalPath;
extern NSString * const kAylaBlobFileSuffixName;
extern NSString * const kAylaBlobFileData;
extern NSString * const kAylaBlobFileUrl;

//---------------------------------- Ayla Lan Mode Config -------------------
@interface AylaLanModeConfig : NSObject

@property (nonatomic, strong) NSNumber *lanipKeyId;
@property (nonatomic, strong) NSString *lanipKey;
@property (nonatomic, strong) NSNumber *keepAlive;
@property (nonatomic, strong) NSString *status;

- (id) initAylaLanModeConfigWithDictionary: (NSDictionary *)dictionary;

- (BOOL) isEnabled;
- (BOOL) isValid;

@end
