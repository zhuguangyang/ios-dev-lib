//
//  AylaPingHelper.m
//  Ayla Mobile Library
//
//  Created by Yipei Wang on 2/27/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//
#import "AylaNetworks.h"
#import "AylaPingHelper.h"
#import <netinet/in.h>
#import <arpa/inet.h>

@implementation AylaPingHelper{
    void (^_block)(bool);
    struct sockaddr_in sock;
    int retryTimes;
}

@synthesize pinger = _pinger;

- (void)pingWithHostAddress: (NSString *)ip delay:(int)delay
               resultBlock: (void (^)(bool))block
{
    
    sock.sin_family = AF_INET;
    sock.sin_port = 8080;
    sock.sin_len = sizeof(struct sockaddr_in);
    sock.sin_addr.s_addr = inet_addr([ip cStringUsingEncoding:NSUTF8StringEncoding]);
    
    NSData * data= [NSData dataWithBytes:&sock length:sizeof(struct sockaddr_in)];
    _pinger = [SimplePing simplePingWithHostAddress:data];
    _pinger.delegate = self;
    _block = block;

    retryTimes = 3;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pinger start];
        [self performSelector:@selector(endPing) withObject:nil afterDelay:delay]; // This timeout is what retains the ping helper
    });
}


- (void)pingWithHostName:(NSString *)host delay:(int)delay
             resultBlock: (void (^)(bool))block
{
    _pinger = [SimplePing simplePingWithHostName:host];
    _pinger.delegate = self;
    _block = block;
    
    retryTimes = 3;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_pinger start];
        [self performSelector:@selector(endPing) withObject:nil afterDelay:delay]; // This timeout is what retains the ping helper
    });
}


- (void)endPing
{
	if (_pinger) { // If it hasn't already been killed, then it's timed out
        saveToLog(@"%@, %@, %@, %@", @"I", @"AylaPingHelper", @"failed", @"didReceivePingResponsePacket");
        [_pinger stop];
        _pinger = nil;
        _block(false);
    }
}

- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
{
    [_pinger sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet
{    
    if( --retryTimes > 0){
        usleep(100000);
        [_pinger sendPingWithData:nil];
    }
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error{
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
{
    saveToLog(@"%@, %@, %@, %@", @"I", @"AylaPingHelper", @"sucess", @"didReceivePingResponsePacket");
    [_pinger stop];
    _pinger = nil;
    _block(true);
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error{
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet{
}

@end
