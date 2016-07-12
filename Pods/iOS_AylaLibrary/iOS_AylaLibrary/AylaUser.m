//
//  AylaUser.m
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 6/28/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaSystemUtilsSupport.h"
#import "AylaOAuth.h"
#import "AylaErrorSupport.h"
#import "AylaReachabilitySupport.h"
#import "AylaContact.h"
#import "AylaConnectionOperationSupport.h"
#import "AylaHTTPOperation.h"
#import "AylaDefines_Internal.h"
#import "NSObject+AylaNetworks.h"
#import "NSString+AylaNetworks.h"
#import "NSString+Validation.h"

@interface AylaUser ()
@property (nonatomic,readwrite) NSString *accessToken;
@property (nonatomic,readwrite) NSString *refreshToken;
@property (nonatomic,readwrite) NSUInteger expiresIn;
@property (nonatomic,readwrite) NSDate *updatedAt;
@property (nonatomic,readwrite) NSString *role;
@end

NSString * const aylaOAuthAccountTypeGoogle = @"google_provider";
NSString * const aylaOAuthAccountTypeFacebook = @"facebook_provider";

NSString * const kAylaUserLogoutClearCache = @"clear_cache";

static id refactorCloudReturnedErrors(id returnedErrors)
{
    if(!returnedErrors) return nil;
    
    // If cloud returns an array of errors
    if([returnedErrors isKindOfClass:[NSArray class]]) {
        // We don't need refactor an array response from cloud.
        return returnedErrors;
    } else if([returnedErrors isKindOfClass:[NSDictionary class]]) {
        NSDictionary *errors = returnedErrors[@"errors"]?:returnedErrors;
        NSMutableDictionary *refactoredErrors = [NSMutableDictionary dictionary];
        [errors enumerateKeysAndObjectsUsingBlock:^(id  __nonnull key, id  __nonnull obj, BOOL * __nonnull stop) {
            if([obj isKindOfClass:[NSArray class]]) {
                if([obj count] > 0) {
                    refactoredErrors[key] = obj[0];
                }
                else {
                    AylaLogE(@"AylaApiClient", 0, @"Captured an empty error array for key %@, v %@", key, obj);
                }
            }
            else {
                refactoredErrors[key] = obj;
            }
        }];
        return refactoredErrors;
    }
    else {
        AylaLogE(@"AylaApiClient", 0, @"Errors container has to be an array or a dictionary: %@", returnedErrors);
    }
    return nil;
}

@implementation AylaUser

- (void)setPhoneCountryCode:(NSString *)countryCode {
    _phoneCountryCode = [countryCode stringByStrippingLeadingZeroes];
}

static AylaUser *_user = nil;

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if(self){
        _firstName = [[dict objectForKey:@"firstname"] nilIfNull];
        _lastName = [[dict objectForKey:@"lastname"] nilIfNull];
        _email = [[dict objectForKey:@"email"] nilIfNull];
        _country = [[dict objectForKey:@"country"] nilIfNull];
        
        _accessToken = [[dict objectForKey:@"access_token"] nilIfNull];
        _refreshToken = [[dict objectForKey:@"refresh_token"] nilIfNull];
        id expiresIn = [dict objectForKey:@"expires_in"];
        
        //the folowing check is required because the service returns a JSON number for Ayla login, and a "numberString" for Google/FB login, NSString doesn't have a unsignedIntegerValue method so use the integerValue instead
        _expiresIn = [expiresIn respondsToSelector:@selector(unsignedIntegerValue)] ?
        [expiresIn unsignedIntegerValue] :
        (NSUInteger)[expiresIn integerValue];
        
        _updatedAt = [NSDate date];
        _role = [dict[@"role"] nilIfNull];
        
        // Set YES as the default value of termsAccepted
        _termsAccepted = dict[@"terms_accepted"]? [[dict[@"terms_accepted"] nilIfNull] boolValue]: YES;
    }
    return self;
}

+ (NSOperation *)login:(NSString *)userName password:(NSString *)password appId:(NSString *)appId appSecret:(NSString *)appSecret
      success:(void (^)(AylaResponse *response, AylaUser *user))successBlock
      failure:(void (^)(AylaError *err))failureBlock
{
  // params = {‘user’:{‘email’:‘user@aylanetworks.com’,‘password’:‘password’,‘application’:{‘app_id’:‘debwebserver_id’,‘app_secret’:‘debwebserver_secret’}}}
  NSDictionary *app_params =[NSDictionary dictionaryWithObjectsAndKeys:
                             appId, @"app_id", appSecret, @"app_secret", nil];
  NSDictionary *user_params =[NSDictionary dictionaryWithObjectsAndKeys:
                             app_params, @"application",
                             userName, @"email", password, @"password",
                             nil];
  NSDictionary *params =[NSDictionary dictionaryWithObjectsAndKeys:
                             user_params, @"user", nil];
  
  // Clean auth token
  gblAuthToken = nil;
    
    AylaLogI(@"User", 0, @"Login attempt - baseUrl:%@ , appId:%@",
             [[[AylaApiClient sharedUserServiceInstance] baseURL] absoluteString],
             appId);
    return
    [[AylaApiClient sharedUserServiceInstance] postPath:@"users/sign_in.json"
                                              parameters:params
        success:^(AylaHTTPOperation *operation, id loginResponse) {
            saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"userLogin.postPath success");
            
            //set reachability to be REACHABLE, after success reponse from cloud
            [AylaReachability setConnectivity:AML_REACHABILITY_REACHABLE];
            //auth_token = ([loginResponse valueForKeyPath:@"user.auth_token"] != [NSNull null]) ? [loginResponse valueForKeyPath:@"user.auth_token"] : @"";
            NSString *accessToken = [loginResponse valueForKeyPath:@"access_token"] ? [loginResponse valueForKeyPath:@"access_token"] : @"";
            if ([accessToken isEqualToString:@""]) {
                saveToLog(@"%@, %@, %@:%@, %@", @"E", @"User", @"auth_token", @"null", @"userLogin No authorization token from device service.");
                AylaError *err = [AylaError new]; err.errorCode = AML_USER_NO_AUTH_TOKEN; err.nativeErrorInfo = nil; err.errorInfo = nil;
                failureBlock(err);
            } else {
                gblAuthToken = accessToken;
                AylaUser *user = [[AylaUser alloc] initWithDictionary:loginResponse];
                _user = user;
                saveToLog(@"%@, %@, %@:%@, %@", @"I", @"User", @"gblAuthToken", @"retrieved", @"userLogin authorization header set");
                successBlock(operation.response, user);
            }
        } failure:^(AylaHTTPOperation *operation, AylaError *error) {
            saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"userLogin");
            error.errorCode = operation.responseObject?AML_USER_INVALID_PARAMETERS:1;
            failureBlock(error);
        }];
}

