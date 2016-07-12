//
//  AylaConnectivityListener.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 6/25/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AylaConnectivityListener : NSObject
- (void) startNotifier;
- (void) networkChanged:(NSNotification *)notification;
@end
