//
//  AylaLanMessage.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 5/12/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AylaMessage.h"

extern NSString * const kAylaLanMessageParamCmdId;
extern NSString * const kAylaLanMessageParamStatus;
extern NSString * const kAylaLanMessageParamId;

extern NSString * const kAylaLanMessageParamData;
extern NSString * const kAylaLanMessageParamName;
extern NSString * const kAylaLanMessageParamValue;

extern NSString * const AylaLanPathDatapoint;
extern NSString * const AylaLanPathConnStatus;
extern NSString * const AylaLanPathCommands;
extern NSString * const AylaLanPathDatapointAck;

extern NSString * const AylaLanPathNodePrefix;
extern NSString * const AylaLanPathLocalLanPrefix;

@class AylaLanSession;
@interface AylaLanMessage : AylaMessage

@property (strong, nonatomic) NSDictionary *urlParams;

@property (getter = isCallback, nonatomic) BOOL isCallback;

- (instancetype)initWithMethod:(AylaMessageMethod)method urlString:(NSString *)urlString contents:(id)contents contextHandler:(AylaLanSession *)session;

- (NSUInteger) cmdId;
- (NSInteger)  status;

@end
