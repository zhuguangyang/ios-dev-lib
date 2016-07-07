//
//  AylaContact.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 1/13/15.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AylaResponse;
@class AylaError;

@interface AylaContact : NSObject

/** Contact id */
@property (nonatomic, strong) NSNumber *id;

/** Contact first name */
@property (nonatomic, strong) NSString *firstName;

/** Contact last name */
@property (nonatomic, strong) NSString *lastName;

/** Contact display name */
@property (nonatomic, strong) NSString *displayName;

/** Contact email address */
@property (nonatomic, strong) NSString *email;

/** Contact phone number's country code */
@property (nonatomic, strong) NSString *phoneCountryCode;

/** Contact phone number */
@property (nonatomic, strong) NSString *phoneNumber;

/** Contact address - street address */
@property (nonatomic, strong) NSString *streetAddress;

/** Contact address - zip code */
@property (nonatomic, strong) NSString *zipCode;

/** Contact address - country */
@property (nonatomic, strong) NSString *country;

/** Accept status of email notification. Could be one of followings: AylaContactAcceptNotReq, AylaContactAcceptReq, AylaContactAcceptPending, AylaContactAcceptAccepted, AylaContactAcceptDenied */
@property (nonatomic, strong) NSString *emailAccept;

/** If email notifications have been enabled for current contact. */
@property (nonatomic, assign) BOOL      emailNotification;

/** Accept status of SMS notification. Could be one of followings: AylaContactAcceptNotReq, AylaContactAcceptReq, AylaContactAcceptPending, AylaContactAcceptAccepted, AylaContactAcceptDenied */
@property (nonatomic, strong) NSString *smsAccept;

/** If SMS notifications have been enabled for current contact. */
@property (nonatomic, assign) BOOL      smsNotification;

/** If PUSH notifications have been enabled for current contact. */
@property (nonatomic, assign) BOOL      pushNotification;

/** Contact metadata */
@property (nonatomic, strong) NSString *metadata;

/** Contact notes */
@property (nonatomic, strong) NSString *notes;

/** Array of devices' oem models */
@property (nonatomic, strong) NSArray  *oemModels;

/** Last update time */
@property (nonatomic, strong, readonly) NSString *updatedAt;

/**
 *  Use this method to create a new contact for current user.
 *  @param contact The contact to be created.
 *  @param callParams Not required, set to nil.
 *  @param successBlock Block which would be called with created contact when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
+ (NSOperation *)create:(AylaContact *)contact withParams:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *resp, AylaContact *createdContact))successBlock
               failure:(void (^)(AylaError *error))failureBlock;

/**
 *  Use this method to get a contact with contact Id.
 *  @param contactId Id or requested contact.
 *  @param callParams Not required, set to nil.
 *  @param successBlock Block which would be called with a contact when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
+ (NSOperation *)getWithId:(NSNumber *)contactId params:(NSDictionary *)callParams
                   success:(void (^)(AylaResponse *resp, AylaContact *contact))successBlock
                   failure:(void (^)(AylaError *error))failureBlock;

/**
 *  Use this method to get a list of contacts with input params.
 *  @param callParams Pass-in parameters will be used as filters when querying for contacts.
 *  @param successBlock Block which would be called with an array of retrieved contacts when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
+ (NSOperation *)getAllWithParams:(NSDictionary *)callParams
                          success:(void (^)(AylaResponse *resp, NSArray *contacts))successBlock
                          failure:(void (^)(AylaError *error))failureBlock;

/**
 *  This method is used to update an existing contact
 *  @param contact The contact to be updated.
 *  @param callParams Dictionary of to-be-updated contact infos.
 *  @param successBlock Block which would be called with updated contact when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
+ (NSOperation *)update:(AylaContact *)contact withParams:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *resp, AylaContact *updatedContact))successBlock
               failure:(void (^)(AylaError *error))failureBlock;

/**
 *  This method is used to delete a contact.
 *  @param contact The contact to be deleted.
 *  @param callParams Not required.
 *  @param successBlock Block which would be called when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
+ (NSOperation *)delete:(AylaContact *)contact withParams:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *resp))successBlock
               failure:(void (^)(AylaError *error))failureBlock;

@end

extern NSString * const kAylaContactParamFirstName;
extern NSString * const kAylaContactParamLastName;
extern NSString * const kAylaContactParamDisplayName;
extern NSString * const kAylaContactParamEmail;
extern NSString * const kAylaContactParamPhoneCountryCode;
extern NSString * const kAylaContactParamPhoneNumber;
extern NSString * const kAylaContactParamStreetAddress;
extern NSString * const kAylaContactParamZipCode;
extern NSString * const kAylaContactParamCountry;

extern NSString * const kAylaContactParamMetadata;
extern NSString * const kAylaContactParamNotes;
extern NSString * const kAylaContactParamOemModels;

extern NSString * const kAylaContactParamEmailAccept;
extern NSString * const kAylaContactParamEmailNotification;
extern NSString * const kAylaContactParamSmsAccept;
extern NSString * const kAylaContactParamSmsNotification;
extern NSString * const kAylaContactParamPushNotification;

extern NSString * const kAylaContactParamFilter;

extern NSString * const AylaContactAcceptNotReq;
extern NSString * const AylaContactAcceptReq;
extern NSString * const AylaContactAcceptPending;
extern NSString * const AylaContactAcceptAccepted;
extern NSString * const AylaContactAcceptDenied;
