//
//  AylaContact.m
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 1/13/15.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaContact.h"
#import "AylaNetworks.h"
#import "AylaApiClient.h"
#import "AylaErrorSupport.h"
#import "NSObject+AylaNetworks.h"
#import "NSString+AylaNetworks.h"

@interface AylaContact ()

@property (nonatomic, strong, readwrite) NSString *updatedAt;

@end

@implementation AylaContact

- (void)setPhoneCountryCode:(NSString *)countryCode {
    _phoneCountryCode = [countryCode stringByStrippingLeadingZeroes];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if(!self) return nil;
    
    if(self) {
        [self updateWithDictionary:dictionary];
    }
    
    return self;
}

+ (NSOperation *)create:(AylaContact *)contact withParams:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *resp, AylaContact *createdContact))successBlock
               failure:(void (^)(AylaError *error))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    if(!contact) {
        [errors setObject:@"can't be blank" forKey:kAylaContactParamContact];
    }
    
    if(errors.count > 0) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:errors];
        failureBlock(error);
        return nil;
    }
    
    NSDictionary *params = @{kAylaContactParamContact: [contact toServiceDictionary]};
    return
    [[AylaApiClient sharedUserServiceInstance] postPath:@"api/v1/users/contacts.json" parameters:params
                                                success:^(AylaHTTPOperation *operation, id responseObject) {
                                                    AylaContact *contact = [[AylaContact alloc] initWithDictionary:responseObject];
                                                    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Contact", @"contact", @"created", @"createContact");
                                                    successBlock(operation.response, contact);
                                                } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                    saveToLog(@"%@, %@, %@, %@", @"E", @"Contact", error.logDescription, @"createContact");
                                                    failureBlock(error);
                                                }];
}

+ (NSOperation *)getAllWithParams:(NSDictionary *)callParams
                          success:(void (^)(AylaResponse *resp, NSArray *contacts))successBlock
                          failure:(void (^)(AylaError *error))failureBlock
{
    return
    [[AylaApiClient sharedUserServiceInstance] getPath:@"api/v1/users/contacts.json" parameters:callParams
                                               success:^(AylaHTTPOperation *operation, id responseObject) {
                                                   NSArray *contactsDict = responseObject;
                                                   NSMutableArray *contacts = [NSMutableArray array];
                                                   for(NSDictionary *contactInfo in contactsDict) {
                                                       AylaContact *contact = [[AylaContact alloc] initWithDictionary:contactInfo];
                                                       [contacts addObject:contact];
                                                   }
                                                   saveToLog(@"%@, %@, %@:%ld, %@", @"I", @"contact", @"contacts", (unsigned long)contacts.count, @"getAllWithParams");
                                                   successBlock(operation.response, contacts);
                                               } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                   saveToLog(@"%@, %@, %@, %@", @"E", @"Contact", error.logDescription, @"getAllWithParams");
                                                   failureBlock(error);
                                               }];
}

+ (NSOperation *)getWithId:(NSNumber *)contactId params:(NSDictionary *)callParams
                   success:(void (^)(AylaResponse *resp, AylaContact *contact))successBlock
                   failure:(void (^)(AylaError *error))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    if(!contactId) {
        [errors setObject:@"can't be blank" forKey:kAylaContactParamId];
    }
    
    if(errors.count > 0) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:errors];
        failureBlock(error);
        return nil;
    }

    return
    [[AylaApiClient sharedUserServiceInstance] getPath:[NSString stringWithFormat:@"api/v1/users/contacts/%@.json",  contactId] parameters:nil
                                               success:^(AylaHTTPOperation *operation, id responseObject) {
                                                   AylaContact *contact = [[AylaContact alloc] initWithDictionary:responseObject];
                                                   saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Contact", @"contact", contact.displayName, @"getWithId");
                                                   successBlock(operation.response, contact);
                                               } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                   saveToLog(@"%@, %@, %@, %@", @"E", @"Contact", error.logDescription, @"getWithId");
                                                   failureBlock(error);
                                               }];
}

