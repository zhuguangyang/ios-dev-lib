//
//  AylaApiClientSupport.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 1/15/15.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaSystemUtils.h"
@interface AylaApiClient(Support)

+ (NSString *)buildUrlPathWithAppId:(NSString *)appId andSuffixUrl:(NSString *)suffixUrl isHttps:(BOOL)isHttps;
+ (NSString *)addLocation:(AylaServiceLocation)location toUrlPath:(NSString *)url;

@end