+ (NSOperation *)ssoLogin:(NSString *)userName
                 password:(NSString *)password
                    token:(NSString *)token
                    appId:(NSString *)appId
                appSecret:(NSString *)appSecret
                  success:(void (^)(AylaResponse *response, AylaUser *user))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    AYLAssert(appId, @"appId must not be nil.");
    AYLAssert(appSecret, @"appSecret must not be nil.");
    
    NSDictionary *token_params = @{
                                  @"app_id": appId,
                                  @"app_secret": appSecret,
                                  @"token": token?:@""
                                  };

    AylaLogI(@"User", 0, @"ssoLogin attempt - baseUrl:%@ , appId:%@",
             [[[AylaApiClient sharedUserServiceInstance] baseURL] absoluteString],
             appId);
    return
    [[AylaApiClient sharedUserServiceInstance] postPath:@"api/v1/token_sign_in.json"
                                             parameters:token_params
                                                success:^(AylaHTTPOperation *operation, id loginResponse) {
                                                    saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"ssoLogin.postPath success");
                                                    //set reachability to be REACHABLE, after success reponse from cloud
                                                    [AylaReachability setConnectivity:AML_REACHABILITY_REACHABLE];
                                                    NSString *accessToken = [loginResponse valueForKeyPath:@"access_token"]? : @"";
                                                    if ([accessToken isEqualToString:@""]) {
                                                        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"User", @"auth_token", @"null", @"ssoLogin No authorization token from device service.");
                                                        AylaError *err = [AylaError new]; err.errorCode = AML_USER_NO_AUTH_TOKEN; err.nativeErrorInfo = nil; err.errorInfo = nil;
                                                        failureBlock(err);
                                                    } else {
                                                        gblAuthToken = accessToken;
                                                        AylaUser *user = [[AylaUser alloc] initWithDictionary:loginResponse];
                                                        _user = user;
                                                        saveToLog(@"%@, %@, %@:%@, %@", @"I", @"User", @"gblAuthToken", @"retrieved", @"userLogin authorization header set");
                                                        successBlock(operation.response, user);
                                                    }
                                                } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                    saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"userLogin");
                                                    failureBlock(error);
                                                }];
}

+ (NSUInteger)accessTokenSecondsToExpiry
{
    if(gblAuthToken == nil || _user == nil)
        return 0;
    NSTimeInterval interval = [[_user.updatedAt dateByAddingTimeInterval:_user.expiresIn] timeIntervalSinceDate:[NSDate date]];
    return interval>0?interval:0;
}

+ (NSOperation *)refreshAccessTokenWithRefreshToken:(NSString *)refreshToken
        success:(void (^)(AylaResponse *response, AylaUser *refreshed))successBlock
        failure:(void (^)(AylaError *err))failureBlock
{
    if(refreshToken == nil){
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.nativeErrorInfo = nil; err.errorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    
    NSDictionary *refresh = [NSDictionary dictionaryWithObjectsAndKeys:refreshToken, @"refresh_token", nil];
    return [[AylaApiClient sharedUserServiceInstance] postPath: @"users/refresh_token.json"
                                                     parameters: [NSDictionary dictionaryWithObjectsAndKeys:refresh, @"user", nil]
            success:^(AylaHTTPOperation *operation, id refreshResponse) {
                saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"refreshToken.postPath, success");
                
                //set reachability to be REACHABLE, after success reponse from cloud
                [AylaReachability setConnectivity:AML_REACHABILITY_REACHABLE];
                NSString *accessToken = [refreshResponse valueForKeyPath:@"access_token"] ? [refreshResponse valueForKeyPath:@"access_token"] : @"";
                if ([accessToken isEqualToString:@""]) {
                    saveToLog(@"%@, %@, %@:%@, %@", @"E", @"User", @"auth_token", @"null", @"refreshAccessWithRefreshToken: No authorization token from device service.");
                    AylaError *err = [AylaError new]; err.errorCode = AML_USER_NO_AUTH_TOKEN; err.nativeErrorInfo = nil; err.errorInfo = nil;
                    failureBlock(err);
                } else {
                    gblAuthToken = accessToken;
                    AylaUser *user = [[AylaUser alloc] initWithDictionary:refreshResponse];
                    _user = user;
                    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"User", @"gblAuthToken", @"retrieved", @"userLogin authorization header set");
                    successBlock(operation.response, user);
                }

            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"E", @"User",
                          @"statusCode", (long)operation.response.httpStatusCode, @"response", operation.responseObject, @"refreshToken.postPath");
                error.errorCode = error.errorInfo?AML_USER_INVALID_PARAMETERS:1;
                failureBlock(error);
            }];
}



