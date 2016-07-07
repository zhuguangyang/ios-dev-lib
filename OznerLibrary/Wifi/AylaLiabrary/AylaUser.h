//
//  AylaUser.h
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 6/28/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//
#import "AylaShare.h"
@class AylaDatum;
@class AylaContact;
@class UIWebView;
@interface AylaUser : NSObject

/** User's access token */
@property (nonatomic, readonly) NSString *accessToken;

/** User's refresh token */
@property (nonatomic, readonly) NSString *refreshToken;

/** Expire in time of current access token */
@property (nonatomic, readonly) NSUInteger expiresIn;

/** User's email address */
@property (nonatomic, strong) NSString *email;

/** User's first name */
@property (nonatomic, strong) NSString *firstName;

/** User's last name */
@property (nonatomic, strong) NSString *lastName;

/** User's country code in phone number */
@property (nonatomic, strong) NSString *phoneCountryCode;

/** User's phone number */
@property (nonatomic, strong) NSString *phone;

/** User's company name */
@property (nonatomic, strong) NSString *company;

/** User's address - street */
@property (nonatomic, strong) NSString *street;

/** User's address - city */
@property (nonatomic, strong) NSString *city;

/** User's address - city */
@property (nonatomic, strong) NSString *state;

/** User's address - zip code */
@property (nonatomic, strong) NSString *zipCode;

/** User's address - country */
@property (nonatomic, strong) NSString *country;

/** User's development kit number */
@property (nonatomic, assign) NSUInteger devKitNum;

/** If terms & conditions has been accepted by user. */
@property (nonatomic, assign) BOOL termsAccepted;

@property (nonatomic, strong) NSMutableArray *shares;
@property (nonatomic, strong) AylaShare *share;

/** Role related attributes */
@property (nonatomic, strong, readonly) NSString *role;

/**
 * Use this method to provide user access to the devices registered with their Ayla account. It handles all user authentication
 * and credentialing. Therefore, after loadSavedSettings, this is the first method that must be called prior to accessing any Ayla Cloud
 * Service.
 * @param userName User account email address.
 * @param password User account password.
 * @param appId Ayla supplied application identity.
 * @param appSecret Ayla supplied application secret.
 * @param successBlock Block which would be called when login request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)login:(NSString *)userName password:(NSString *)password appId:(NSString *)appId appSecret:(NSString *)appSecret
                        success:(void (^)(AylaResponse *response, AylaUser *user))successBlock
                        failure:(void (^)(AylaError *err))failureBlock;

/**
 * Use this method to process SSO with token from external identity provider. This method must be called to authiciate user
 * credentials prior to accessing any Ayla Cloud Service
 * @param userName User account email address.
 * @param password User account password.
 * @param appId Ayla supplied application identity. Must not be nil.
 * @param appSecret Ayla supplied application secret. Must not be nil.
 * @param token Token from external identity provider.
 * @param successBlock Block which would be called when login request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)ssoLogin:(NSString *)userName
                 password:(NSString *)password
                    token:(NSString *)token
                    appId:(NSString *)appId
                appSecret:(NSString *)appSecret
                  success:(void (^)(AylaResponse *response, AylaUser *user))successBlock
                  failure:(void (^)(AylaError *err))failureBlock;

/**
 * Use this method to refresh user's access token lifetime with a refreshToken
 * @param refreshToken User's refresh token. This token could be retrieved from login method.
 * @param successBlock Block which would be called when login request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @see +login:password:appId:appSecret:success:failure:
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)refreshAccessTokenWithRefreshToken:(NSString *)refreshToken
    success:(void (^)(AylaResponse *response, AylaUser *refreshed))successBlock
    failure:(void (^)(AylaError *err))failureBlock;

/** 
 * Use this method to calculate the remaining lifetime of current access token.
 * @return Seconds to expiry. 0 will be returned if access token has expired or there is no access token in use by the library.
 */
+ (NSUInteger)accessTokenSecondsToExpiry;

