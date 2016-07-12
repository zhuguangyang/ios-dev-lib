//
//  AylaHttpServer.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/8/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import "HTTPConnection.h"
#import "HTTPDataResponse.h"
#import "HTTPServer.h"

@interface AylaHttpServer : HTTPServer
-(id) initWithPort:(int) portNum;
@end

@interface AylaHttpServerConnection : HTTPConnection

@property (strong, nonatomic) NSString *hostIp;

@end

@interface AylaHttpResponce : HTTPDataResponse
- (id)initWithData:(int)httpStatus headerParam:(NSDictionary *)headerParam dataParam:(NSData *)dataParam;
@end
