//
//  AylaDeviceGatewaySupport.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 7/29/14.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaDeviceGateway (Support)

- (void) updateNodesFromGlobalDeviceList:(NSArray *)devices;
- (NSArray *) updateNodesConnStatusWithArray:(NSArray *)connStatusArray toBeNotified:(BOOL)toBeNotified;

@end
