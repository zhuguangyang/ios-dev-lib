//
//  AylaTrigger.h
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 7/5/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

@class AylaApplicationTrigger;

//----------------------------------------------- Property Triggers -------------------------------
@interface AylaPropertyTrigger : NSObject

@property (nonatomic, copy) NSString *deviceNickname;
@property (nonatomic, copy) NSString *propertyNickname;
@property (nonatomic, assign) BOOL active;

// Properties for Trigger1
@property (nonatomic, copy) NSString *triggerType;
@property (nonatomic, copy) NSString *compareType;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSDate   *retrievedAt;

// Additional Properties for Trigger2
@property (nonatomic, copy) NSString *period;
@property (nonatomic, copy) NSString *baseType;
@property (nonatomic, copy) NSString *triggeredAt;

@property (nonatomic, copy) AylaApplicationTrigger *applicationTrigger;
@property (nonatomic, copy) NSArray *applicationTriggers;

/**
 * Post a new property trigger associated with input param property. See section Device Service – Property Triggers in iAyla Mobile Library document for details.
 * @param property is the property associated with new created trigger.
 * @param propertTrigger is the property trigger user want to want to create
 * @param success would be called with "created AylaProperyTrigger" object when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *) createTrigger:(AylaProperty *)property propertyTrigger:(AylaPropertyTrigger *)propertyTrigger
               success:(void (^)(AylaResponse *response, AylaPropertyTrigger *propertyTriggerCreated))successBlock
               failure:(void (^)(AylaError *err))failureBlock;

/**
 * Get all the property triggers associated with the property.
 * @param property is the property which retrieved property triggers bind to.
 * @param callParams is not required. Set to nil.
 * @param success would be called with a mutable array of property triggers when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *) getTriggers:(AylaProperty *)property callParams:(NSDictionary *)callParams
             success:(void (^)(AylaResponse *response, NSMutableArray *propertyTriggers))successBlock
             failure:(void (^)(AylaError *err))failureBlock;

/**
 * Update one property trigger associated with the property.
 * @param property is the property which the property trigger bind to.
 * @param success would be called with a mutable array of property triggers when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *) updateTrigger:(AylaProperty *)property propertyTrigger:(AylaPropertyTrigger *)propertyTrigger
                       success:(void (^)(AylaResponse *response, AylaPropertyTrigger *propertyTriggerCreated))successBlock
                       failure:(void (^)(AylaError *err))failureBlock;

/**
 * Destroy a dedicated property trigger.
 * @param propertTrigger is the property trigger to be destroyed.
 * @param success would be called when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *) destroyTrigger:(AylaPropertyTrigger *)propertyTrigger
                success:(void (^)(AylaResponse *response))successBlock
                failure:(void (^)(AylaError *err))failureBlock;


/**
 * Used to post a new text message application trigger to the Ayla Cloud Service. See section Application Triggers for details on 
   the AylaApplicationTrigger class in iAyla Mobile Library document.
 * @param applicationTrigger is the trigger to be created.
 * @param success would be called with a created ApplicationTrigger when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) createSmsApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
               success:(void (^)(AylaResponse *response, AylaApplicationTrigger *ApplicationTriggerCreated))successBlock
               failure:(void (^)(AylaError *err))failureBlock;

/**
 * Used to post a new email message application trigger to the Ayla Cloud Service. See section Application Triggers for details on
   the AylaApplicationTrigger class in iAyla Mobile Library document.
 * @param applicationTrigger is the one to be created.
 * @param success would be called with a created ApplicationTrigger when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) createEmailApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                  success:(void (^)(AylaResponse *response, AylaApplicationTrigger *ApplicationTriggerCreated))successBlock
                  failure:(void (^)(AylaError *err))failureBlock;

/**
 * Used to post a new push notification application trigger to the Ayla Cloud Service. See section Application Triggers for details on
 * the AylaApplicationTrigger class in iAyla Mobile Library document.
 * @param applicationTrigger is the one to be created.
 * @param success would be called with a created ApplicationTrigger when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) createPushApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                             success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerCreated))successBlock
                             failure:(void (^)(AylaError *err))failureBlock;

/**
 * Get all the application triggers for the given property.
 * @param callParams is required, set to nil.
 * @param success would be called with a mutable array of appication triggers when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) getApplicationTriggers:(NSDictionary *)callParams
                        success:(void (^)(AylaResponse *response, NSMutableArray *applicationTrigger))successBlock
                        failure:(void (^)(AylaError *err))failureBlock;

/**
 * Used to update a text message application trigger to the Ayla Cloud Service. See section Application Triggers for details on
 * the AylaApplicationTrigger class in iAyla Mobile Library document.
 * @param applicationTrigger is the trigger to be updated.
 * @param success would be called with a updated ApplicationTrigger when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) updateSmsApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                                   success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerUpdated))successBlock
                                   failure:(void (^)(AylaError *err))failureBlock;

/**
 * Used to update an email message application trigger to the Ayla Cloud Service. See section Application Triggers for details on
 * the AylaApplicationTrigger class in iAyla Mobile Library document.
 * @param applicationTrigger is the trigger to be updated.
 * @param success would be called with a updated ApplicationTrigger when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) updateEmailApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                                        success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerUpdated))successBlock
                                        failure:(void (^)(AylaError *err))failureBlock;

/**
 * Used to update a push notification application trigger to the Ayla Cloud Service. See section Application Triggers for details on
 * the AylaApplicationTrigger class in iAyla Mobile Library document.
 * @param applicationTrigger is the trigger to be updated.
 * @param success would be called with a updated ApplicationTrigger when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) updatePushApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                                       success:(void (^)(AylaResponse *response, AylaApplicationTrigger *applicationTriggerUpdated))successBlock
                                       failure:(void (^)(AylaError *err))failureBlock;

/**
 * Destroy a single application trigger
 * @param applicationTrigger is the trigger to be destroyed
 * @param success would be called with a mutable array of appication triggers when request is succeeded.
 * @param failure would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *) destroyApplicationTrigger:(AylaApplicationTrigger *)applicationTrigger
                           success:(void (^)(AylaResponse *response))successBlock
                           failure:(void (^)(AylaError *err))failureBlock;

@end

//---------------------------------------------- Application Triggers -------------------------------
@interface AylaApplicationTrigger : NSObject

@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSNumber *contactId;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *message;

@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *emailTemplateId;
@property (nonatomic, copy) NSString *emailSubject;
@property (nonatomic, copy) NSString *emailBodyHtml;

@property (nonatomic, copy) NSString *registrationId;
@property (nonatomic, copy) NSString *applicationId;
@property (nonatomic, copy) NSString *pushSound;
@property (nonatomic, copy) NSString *pushData;

@property (nonatomic, copy) NSDate   *retrievedAt;

@end