+ (NSOperation *)update:(AylaContact *)contact withParams:(NSDictionary *)callParams
               success:(void (^)(AylaResponse *resp, AylaContact *updatedContact))successBlock
               failure:(void (^)(AylaError *error))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    if(!contact.id) {
        [errors setObject:@"can't be blank" forKey:kAylaContactParamId];
    }
    
    if(errors.count > 0) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:errors];
        failureBlock(error);
        return nil;
    }
    
    NSDictionary *params = @{kAylaContactParamContact: callParams?:@{}};
    
    return
    [[AylaApiClient sharedUserServiceInstance] putPath:[NSString stringWithFormat:@"api/v1/users/contacts/%@.json", contact.id] parameters:params
                                               success:^(AylaHTTPOperation *operation, id responseObject) {
                                                   [contact updateWithDictionary:(NSDictionary *)responseObject];
                                                   saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Contact", @"contact", contact.displayName, @"getWithId");
                                                   successBlock(operation.response, contact);
                                               } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                   saveToLog(@"%@, %@, %@, %@", @"E", @"Contact", error.logDescription, @"getWithId");
                                                   failureBlock(error);
                                               }];
}


+ (NSOperation *)delete:(AylaContact *)contact withParams:(NSDictionary *)callParams
                success:(void (^)(AylaResponse *resp))successBlock
                failure:(void (^)(AylaError *error))failureBlock
{
    NSMutableDictionary *errors = [NSMutableDictionary new];
    if(!contact.id) {
        [errors setObject:@"can't be blank" forKey:kAylaContactParamId];
    }
    
    if(errors.count > 0) {
        AylaError *error = [AylaError createWithCode:AML_USER_INVALID_PARAMETERS httpCode:0 nativeError:nil andErrorInfo:errors];
        failureBlock(error);
        return nil;
    }
    
    return [[AylaApiClient sharedUserServiceInstance] deletePath:[NSString stringWithFormat:@"api/v1/users/contacts/%@.json", contact.id]
                                                      parameters:nil
                                                         success:^(AylaHTTPOperation *operation, id responseObject) {
                                                             saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Contact", @"contact", contact.displayName, @"deleteContact");
                                                             successBlock(operation.response);
                                                         } failure:^(AylaHTTPOperation *operation, AylaError *error) {
                                                             saveToLog(@"%@, %@, %@:%ld, %@:%ld, %@", @"E", @"Contact", @"NSError.code", (long)error.nativeErrorInfo.code, @"http", (long)operation.response.httpStatusCode, @"deleteContact");
                                                             failureBlock(error);
                                                         }];
}

- (void)updateWithDictionary:(NSDictionary *)dictionary
{
    if([dictionary objectForKey:kAylaContactParamContact]) {dictionary = dictionary[kAylaContactParamContact]; };
    
    self.id = [[dictionary objectForKey:kAylaContactParamId] nilIfNull];
    self.firstName = [[dictionary objectForKey:kAylaContactParamFirstName] nilIfNull];
    self.lastName = [[dictionary objectForKey:kAylaContactParamLastName] nilIfNull];
    self.displayName = [[dictionary objectForKey:kAylaContactParamDisplayName] nilIfNull];
    self.email = [[dictionary objectForKey:kAylaContactParamEmail] nilIfNull];
    self.phoneCountryCode = [[dictionary objectForKey:kAylaContactParamPhoneCountryCode] nilIfNull];
    self.phoneNumber = [[dictionary objectForKey:kAylaContactParamPhoneNumber] nilIfNull];
    self.streetAddress = [[dictionary objectForKey:kAylaContactParamStreetAddress] nilIfNull];
    self.zipCode = [[dictionary objectForKey:kAylaContactParamZipCode] nilIfNull];
    self.country = [[dictionary objectForKey:kAylaContactParamCountry] nilIfNull];
    self.emailAccept = [[dictionary objectForKey:kAylaContactParamEmailAccept] nilIfNull];
    self.emailNotification = [[dictionary objectForKey:kAylaContactParamEmailNotification] boolValue];
    self.smsAccept = [[dictionary objectForKey:kAylaContactParamSmsAccept] nilIfNull];
    self.smsNotification = [[dictionary objectForKey:kAylaContactParamSmsNotification] boolValue];
    self.pushNotification = [[dictionary objectForKey:kAylaContactParamPushNotification] boolValue];
    self.notes = [[dictionary objectForKey:kAylaContactParamNotes] nilIfNull];
    self.oemModels = [[dictionary objectForKey:kAylaContactParamOemModels] nilIfNull];
    self.metadata = [[dictionary objectForKey:kAylaContactParamMetadata] nilIfNull];
    self.updatedAt = [[dictionary objectForKey:kAylaContactParamUpdatedAt] nilIfNull];
}