+ (NSOperation *)signUp: (NSDictionary *)callParams appId:(NSString *)appId appSecret:(NSString *)appSecret
           success:(void (^)(AylaResponse *response))successBlock
           failure:(void (^)(AylaError *err))failureBlock
{
    NSDictionary *app_params =[NSDictionary dictionaryWithObjectsAndKeys:
                               appId, @"app_id", appSecret, @"app_secret", nil];
    
    NSMutableDictionary *nparams = [callParams mutableCopy];
    [nparams setObject:app_params forKey:@"application"];
    
    NSMutableDictionary *errors = [[NSMutableDictionary alloc] init];
    
    NSString *email = [nparams objectForKey:@"email"];
    AylaError *emailValidationError = nil;
    
    if([email ayla_validateAsEmail:&emailValidationError])
    {
        [errors addEntriesFromDictionary:emailValidationError.errorInfo];
    }
    
    if([nparams objectForKey:@"password"] == nil)
    {
        [errors setObject:@"can't be blank" forKey:@"password"];
    }
    else{
        if([[nparams objectForKey:@"password"] length] < 6)
            [errors setObject:@"must be at least 6 characters long" forKey:@"password"];
    }

    if([nparams objectForKey:@"firstname"] == nil)
    {
        [errors setObject:@"can't be blank" forKey:@"firstname"];
    }
    else{
        if([[nparams objectForKey:@"firstname"] length] < 2)
            [errors setObject:@"is invalid" forKey:@"firstname"];
    }

    if([nparams objectForKey:@"lastname"] == nil)
    {
        [errors setObject:@"can't be blank" forKey:@"lastname"];
    }
    else{
        if([[nparams objectForKey:@"lastname"] length] < 2)
            [errors setObject:@"is invalid" forKey:@"lastname"];
    }
/*
    if([nparams objectForKey:@"company"] == nil)
    {
        [errors setObject:@"can't be blank" forKey:@"company"];
    }
    else{
        if([[nparams objectForKey:@"company"] length] < 2)
            [errors setObject:@"is invalid" forKey:@"company"];
    }
*/
    if([nparams objectForKey:@"country"] == nil)
    {
        [errors setObject:@"can't be blank" forKey:@"country"];
    }
    else{
        if([[nparams objectForKey:@"country"] length] < 2)
            [errors setObject:@"is invalid" forKey:@"country"];
    }
    
    
    NSDictionary *possibleParams = [[NSDictionary alloc] initWithObjectsAndKeys:@"1",@"email", @"1", @"password",
                                                                                @"1", @"firstname",@"1", @"lastname", @"1", @"country",
                                                                                @"1", @"phone",@"1", @"company",@"1", @"city", @"1", @"state",
                                                                                @"1", @"street",@"1", @"zip",@"1", @"ayla_dev_kit_num",
                                                                                @"1", @"phone_country_code",
                                                                                @"1", AML_EMAIL_TEMPLATE_ID,
                                                                                @"1", AML_EMAIL_SUBJECT,
                                                                                @"1", AML_EMAIL_BODY_HTML,
                                                                                nil];
    for(NSString *key in [callParams allKeys]){
        if(  [possibleParams valueForKey:key ] ==nil ){ // not supported
            [errors setObject:@"is not supported" forKey:key];
        }
    }
    
    if([errors count]>0){
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.errorInfo = errors;
        err.nativeErrorInfo = nil; err.httpStatusCode = 422;
        failureBlock(err);
        return nil;
    }
    
    NSString *path = @"users.json";
    if([nparams objectForKey:AML_EMAIL_TEMPLATE_ID]) {
        NSString *emailTemplateIdString = [@"?email_template_id=" stringByAppendingString:[nparams objectForKey:AML_EMAIL_TEMPLATE_ID]];
        path = [path stringByAppendingString:emailTemplateIdString];
        if([nparams objectForKey:AML_EMAIL_SUBJECT]) {
            NSString *utf8Encoding = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                               (__bridge CFStringRef)[nparams objectForKey:AML_EMAIL_SUBJECT],
                                                                                               NULL,
                                                                                               CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                               kCFStringEncodingUTF8));
            path = [path stringByAppendingFormat:@"&email_subject=%@",utf8Encoding];
        }
        if([nparams objectForKey:AML_EMAIL_BODY_HTML]) {
            NSString *utf8Encoding = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                               (__bridge CFStringRef)[nparams objectForKey:AML_EMAIL_BODY_HTML],
                                                                                               NULL,
                                                                                               CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                               kCFStringEncodingUTF8));
            path = [path stringByAppendingFormat:@"&email_body_html=%@",utf8Encoding];
        }

    }
    
    NSDictionary *userParams =[NSDictionary dictionaryWithObjectsAndKeys:nparams, @"user", nil];
    NSString *uname = [callParams objectForKey:@"email"];
    saveToLog(@"%@, %@, %@:%@, %@:%@, %@", @"I", @"User",@"username", uname, @"appId", appId, @"userSignUp.postPath attempt");
    
    return [[AylaApiClient sharedUserServiceInstance] postPath:path parameters:userParams
            success:^(AylaHTTPOperation *operation, id signUpResponse) {
                saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"userSignUp._postPath success");
                
                NSString *email = ([signUpResponse valueForKeyPath:@"email"] != [NSNull null]) ? [signUpResponse valueForKeyPath:@"email"] : @"";
                if ([email isEqualToString:@""]) {
                    saveToLog(@"%@, %@, %@:%@, %@", @"E", @"User", @"SignUp email", @"null", @"userSignUp");
                    NSString *errStr = @"Cannot get right responce from server";
                    AylaError *err = [AylaError new]; err.errorCode = 1; err.httpStatusCode = operation.response.httpStatusCode; err.nativeErrorInfo = errStr;
                    failureBlock(err);
                } else {
                    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"User", @"mail", email, @"userSignUp");
                    successBlock(operation.response);
                }
            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"E", @"User",
                          @"statusCode", (long)operation.response.httpStatusCode, @"response", operation.responseObject, @"userSignUp");
                error.errorCode = error.errorInfo?AML_USER_INVALID_PARAMETERS:1;
                error.errorInfo = refactorCloudReturnedErrors(error.errorInfo);
                failureBlock(error);
            }];
}

