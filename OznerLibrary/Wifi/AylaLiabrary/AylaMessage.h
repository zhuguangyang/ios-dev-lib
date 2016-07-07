//
//  AylaMessage.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 5/12/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, AylaMessageSource) {
    AylaMessageSourceHTTP,
    AylaMessageSourceLAN,
    AylaMessageSourceWebSocket,
    AylaMessageSourceLibrary
};

typedef NS_ENUM(uint16_t, AylaMessageType) {
    AylaMessageTypeUnknown,
    AylaMessageTypeCommands,
    AylaMessageTypePropertyGet,
    AylaMessageTypeDatapointUpdate,
    AylaMessageTypeDatapointUpdateWithAck,
    AylaMessageTypeConnStatusGet,
    AylaMessageTypeConnStatusUpdate,
    AylaMessageTypeDatapointAck
};

typedef NS_ENUM(uint8_t, AylaMessageMethod) {
    AylaMessageMethodGET,
    AylaMessageMethodPOST,
    AylaMessageMethodPUT,
    AylaMessageMethodDELETE
};

/**
 * Abstact class for messages
 */
@interface AylaMessage : NSObject

@property (assign, nonatomic) AylaMessageSource source;
@property (assign, nonatomic) AylaMessageMethod method;
@property (assign, nonatomic) AylaMessageType type;

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) id contents;

@property (weak, nonatomic) id contextHandler;

@end