/**
 * Use this method to create a new user account on the Ayla Cloud Service. 
 * @param callParams contains user information to complete user sign up. Please see section 2.3.3 signUp in iAyla Mobile Library document for details.
 * @param appId Ayla supplied application identity.
 * @param appSecret Ayla supplied application secret.
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning The following parameters are mandatory for creating a new user account: email, password, firstname, lastname, country. 
 *          Please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)signUp: (NSDictionary *)callParams appId:(NSString *)appId appSecret:(NSString *)appSecret
    success:(void (^)(AylaResponse *response))successBlock
    failure:(void (^)(AylaError *err))failureBlock;

/**
 * Use this method to activate created user account.
 * @param token Must be the confirmation token sent to user after user has signed up a new account.
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning Token is mandatory for this method.
 *          Please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)signUpConfirmationWithToken:(NSString *)token
    success:(void (^)(AylaResponse *response, AylaUser *user))successBlock
    failure:(void (^)(AylaError *err))failureBlock;

/**
 * Use this method to retrieve existing user account information from Ayla Cloud Services. The user must be authenticated, via login, before calling 
 * this method.
 * @param callParams Is not required, so set callParams to nil.
 * @param successBlock Block which would be called with a dictionary of user information when request is succeeded. Please see section 2.3.4 getInfo in iAyla Mobile Library document for details.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)getInfo:(NSDictionary *)callParams
    success:(void (^)(AylaResponse *response, NSDictionary *informations))successBlock
    failure:(void (^)(AylaError *err))failureBlock;

/**
 * Use this method to change the user’s password. This method may be called only after the user has successfully completed login.
 * @param currentPassword User's current password
 * @param newPassword New password
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)changePassword:(NSString *)currentPassword newPassword:(NSString *)newPassword
    success:(void (^)(AylaResponse *response))successBlock
    failure:(void (^)(AylaError *err))failureBlock;

/**
 * Use this method to modify existing account information from Ayla Cloud Services. The user must be authenticated, via login, before calling this method.
 * @param callParams Parameters which contains new user information. Please see section 2.3.5 updateUserInfo in iAyla Mobile Library document for details.
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)updateUserInfo:(NSDictionary *)callParams
    success:(void (^)(AylaResponse *response))successBlock
    failure:(void (^)(AylaError *err))failureBlock;

/**
 * @deprecated This method has been deprecated. Use -logoutWithParams:success:failure: instead
 * @see -logoutWithParams:success:failure:
 */
+ (NSOperation *)logout:(NSString *)accessToken
    success:(void (^)(AylaResponse *response))successBlock
    failure:(void (^)(AylaError *err))failureBlock DEPRECATED_ATTRIBUTE;

/**
 * This method will log the user off of the Ayla cloud service and remove security credentials preventing subsequent network transactions.
 * @note By default, this api no longer cleans library caches. Set @p kAylaUserLogoutClearCache if caches need to be cleaned.
 * @param callParams A dictionary of call parameters. Currently accepted params - @p kAylaUserLogoutClearCache: @(YES) or @(NO).
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)logoutWithParams:(NSDictionary *)callParams
                          success:(void (^)(AylaResponse *response))successBlock
                          failure:(void (^)(AylaError *err))failureBlock;

/**
 * @deprecated This method has been deprecated. Use -resetPassword:appId:appSecret:andParams:success:failure: instead
 * @see -resetPassword:appId:appSecret:andParams:success:failure:
 */
+ (NSOperation *)resetPassword:(NSString *)mailAddress
                    withParams:(NSDictionary *)params
                       success:(void (^)(AylaResponse *response))successBlock
                       failure:(void (^)(AylaError *err))failureBlock DEPRECATED_ATTRIBUTE;

/**
 * This method will delete the users existing password and send a reset password link to their registered email address.
 * @param mailAddress User's registered mail address.
 * @param appId Ayla supplied application identity.
 * @param appSecret Ayla supplied application secret.
 * @param params Use to send supported optional params: @p iAML_EMAIL_TEMPLATE_ID : registered email template id
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)resetPassword:(NSString *)mailAddress
                         appId:(NSString *)appId
                     appSecret:(NSString *)appSecret
                     andParams:(NSDictionary *)params
                       success:(void (^)(AylaResponse *response))successBlock
                       failure:(void (^)(AylaError *err))failureBlock;

/**
 * This method will help user complete password reset. The new password can then be used to login.
 * @param password User's new password.
 * @param token The token received by user.
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)resetPasswordWithNewPassword:(NSString *)password
                      andToken:(NSString *)token
                       success:(void (^)(AylaResponse *response)) successBlock
                       failure:(void (^)(AylaError *err))failureBlock;

/**
 * @deprecated This method has been deprecated. Use -resendConfirmation:appId:appSecret:andParams:success:failure: instead.
 * @see -resendConfirmation:appId:appSecret:andParams:success:failure:
 */
+ (NSOperation *)resendConfirmation:(NSString *)mailAddress
                withParams:(NSDictionary *)params
                success:(void (^)(AylaResponse *response)) successBlock
                failure:(void (^)(AylaError *err))failureBlock DEPRECATED_ATTRIBUTE;