+ (NSOperation *)signUpConfirmationWithToken:(NSString *)token
                            success:(void (^)(AylaResponse *response, AylaUser *user))successBlock
                            failure:(void (^)(AylaError *err))failureBlock
{
    if(!token || [token isEqualToString:@""]){
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"is invalid", @"token", nil];
        err.nativeErrorInfo = nil; err.httpStatusCode = 422;
        failureBlock(err);
        return nil;
    }
    
    NSString *path = [NSString stringWithFormat:@"users/confirmation.json?confirmation_token=%@", token];
    return [[AylaApiClient sharedUserServiceInstance] putPath: path parameters:nil
            success:^(AylaHTTPOperation *operation, id responseObject) {
                saveToLog(@"%@, %@, %@:%ld, %@:%@, %@", @"I", @"User",
                          @"statusCode", (long)operation.response.httpStatusCode, @"success",@"null", @"signUpConfirmationWithToken");
                AylaUser *user = responseObject?[[AylaUser alloc] initWithDictionary:responseObject]:nil;;
                successBlock(operation.response, user);
            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@:%ld, %@:%@, %@", @"E", @"User",
                          @"httpStatusCode", (long)operation.response.httpStatusCode, @"response", operation.responseObject, @"signUpConfirmationWithToken");
                error.errorCode = error.errorInfo?AML_USER_INVALID_PARAMETERS:1;
                error.errorInfo = refactorCloudReturnedErrors(error.errorInfo);
                failureBlock(error);
            }];
}

+ (NSOperation *)getInfo:(NSDictionary *)callParams
            success:(void (^)(AylaResponse *response, NSDictionary *dict))successBlock
            failure:(void (^)(AylaError *err))failureBlock
{
    NSString *token = gblAuthToken;
    if(token == nil){
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_NO_AUTH_TOKEN;
        err.nativeErrorInfo = nil; err.errorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    return [[AylaApiClient sharedUserServiceInstance] getPath:[NSString stringWithFormat:@"%@%@",@"users/get_user_profile.json?access_token=",gblAuthToken]
                                                   parameters:nil
            success:^(AylaHTTPOperation *operation, id responseObject) {
                saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"usergetInfo.getPath");
                successBlock(operation.response, operation.responseObject);
            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"getInfo.getPath");
                error.errorInfo = refactorCloudReturnedErrors(error.errorInfo);
                failureBlock(error);
            }];
}

+ (NSOperation *)changePassword:(NSString *)currentPassword newPassword:(NSString *)newPassword
                    success:(void (^)(AylaResponse *response))successBlock
                    failure:(void (^)(AylaError *err))failureBlock
{
    NSString *token = gblAuthToken;
    if(token == nil){
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_NO_AUTH_TOKEN;
        err.nativeErrorInfo = nil; err.errorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    
    NSDictionary *pwdInfo = [[NSDictionary alloc] initWithObjectsAndKeys:currentPassword, @"current_password", newPassword, @"password", nil];
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:pwdInfo, @"user", nil];
    return [[AylaApiClient sharedUserServiceInstance] putPath: @"users.json" parameters:params
            success:^(AylaHTTPOperation *operation, id responseObject) {
                saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"userPasswordEdit.putPath");
                successBlock(operation.response);
            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"userPasswordEdit.putPath");
                error.errorCode = error.errorInfo?AML_USER_INVALID_PARAMETERS:1;
                error.errorInfo = refactorCloudReturnedErrors(error.errorInfo);
                failureBlock(error);
            }];
}


+ (NSOperation *)updateUserInfo:(NSDictionary *)callParams
                  success:(void (^)(AylaResponse *response))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    NSString *token = gblAuthToken;
    if(token == nil){
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_NO_AUTH_TOKEN;
        err.nativeErrorInfo = nil; err.errorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    
    NSDictionary *possibleParams = [[NSDictionary alloc] initWithObjectsAndKeys:@"1", @"firstname",@"1", @"lastname", @"1", @"country",
                                                                                @"1", @"phone",@"1", @"company", @"1", @"city", @"1", @"state",
                                                                                @"1", @"street",@"1", @"zip",@"1", @"ayla_dev_kit_num",
                                                                                @"1", @"phone_country_code", nil];
    NSMutableDictionary *errors = [NSMutableDictionary new];
    for(NSString *key in [callParams allKeys]){
        if(  [possibleParams valueForKey:key ] ==nil ){ // not supported
            [errors setObject:@"is not supported" forKey:key];
        }
    }
    if([errors count]>0){
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.errorInfo = errors;
        err.nativeErrorInfo = nil; err.httpStatusCode = 422;
        failureBlock(err);
        return nil;
    }
    
    NSDictionary *userParams = [[NSDictionary alloc] initWithObjectsAndKeys:callParams, @"user", nil];
    return [[AylaApiClient sharedUserServiceInstance] putPath: @"users.json" parameters:userParams
            success:^(AylaHTTPOperation *operation, id responseObject) {
                saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"userUpdateUserInfo");
                successBlock(operation.response);
            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"userAttributesUpdate");
                error.errorCode = error.errorInfo?AML_USER_INVALID_PARAMETERS:1;
                error.errorInfo = refactorCloudReturnedErrors(error.errorInfo);
                failureBlock(error);
            }];
}

