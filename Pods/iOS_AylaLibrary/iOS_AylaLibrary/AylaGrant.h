//
//  AylaGrant.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 6/19/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaGrant : NSObject

@property (nonatomic, strong) NSString *userId; // The target user id that created this share. Returned with create/POST & update/PUT operations

@property (nonatomic, strong) NSString *shareId; // The unique share id associated with this grant

@property (nonatomic, strong) NSString *operation; // Access permissions allowed: either read or write. Used with create/POST & update/PUT operations. Ex: 'write', Optional
                                                   // If omitted, the default access permitted is read only

@property (nonatomic, strong) NSString *startDateAt; // When this named resource will be shared. Used with create/POST & update/PUT operations. Ex: '2014-03-17 12:00:00', Optional
                                                     // If omitted, the resource will be shared immediately. UTC DateTime value.

@property (nonatomic, strong) NSString *endDateAt; // When this named resource will stop being shared. Used with create/POST & update/PUT operations. Ex: '2020-03-17 12:00:00', Optional
                                                   // If omitted, the resource will be shared until the share or named resource is deleted. UTC DateTime value

@property (nonatomic, strong) NSString *role; //Role of the share.
@end
