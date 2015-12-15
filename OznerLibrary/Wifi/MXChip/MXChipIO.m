//
//  MXChipIO.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/8.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "MXChipIO.h"
#import "../../Device/BaseDeviceIO.hpp"
#import "../../Helper/Helper.h"

@implementation MXChipIO
-(instancetype)init:(NSString *)identifier MQTT:(MQTTProxy*)proxy Type:(NSString *)type
{
    if (self=[super init:identifier Type:type])
    {
        self->proxy=proxy;
    }
    return self;
}

-(void)close
{
    if (runThread)
    {
        [runThread cancel];
        runThread=nil;
    }
 
}

-(BOOL)send:(NSData*) data
{
    if (!runThread) return false;
    if ([[NSThread currentThread] isEqual:runThread])
    {
        return [self postSend:data];
    }else
    {
        [self performSelector:@selector(postSend:) onThread:runThread withObject:data waitUntilDone:false];
        return errorinfo==nil;
    }
}

-(BOOL)postSend:(NSData*)data
{
    [self doSend:data];
    return [proxy publish:inKey Data:data];
}

-(BOOL)runJob:(SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait
{
    if (runThread==NULL) return false;
    if (runThread.isCancelled) return false;
    [self performSelector:aSelector onThread:runThread withObject:arg waitUntilDone:wait];
    return true;
}

-(void)runThreadProc
{
    int msgId=0;
    @try {
        if (!proxy.connected)
            return ;
        [self doConnecting];
        
        msgId=[proxy registerOnPublish:^(NSString *topic, NSData *data) {
            if (outKey)
            {
                if ([topic isEqualToString:outKey])
                    [self doRecv:data];
            }
        }];

        if (![proxy subscribe:outKey])
            return;
        [self doConnected];
        
        if (![self doInit])
            return;
        
        [self doReady];
        while (![[NSThread currentThread] isCancelled]) {
            [[NSRunLoop currentRunLoop] run];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception:%@",[exception debugDescription]);
    }
    @finally {
        [proxy unsubscribe:outKey];
        [self->proxy unregisterOnPublish:msgId];
        [self doDisconnect];
    }
}

-(void)doDisconnect
{
    [self.statusDelegate IOClosed:self];
    [super doDisconnect];
    
}

-(void)open
{
    if (StringIsNullOrEmpty(outKey))
    {
        @throw [NSException exceptionWithName:@"MXChioIO" reason:@"out IsNull" userInfo:nil];
    }
    if (runThread) return;
    runThread=[[NSThread alloc] initWithTarget:self selector:@selector(runThreadProc) object:nil];
    [runThread start];
}

-(void)setSecureCode:(NSString*)secureCode;
{
    self->inKey=[NSString stringWithFormat:@"%@/%@/in",secureCode,[[self.identifier stringByReplacingOccurrencesOfString:@":" withString:@""] lowercaseString]];
    self->outKey=[NSString stringWithFormat:@"%@/%@/out",secureCode,[[self.identifier stringByReplacingOccurrencesOfString:@":" withString:@""] lowercaseString]];
}


@end