+ (NSOperation *)logout:(__unused NSString *)accessToken
                success:(void (^)(AylaResponse *response))successBlock
                failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaUser logoutWithParams:@{kAylaUserLogoutClearCache: @(YES)} success:successBlock failure:failureBlock];
}

+ (NSOperation *)logoutWithParams:(NSDictionary *)callParams
                  success:(void (^)(AylaResponse *response))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    NSString *token = gblAuthToken;
    
	// '{"user": {"access_token": "e0b062246574a6de2980687857f28240"}}'
    NSDictionary *user_params =[NSDictionary dictionaryWithObjectsAndKeys:
                             token, @"access_token", nil];
    NSDictionary *params =[NSDictionary dictionaryWithObjectsAndKeys:
                         user_params, @"user", nil];
  
    NSNumber *clearCache = callParams[kAylaUserLogoutClearCache]?: @(NO);
    NSMutableURLRequest *request = [[AylaApiClient sharedUserServiceInstance] requestWithMethod:@"POST" path:@"users/sign_out.json" parameters:params];
    [request setTimeoutInterval:20];
    
    AylaHTTPOperation *operation = [[AylaApiClient sharedUserServiceInstance] operationWithRequest:request
                                    success:^(AylaHTTPOperation *operation, id responseObject) {
                                        gblAuthToken = nil;
                                        _user = nil;
                                        saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"userLogout.getPath");
                                        if(clearCache.boolValue) [AylaCache clearAll];
                                        successBlock(operation.response);
                                    } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                        gblAuthToken = nil;
                                        _user = nil;
                                        saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"userLogout.getPath");
                                        failureBlock(error);
                                    }];
    [operation start];
    return operation;
}

+ (NSOperation *)resetPassword:(NSString *)mailAddress
                    withParams:(NSDictionary *)params
                       success:(void (^)(AylaResponse *response))successBlock
                       failure:(void (^)(AylaError *err))failureBlock
{
   return [AylaUser resetPassword:mailAddress appId:nil appSecret:nil andParams:params success:successBlock failure:failureBlock];
}

+ (NSOperation *)resetPassword:(NSString *)mailAddress
                         appId:(NSString *)appId
                     appSecret:(NSString *)appSecret
                     andParams:(NSDictionary *)params
                  success:(void (^)(AylaResponse *response))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    NSDictionary *applicationDictionary = nil;
    if(appId && appSecret)
    {
        applicationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   appId, @"app_id",
                                                   appSecret, @"app_secret", nil];
    }
    else {
        saveToLog(@"%@, %@, %@:%@, %@", @"W", @"User",
              @"app_id||app_secret", @"can't be blank", @"userResetPassword");
    }
    
    AylaError *error = nil;
    if([mailAddress ayla_validateAsEmail:&error]){
        NSMutableDictionary *errors = [NSMutableDictionary dictionary];
        
        id errorInfo = [error.errorInfo objectForKey:kNSStringValidationEmail];
        if(errorInfo  != nil)
        {
            [errors setObject:errorInfo forKey:@"base"];
        }
        
        error.errorInfo = errors;
        failureBlock(error);
        return nil;
    }
    
    NSMutableDictionary *infoDictionary =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:mailAddress, @"email", nil];
    
    if(applicationDictionary) {
        [infoDictionary setObject:applicationDictionary forKey:@"application"];
    }
    
    NSString *path = @"users/password.json";
    if(params) {
        if([params objectForKey:AML_EMAIL_TEMPLATE_ID]) {
            path = [path stringByAppendingFormat:@"?email_template_id=%@",
                    [params objectForKey:AML_EMAIL_TEMPLATE_ID]];
            if([params objectForKey:AML_EMAIL_SUBJECT]) {
                NSString *utf8Encoding = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                   (__bridge CFStringRef)[params objectForKey:AML_EMAIL_SUBJECT],
                                                                                                   NULL,
                                                                                                   CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                                   kCFStringEncodingUTF8));
                path = [path stringByAppendingFormat:@"&email_subject=%@",utf8Encoding];
            }
            if([params objectForKey:AML_EMAIL_BODY_HTML]) {
                NSString *utf8Encoding = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                   (__bridge CFStringRef)[params objectForKey:AML_EMAIL_BODY_HTML],
                                                                                                   NULL,
                                                                                                   CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                                   kCFStringEncodingUTF8));
                path = [path stringByAppendingFormat:@"&email_body_html=%@",utf8Encoding];
            }
        }
    }
    NSDictionary *userParams = [[NSDictionary alloc] initWithObjectsAndKeys:infoDictionary, @"user", nil];
    return [[AylaApiClient sharedUserServiceInstance] postPath:path parameters:userParams
            success:^(AylaHTTPOperation *operation, id responseObject) {
                saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"I", @"User",
                          @"statusCode", (long)operation.response.httpStatusCode, @"success",@"null", @"userResetPassword");
                successBlock(operation.response);
            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"userLogout.getPath");
                error.errorCode = error.errorInfo?AML_USER_INVALID_PARAMETERS:1;
                error.errorInfo = refactorCloudReturnedErrors(error.errorInfo);
                failureBlock(error);
            }];
}

