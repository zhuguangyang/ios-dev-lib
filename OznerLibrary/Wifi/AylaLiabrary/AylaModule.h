//
//  AylaModule.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 1/23/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaDevice.h"

@class AylaWiFiStatus;
@interface AylaModule : AylaDevice

    @property (nonatomic, copy) NSString *deviceService;
    @property (nonatomic, copy) NSNumber *lastConnectMtime;
    @property (nonatomic, copy) NSNumber *mtime;
    @property (nonatomic, copy) NSString *version;
    @property (nonatomic, copy) NSString *apiVersion;
    @property (nonatomic, copy) NSString *build;
    @property (nonatomic, copy) NSString *connectorLanIp;
    @property (nonatomic, assign, getter=hasConnected) BOOL hasConnected;

    - (void)startListeningDisconnection;

@end

