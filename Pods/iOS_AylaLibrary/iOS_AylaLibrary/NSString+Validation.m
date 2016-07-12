//
//  NSString+Validation.m
//  iOS_AylaLibrary
//
//  Created by Emanuel Peña Aguilar on 1/25/16.
//  Copyright © 2016 AylaNetworks. All rights reserved.
//

#import "NSString+Validation.h"
#import "AylaNetworks.h"
#import "AylaErrorSupport.h"

NSString * const kNSStringValidationEmail = @"email";

@implementation NSString (Validation)
- (BOOL)ayla_validateAsEmail:(AylaError *__autoreleasing *)error {
    NSMutableDictionary *errors = [[NSMutableDictionary alloc] init];
    if(self == nil)
    {
        [errors setObject:@"can't be blank." forKey:kNSStringValidationEmail];
    }
    else {
        NSString *aylaEmailRegEx = @"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$";
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:aylaEmailRegEx
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:self
                                                            options:0
                                                              range:NSMakeRange(0, [self length])];
        if(numberOfMatches == 0){
            [errors setObject:@"is invalid" forKey:kNSStringValidationEmail];
        }
    }
    
    if([errors count] != 0){
        AylaError *err = [AylaError new];
        err.errorCode = AML_USER_INVALID_PARAMETERS;
        err.errorInfo = errors;
        err.nativeErrorInfo = nil;
        err.httpStatusCode = 0;
        *error = err;
        return YES;
    }
    return NO;
}
@end