/**
 * This method will send confirmation token to user email address again.
 * @param mailAddress User's registered mail address.
 * @param appId Ayla supplied application identity.
 * @param appSecret Ayla supplied application secret.
 * @param params could be used to send supported optional params: IAML_EMAIL_TEMPLATE_ID : registered email template id
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)resendConfirmation:(NSString *)mailAddress
                              appId:(NSString *)appId
                          appSecret:(NSString *)appSecret
                          andParams:(NSDictionary *)params
                            success:(void (^)(AylaResponse *response)) successBlock
                            failure:(void (^)(AylaError *err))failureBlock;

/**
 * This method will delete existing user account from the Ayla cloud service.
 * @param callParams is not required, set it to nil
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)delete:(NSDictionary *) callParams
              success:(void (^)(AylaResponse *response)) successBlock
              failure:(void (^)(AylaError *err))failureBlock;

/** 
 * Current logged in user.
 * @return User object.
 */
+ (AylaUser *)currentUser;

/**
 * This method will attempt to refresh access token for +currentUser
 */
+ (void)refreshAccessTokenOnExpiry;


//--------------------- User datum pass-through -----------------------
/**
 * This method instantiates a metadata object on the Ayla User Cloud Service or the current user.
 * @param datum A valid datum which contains a key-value pair.
 * @param successBlock Block which would be called with created datum when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)createDatum:(AylaDatum *)datum
            success:(void (^)(AylaResponse *response, AylaDatum *newDatum))successBlock
            failure:(void (^)(AylaError *error))failureBlock;

/**
 * This method retrieves an existing metadata object on the Ayla User Cloud Service for the current user based on the input key.
 * @param key The key of the metadata object to retrieve.
 * @param successBlock Block which would be called with retrieved datum when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getDatumWithKey:(NSString *)key
            success:(void (^)(AylaResponse *response, AylaDatum *datum))successBlock
            failure:(void (^)(AylaError *error))failureBlock;

/**
 * This method retrieves existing metadata objects from the Ayla User Cloud Service for the current user.
 * @param params Pass-in parameters. Accept one of the following filters:
 *              - nil : retrieve all datum objects
 *              - a list of one of more key names to retrieve
 *              - a list of patterns where the "%" sign defines wild cards before or after the pattern
 * @param successBlock Block which would be called with retrieved datums when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getDatumWithParams:(NSDictionary *)params
                            success:(void (^)(AylaResponse *response, NSArray *datums))successBlock
                            failure:(void (^)(AylaError *error))failureBlock;

/**
 * This method updates an existing metadata object on the Ayla User Cloud Service for the current user..
 * @param datum The datum going to be deleted
 * @param successBlock Block which would be called with updated datum when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)updateDatum:(AylaDatum *)datum
            success:(void (^)(AylaResponse *response, AylaDatum *updatedDatum))successBlock
            failure:(void (^)(AylaError *error))failureBlock;

/**
 * This method removes an existing metadata object on the Ayla User Cloud Service for the current logged-in user.
 * @param datum The datum going to be removed
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)deleteDatum:(AylaDatum *)datum
            success:(void (^)(AylaResponse *response))successBlock
            failure:(void (^)(AylaError *error))failureBlock;


//---------------------- User share pass-through methods --------------------------

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
 * @param callParams Pass one of the following filters in parameters:
 *            - null: retrieve all share objects
 *            - a "resource_name": the resource class/type to retrieve. Currently only "device" is supported
 *            - a "resource_id": the specific resource id to be retrieved. Currently only a device.dsn is supported
 *              If resourceId is specified, resourceName is required.
 * @param successBlock Block which would be called with the retrieved shares when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getShares:(NSDictionary *)callParams
                   success:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                   failure:(void (^)(AylaError *err))failureBlock;

/**
 * This class method is used to retrieve all existing share objects from the Ayla Cloud Service
 * May be called from an owner pass-through method in AylaDevice to auto filter by class/type
 * @param callParams Accept one of the following filters:
 *            - null: retrieve all share objects
 *            - a "resource_name": the resource class/type to retrieve. Currently only "device" is supported
 *            - a "resource_id": the specific resource id to be retrieved. Currently only a device.dsn is supported
 *              If resourceId is specified, resourceName is required.
 * @param successBlock Block which would be called with the retrieved shares when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)getAllShares:(NSDictionary *)callParams
            success:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
            failure:(void (^)(AylaError *err))failureBlock;

/**
 * This instance method is used to retrieve existing share objects received from other users
 * May be called from an owner pass-through method in AylaDevice to auto filter by class/type
 * @param callParams Accept one of the following filters:
 *            - null: retrieve all share objects
 *            - a "resource_name": the resource class/type to retrieve. Currently only "device" is supported
 *            - a "resource_id": the specific resource id to be retrieved. Currently only a device.dsn is supported
 *              If resourceId is specified, resourceName is required.
 * @param successBlock Block which would be called with the received shares when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)getReceivedShares:(NSDictionary *)callParams
                     success:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                     failure:(void (^)(AylaError *err))failureBlock;

/**
 * This class method is used to retrieve all existing share objects received from other users
 * May be called from an owner pass-through method in AylaDevice to auto filter by class/type
 * @param callParams Accept one of the following filters:
 *            - null: retrieve all share objects
 *            - a "resource_name": the resource class/type to retrieve. Currently only "device" is supported
 *            - a "resource_id": the specific resource id to be retrieved. Currently only a device.dsn is supported
 *              If resourceId is specified, resourceName is required.
 * @param successBlock Block which would be called with the received shares when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (NSOperation *)getAllReceivedShares:(NSDictionary *)callParams
                           success:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                           failure:(void (^)(AylaError *err))failureBlock;

/**
 * This instance method is used to update a share on the Ayla Service.
 * @param share The share object to be updated
 * @param successBlock Block which would be called with the updated share when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)updateShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *resp, AylaShare *updatedShare))successBlock
                     failure:(void (^)(AylaError *error))failureBlock;

/**
 * This instance method is used to delete an existing share on the Ayla Service.
 * Typical usage is to call this method from the owner pass-through methods AylaDevice or AylaUser
 * @param share The share object to be deleted
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @return NSOperation instance
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
- (NSOperation *)deleteShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *response)) successBlock
                     failure:(void (^)(AylaError *err))failureBlock;

//---------------------- User Contact pass-through methods --------------------------

/**
 *  Use this method to create a new contact for current user.
 *  @param contact The contact to be created.
 *  @param callParams Not used, set to be nil.
 *  @param successBlock Block which would be called with created contact when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
- (NSOperation *)createContact:(AylaContact *)contact withParams:(NSDictionary *)callParams
                       success:(void (^)(AylaResponse *resp, AylaContact *createdContact))successBlock
                       failure:(void (^)(AylaError *error))failureBlock;

/**
 *  Use this method to get a contact with contact Id.
 *  @param contactId Id or requested contact.
 *  @param successBlock Block which would be called with a contact when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
- (NSOperation *)getContactWithId:(NSNumber *)contactId
                   success:(void (^)(AylaResponse *resp, AylaContact *contact))successBlock
                   failure:(void (^)(AylaError *error))failureBlock;

/**
 *  Use this method to get a list of contacts with input params.
 *  @param callParams Pass-in parameters will be used as filters when querying for contacts.
 *  @param successBlock Block which would be called with an array of retrieved contacts when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
- (NSOperation *)getContactsWithParams:(NSDictionary *)callParams
                          success:(void (^)(AylaResponse *resp, NSArray *contacts))successBlock
                          failure:(void (^)(AylaError *error))failureBlock;

/**
 *  This method is used to update an existing contact
 *  @param contact The contact to be updated.
 *  @param callParams Dictionary of to-be-updated contact infos.
 *  @param successBlock Block which would be called with updated contact when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
- (NSOperation *)updateContact:(AylaContact *)contact withParams:(NSDictionary *)callParams
                       success:(void (^)(AylaResponse *resp, AylaContact *updatedContact))successBlock
                       failure:(void (^)(AylaError *error))failureBlock;
/**
 *  This method is used to delete a contact.
 *  @param contact The contact to be deleted.
 *  @param successBlock Block which would be called when request is succeeded.
 *  @param failureBlock Block which would be called with an AylaError object when request is failed.
 */