- (NSDictionary *)toServiceDictionary {
    NSDictionary *contactInfos =
    @{
      kAylaContactParamFirstName: _firstName?:[NSNull null],
      kAylaContactParamLastName: _lastName?:[NSNull null],
      kAylaContactParamDisplayName: _displayName?:[NSNull null],
      kAylaContactParamEmail: _email?:[NSNull null],
      kAylaContactParamPhoneCountryCode: _phoneCountryCode?:[NSNull null],
      kAylaContactParamPhoneNumber: _phoneNumber?:[NSNull null],
      kAylaContactParamStreetAddress: _streetAddress?:[NSNull null],
      kAylaContactParamZipCode: _zipCode?:[NSNull null],
      kAylaContactParamCountry: _country?:[NSNull null],
      
      kAylaContactParamEmailAccept: _emailAccept?:AylaContactAcceptNotReq,
      kAylaContactParamEmailNotification: @(_emailNotification),
      kAylaContactParamSmsAccept: _smsAccept?:AylaContactAcceptNotReq,
      kAylaContactParamSmsNotification: @(_smsNotification),
      kAylaContactParamPushNotification: @(_pushNotification),
      
      kAylaContactParamMetadata: _metadata?:[NSNull null],
      kAylaContactParamNotes: _notes?:[NSNull null],
      kAylaContactParamOemModels: _oemModels?:[NSNull null]
      };
    return contactInfos;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, Id: %@, FirstName: %@, LastName: %@, DisplayName: %@, Email: %@, PhoneCountryCode: %@, PhoneNumber: %@> ", NSStringFromClass([self class]), self, self.id, self.firstName, self.lastName, self.displayName, self.email, self.phoneCountryCode, self.phoneNumber];
}

static NSString * const kAylaContactParamId = @"id";
static NSString * const kAylaContactParamUpdatedAt = @"updated_at";
static NSString * const kAylaContactParamContact = @"contact";
static NSString * const kAylaContactParamContacts = @"contacts";

@end

NSString * const kAylaContactParamFirstName = @"firstname";
NSString * const kAylaContactParamLastName = @"lastname";
NSString * const kAylaContactParamDisplayName = @"display_name";
NSString * const kAylaContactParamEmail = @"email";
NSString * const kAylaContactParamPhoneCountryCode = @"phone_country_code";
NSString * const kAylaContactParamPhoneNumber = @"phone_number";
NSString * const kAylaContactParamStreetAddress = @"street_address";
NSString * const kAylaContactParamZipCode = @"zip_code";
NSString * const kAylaContactParamCountry = @"country";

NSString * const kAylaContactParamEmailAccept = @"email_accept";
NSString * const kAylaContactParamEmailNotification = @"email_notification";

NSString * const kAylaContactParamSmsAccept = @"sms_accept";
NSString * const kAylaContactParamSmsNotification = @"sms_notification";

NSString * const kAylaContactParamPushNotification = @"push_notification";

NSString * const kAylaContactParamMetadata = @"metadata";
NSString * const kAylaContactParamNotes = @"notes";
NSString * const kAylaContactParamOemModels = @"oem_models";

NSString * const kAylaContactParamFilter = @"filter";

NSString * const AylaContactAcceptNotReq = @"not_req";
NSString * const AylaContactAcceptReq = @"req";
NSString * const AylaContactAcceptPending = @"pending";
NSString * const AylaContactAcceptAccepted = @"accepted";
NSString * const AylaContactAcceptDenied = @"denied";