+ (NSOperation *)resetPasswordWithNewPassword:(NSString *)password
                                     andToken:(NSString *)token
                                      success:(void (^)(AylaResponse *response))successBlock
                                      failure:(void (^)(AylaError *err))failureBlock
{
    NSMutableDictionary *errors = [[NSMutableDictionary alloc] init];
    if(!password) {
        [errors setObject:@"can't be blank." forKey:@"password"];
    }
    if(!token) {
        [errors setObject:@"can't be blank." forKey:@"token"];
    }
    if([errors count] != 0){
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.errorInfo = errors;
        err.nativeErrorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return nil;
    }
    NSDictionary *pwdInfo = [[NSDictionary alloc] initWithObjectsAndKeys: password, @"password",
                                                                          password, @"password_confirmation",
                                                                          token, @"reset_password_token",
                                                                          nil];
    NSDictionary *userParams = [[NSDictionary alloc] initWithObjectsAndKeys: pwdInfo, @"user", nil];
    return [[AylaApiClient sharedUserServiceInstance] putPath:@"users/password.json" parameters:userParams
            success:^(AylaHTTPOperation *operation, id responseObject) {
                saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"I", @"User",
                          @"statusCode", (long)operation.response.httpStatusCode, @"success",@"null", @"userResetPassword");
                successBlock(operation.response);
            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@, %@", @"E", @"User", error.logDescription, @"userLogout.getPath");
                error.errorCode = error.errorInfo?AML_USER_INVALID_PARAMETERS:1;
                error.errorInfo = refactorCloudReturnedErrors(error.errorInfo);
                failureBlock(error);
            }];
}

+ (NSOperation *)resendConfirmation:(NSString *)mailAddress
                          withParams:(NSDictionary *)params
                            success:(void (^)(AylaResponse *response))successBlock
                            failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaUser resendConfirmation:mailAddress appId:nil appSecret:nil andParams:params success:successBlock failure:failureBlock];
}

+ (NSOperation *)resendConfirmation:(NSString *)mailAddress
                              appId:(NSString *)appId
                          appSecret:(NSString *)appSecret
                          andParams:(NSDictionary *)params
                  success:(void (^)(AylaResponse *response))successBlock
                  failure:(void (^)(AylaError *err))failureBlock
{
    
    NSDictionary *applicationDictionary = nil;
    if(appId && appSecret)
    {
        applicationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                 appId, @"app_id",
                                 appSecret, @"app_secret", nil];
    }
    else {
        saveToLog(@"%@, %@, %@:%@, %@", @"W", @"User",
                  @"app_id||app_secret", @"can't be blank", @"userResendConfirmationToken");
    }

    AylaError *error = nil;
    if([mailAddress ayla_validateAsEmail:&error]){
        failureBlock(error);
        return nil;
    }
    
    NSMutableDictionary *infoDictionary =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:mailAddress, @"email", nil];
    
    if(applicationDictionary) {
        [infoDictionary setObject:applicationDictionary forKey:@"application"];
    }
    
    NSString *path = @"users/confirmation.json";
    if(params) {
        if([params objectForKey:AML_EMAIL_TEMPLATE_ID]) {
            path = [path stringByAppendingFormat:@"?email_template_id=%@",
                        [params objectForKey:AML_EMAIL_TEMPLATE_ID]];
            if([params objectForKey:AML_EMAIL_SUBJECT]) {
                NSString *utf8Encoding = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                   (__bridge CFStringRef)[params objectForKey:AML_EMAIL_SUBJECT],
                                                                                                   NULL,
                                                                                                   CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                                   kCFStringEncodingUTF8));
                path = [path stringByAppendingFormat:@"&email_subject=%@",utf8Encoding];
            }
            if([params objectForKey:AML_EMAIL_BODY_HTML]) {
                NSString *utf8Encoding = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                   (__bridge CFStringRef)[params objectForKey:AML_EMAIL_BODY_HTML],
                                                                                                   NULL,
                                                                                                   CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                                   kCFStringEncodingUTF8));
                path = [path stringByAppendingFormat:@"&email_body_html=%@",utf8Encoding];
            }
        }
    }
    
    NSDictionary *userParams = [[NSDictionary alloc] initWithObjectsAndKeys:infoDictionary, @"user", nil];
    return [[AylaApiClient sharedUserServiceInstance] postPath:path parameters:userParams
            success:^(AylaHTTPOperation *operation, id responseObject) {
                saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"I", @"User",
                          @"http", (long)operation.response.httpStatusCode, @"success",@"null", @"userResendConfirmationToken");
                successBlock(operation.response);
            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@, %@", @"E", @"User",
                          error.logDescription, @"userResendConfirmationToken");
                error.errorCode = error.errorInfo?AML_USER_INVALID_PARAMETERS:1;
                error.errorInfo = refactorCloudReturnedErrors(error.errorInfo);
                failureBlock(error);
            }];
}


+ (NSOperation *)delete:(NSDictionary *) callParams
                   success:(void (^)(AylaResponse *response)) successBlock
                   failure:(void (^)(AylaError *err))failureBlock
{
    return [[AylaApiClient sharedUserServiceInstance] deletePath: @"users.json" parameters:nil
            success:^(AylaHTTPOperation *operation, id responseObject) {
                saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"I", @"User",
                          @"statusCode", (long)operation.response.httpStatusCode, @"success",@"null", @"cancelAccount");
                successBlock(operation.response);
            } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"E", @"User",
                          @"httpStatusCode", (long)operation.response.httpStatusCode, @"response", operation.responseObject, @"cancelAccount");
                failureBlock(error);
            }];
}

+ (AylaUser *)currentUser {
    return _user;
}

