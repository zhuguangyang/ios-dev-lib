//
//  NSString+Validation.h
//  iOS_AylaLibrary
//
//  Created by Emanuel Peña Aguilar on 1/25/16.
//  Copyright © 2016 AylaNetworks. All rights reserved.
//
@class AylaError;
#import <Foundation/Foundation.h>

extern NSString * const kNSStringValidationEmail;

/**
 Adds validation methods which act on the receiving string.
 */
@interface NSString (Validation)
/**
 Validates the receiver as an email with the `^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$` regular expression, returns an BOOL indicating if there was an `AylaError` which will be filled in the error parameter with the description of the problem in the `kNSStringValidationEmail` key of the `errorInfo` property.

@param error An `AylaError` with the description of the error in the `errorInfo` property.

@return YES if ther was an error NO otherwise.
*/
- (BOOL)ayla_validateAsEmail:(AylaError * __autoreleasing *)error;
@end
