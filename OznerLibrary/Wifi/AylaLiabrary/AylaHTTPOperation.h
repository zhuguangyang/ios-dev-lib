//
//  AylaHTTPOperation.h
//  iOS_AylaLibrary
//
//  Created by Yipei Wang on 4/29/15.
//  Copyright (c) 2015 AylaNetworks. All rights reserved.
//

#import "AylaConnectionOperation.h"

#define AML_HTTP_OPERATION_DEFAULT_TIMEOUT 60

@interface AylaHTTPOperation : AylaConnectionOperation

@property (nonatomic, strong) id task;
@property (nonatomic, strong) AylaResponse *response;
@property (nonatomic, strong) id responseObject;

- (instancetype)initWithTask:(id)task;

@end