+ (void)refreshAccessTokenOnExpiry
{
    if([AylaUser currentUser]) {
        AylaUser *user = [AylaUser currentUser];
        NSUInteger left = [AylaUser accessTokenSecondsToExpiry];
        if(left <= DEFAULT_ACCESS_TOKEN_REFRESH_THRRESHOLD && user.refreshToken) {
            [AylaUser refreshAccessTokenWithRefreshToken:user.refreshToken
                 success:^(AylaResponse *response, AylaUser *updatedUser) {
                     @synchronized(user) {
                         user.accessToken = updatedUser.accessToken;
                         user.refreshToken = updatedUser.refreshToken;
                         user.expiresIn = updatedUser.expiresIn;
                         user.updatedAt = updatedUser.updatedAt;
                     }
                     saveToLog(@"%@, %@, %@:%lu, %@", @"I", @"User",
                               @"httpStatusCode", (unsigned long)response.httpStatusCode, @"refreshAccessTokenWithRefreshToken");
                 } failure:^(AylaError *err) {
                     saveToLog(@"%@, %@, %@:%lu, %@", @"E", @"User",
                               @"httpStatusCode", (unsigned long)err.httpStatusCode, @"refreshAccessTokenWithRefreshToken");
                 }];
        }
    }
}

- (NSOperation *)createDatum:(AylaDatum *)datum
                     success:(void (^)(AylaResponse *response, AylaDatum *newDatum))successBlock
                     failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaDatum createWithObject:self andDatum:datum success:successBlock failure:failureBlock];
}

- (NSOperation *)getDatumWithKey:(NSString *)key
                         success:(void (^)(AylaResponse *response, AylaDatum *datum))successBlock
                         failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaDatum getWithObject:self andKey:key success:successBlock failure:failureBlock];
}

- (NSOperation *)getDatumWithParams:(NSDictionary *)params
                          success:(void (^)(AylaResponse *response, NSArray *datums))successBlock
                          failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaDatum getWithObject:self andParams:params success:successBlock failure:failureBlock];
}

- (NSOperation *)updateDatum:(AylaDatum *)datum
                     success:(void (^)(AylaResponse *response, AylaDatum *updatedDatum))successBlock
                     failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaDatum updateWithObject:self andDatum:datum success:successBlock failure:failureBlock];
}

- (NSOperation *)deleteDatum:(AylaDatum *)datum
                     success:(void (^)(AylaResponse *response))successBlock
                     failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaDatum deleteWithObject:self andDatum:datum success:successBlock failure:failureBlock];
}

- (NSOperation *)createShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *resp, AylaShare *share))successBlock
                     failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaShare create:share object:self success:successBlock failure:failureBlock];
}

- (NSOperation *)getShares:(NSDictionary *)callParams
                   success:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                   failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaShare get:self callParams:callParams success:successBlock failure:failureBlock];
}

+ (NSOperation *)getAllShares:(NSDictionary *)callParams
                      success:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                      failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaShare get:nil callParams:callParams success:successBlock failure:failureBlock];
}

- (NSOperation *)getReceivedShares:(NSDictionary *)callParams
                           success:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                           failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaShare getReceives:self callParams:callParams success:successBlock failure:failureBlock];
}

+ (NSOperation *)getAllReceivedShares:(NSDictionary *)callParams
                              success:(void (^)(AylaResponse *response, NSArray *deviceShares)) successBlock
                              failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaShare getReceives:nil callParams:callParams success:successBlock failure:failureBlock];
}

- (NSOperation *)getShareWithId:(NSString *)id
                    success:(void (^)(AylaResponse *resp, AylaShare *share))successBlock
                    failure:(void (^)(AylaError *error))failureBlock;
{
    return [AylaShare getWithId:id success:successBlock failure:failureBlock];
}

- (NSOperation *)updateShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *resp, AylaShare *updatedShare))successBlock
                     failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaShare update:share success:successBlock failure:failureBlock];
}

- (NSOperation *)deleteShare:(AylaShare *)share
                     success:(void (^)(AylaResponse *response)) successBlock
                     failure:(void (^)(AylaError *err))failureBlock
{
    return [AylaShare delete:share success:successBlock failure:failureBlock];
}

- (NSOperation *)createContact:(AylaContact *)contact withParams:(NSDictionary *)callParams
                       success:(void (^)(AylaResponse *resp, AylaContact *createdContact))successBlock
                       failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaContact create:contact withParams:callParams success:successBlock failure:failureBlock];
}

- (NSOperation *)getContactWithId:(NSNumber *)contactId
                          success:(void (^)(AylaResponse *resp, AylaContact *contact))successBlock
                          failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaContact getWithId:contactId params:nil success:successBlock failure:failureBlock];
}

- (NSOperation *)getContactsWithParams:(NSDictionary *)callParams
                               success:(void (^)(AylaResponse *resp, NSArray *contacts))successBlock
                               failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaContact getAllWithParams:callParams success:successBlock failure:failureBlock];
}

- (NSOperation *)updateContact:(AylaContact *)contact withParams:(NSDictionary *)callParams
                       success:(void (^)(AylaResponse *resp, AylaContact *updatedContact))successBlock
                       failure:(void (^)(AylaError *error))failureBlock;
{
    return [AylaContact update:contact withParams:callParams success:successBlock failure:failureBlock];
}

- (NSOperation *)deleteContact:(AylaContact *)contact
                       success:(void (^)(AylaResponse *resp))successBlock
                       failure:(void (^)(AylaError *error))failureBlock
{
    return [AylaContact delete:contact withParams:nil success:successBlock failure:failureBlock];
}