- (NSOperation *)deleteContact:(AylaContact *)contact
                       success:(void (^)(AylaResponse *resp))successBlock
                       failure:(void (^)(AylaError *error))failureBlock;

/**
 * This pass-through compound method facilitates secure user sign-in through 3rd party credentials via OAuth.
 * @discussion The method performs the following tasks: 1)Retrieve the OAuth Provider URL used for authentication from Ayla User Service 2)Retrieve OAuth provider authCode via WebView after user enters credentials 3)Pass authCode to Ayla User Service for login account validation 4)Return validated AylaUser credentials back to the application.
 * @param type Accept two predefined types. @p aylaOAuthAccountTypeGoogle or @p aylaOAuthAccountTypeFacebook
 * @param webView A webView on which the authentication page would be shown to user.
 * @param appId Ayla supplied application identity.
 * @param appSecret Ayla supplied application secret.
 * @param successBlock Block which would be called when request is succeeded.
 * @param failureBlock Block which would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (void)loginThroughOAUTHWithAccountType:(NSString *)type webView:(UIWebView *)webView AppId:(NSString *)appId andAppSecret:(NSString *)appSecret
                           success:(void (^)(AylaResponse *response)) successBlock
                           failure:(void (^)(AylaError *err))failureBlock;

typedef NSString * AylaOAuthAccountType;
extern NSString * const aylaOAuthAccountTypeGoogle;
extern NSString * const aylaOAuthAccountTypeFacebook;


@end

extern NSString * const kAylaUserLogoutClearCache;

