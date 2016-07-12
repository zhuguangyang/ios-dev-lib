//
//  AylaLogManagerSupport.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/28/15.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaLogManager (Support)

/**
 *  This method is used to log messages in old format.
 *  @attention Designed to maintain backward compatibility. Avoid to use this method.
 */
- (void)logOldFormat:(NSString *)fmt, ... NS_FORMAT_FUNCTION(1, 2);

@end