static AylaOAuth *oAuth = nil;
+ (void)loginThroughOAUTHWithAccountType:(AylaOAuthAccountType) accountType webView:(UIWebView *)webView AppId:(NSString *)appId andAppSecret:(NSString *)appSecret
                                 success:(void (^)(AylaResponse *response)) successBlock
                                 failure:(void (^)(AylaError *err))failureBlock
{
    // Clean auth token
    gblAuthToken = nil;
    
    [AylaUser retrieveOAuthURLWithAccountType:accountType AppId:appId andAppSecret:appSecret
          success:^(NSURL *url){
              
              NSString *redirectRemoteUrlStr = [accountType isEqualToString:aylaOAuthAccountTypeGoogle]? aylaOAuthRedirectUriLocal:aylaOAuthRedirectUriRemote ;
              
              NSURL *toWebViewURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&redirect_uri=%@", [url absoluteString], [accountType isEqualToString:aylaOAuthAccountTypeGoogle]? aylaOAuthRedirectUriLocal:redirectRemoteUrlStr]];
              oAuth = [[AylaOAuth alloc] initWithType:accountType webView:webView];
              [oAuth authenticateOnWebViewWithURL:toWebViewURL success:^(NSString *code) {
                  saveToLog(@"%@, %@, %@:%@, %@", @"I", @"User",
                            @"success", @"success", @"authenticateOnWebViewWithURL");
                  NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:code, @"code", [accountType isEqualToString:aylaOAuthAccountTypeGoogle]? aylaOAuthRedirectUriLocal:aylaOAuthRedirectUriRemote, @"redirect_url", appId, @"app_id", accountType, @"provider", nil];
                  [AylaUser authenticateToService:params success:successBlock failure:failureBlock];
                  
              } failure:^(AylaError *err) {
                  failureBlock(err);
              }];
              
            } failure:^(AylaError *err) {
                failureBlock(err);
            }];
}

+ (void)retrieveOAuthURLWithAccountType:(AylaOAuthAccountType)type AppId:(NSString *)appId andAppSecret:(NSString *)appSecret
                                success:(void (^)(NSURL *url)) successBlock
                                failure:(void (^)(AylaError *err))failureBlock
{
    
    NSMutableDictionary *errors = [[NSMutableDictionary alloc] init];
    if(appId == nil)
    {
        [errors setObject:@"can't be blank" forKey:@"appId"];
    }
    if(appSecret == nil)
    {
        [errors setObject:@"can't be blank" forKey:@"appSecret"];
    }
    if(type == nil)
    {
        [errors setObject:@"can't be blank" forKey:@"accountType"];
    }
    
    if([errors count] != 0){
        AylaError *err = [AylaError new]; err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.errorInfo = errors;
        err.nativeErrorInfo = nil; err.httpStatusCode = 0;
        failureBlock(err);
        return;
    }
    
    NSDictionary *applicationInfo = [[NSDictionary alloc] initWithObjectsAndKeys:appId, @"app_id", appSecret, @"app_secret", nil];
    NSDictionary *userParams = [[NSDictionary alloc] initWithObjectsAndKeys:type, @"auth_method", applicationInfo, @"application", nil];
    
    [[AylaApiClient sharedUserServiceInstance] postPath: @"users/sign_in.json"
             parameters:[[NSDictionary alloc] initWithObjectsAndKeys:userParams, @"user", nil]
        success:^(AylaHTTPOperation *operation, id responseObject) {
            saveToLog(@"%@, %@, %@:%ld, %@:%@ %@", @"I", @"User",
                      @"http", (long)operation.response.httpStatusCode, @"success",@"null", @"retrieveOAuthURLWithAccountType");
            successBlock([NSURL URLWithString:[responseObject objectForKey:@"url"]]);

        } failure:^(AylaHTTPOperation *operation, AylaError *error) {
            saveToLog(@"%@, %@, %@, %@", @"E", @"User",
                      error.logDescription, @"cancelAccount");
            error.errorCode = error.errorInfo?AML_USER_INVALID_PARAMETERS:1;
            error.errorInfo = refactorCloudReturnedErrors(error.errorInfo);
            failureBlock(error);
        }];
}

+ (void) authenticateToService:(NSDictionary *)callParams
        success:(void (^)(AylaResponse *response)) successBlock
        failure:(void (^)(AylaError *err))failureBlock
{
    saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"authenticateToService attempt");
    [[AylaApiClient sharedUserServiceInstance] postPath: @"users/provider_auth.json" parameters:callParams
     success:^(AylaHTTPOperation *operation, id authResp) {
         saveToLog(@"%@, %@, %@, %@", @"I", @"User", @"none", @"authenticateToService success");
         NSString *accessToken = ([authResp valueForKeyPath:@"access_token"] != [NSNull null]) ? [authResp valueForKeyPath:@"access_token"] : @"";
         if (!accessToken || [accessToken isEqualToString:@""]) {
             saveToLog(@"%@, %@, %@:%@, %@", @"E", @"User", @"auth_token", @"null", @"authenticateToService No authorization token from device service.");
             AylaError *err = [AylaError new]; err.errorCode = AML_USER_NO_AUTH_TOKEN; err.nativeErrorInfo = nil; err.errorInfo = nil;
             failureBlock(err);
         } else {
             
             AylaUser *user = [[AylaUser alloc] initWithDictionary:authResp];
             _user = user;
             gblAuthToken = accessToken;
             //NSString *refreshToken = ([loginResponse valueForKeyPath:@"refresh_token"] != [NSNull null]) ? [loginResponse valueForKeyPath:@"refresh_token"] : @"";
             //NSNumber *exipryIn = ([loginResponse valueForKeyPath:@"expires_in"] != [NSNull null]) ? [loginResponse valueForKeyPath:@"expires_in"] : @"";
             saveToLog(@"%@, %@, %@:%d, %@", @"I", @"User", @"gblAuthToken", gblAuthToken?1:0, @"authenticateToService");
             AylaResponse *response = [AylaResponse new];
             response.httpStatusCode = operation.response.httpStatusCode;
             successBlock(response);
         }

     } failure:^(AylaHTTPOperation *operation, AylaError *error) {
         saveToLog(@"%@, %@, %@, %@", @"E", @"User",
                   error.logDescription, @"cancelAccount");
         error.errorCode = error.errorInfo?AML_USER_INVALID_PARAMETERS:1;
         failureBlock(error);
     }];
}

@end
