//
//  MQTTProxy.m
//  MxChip
//
//  Created by Zhiyongxu on 15/12/8.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "MQTTProxy.h"
#import "../../Helper/Helper.h"

@implementation MQTTProxy

#define defalutWaitTime 1

-(instancetype)init
{
    if (self=[super init])
    {
        clientId=[NSString stringWithFormat:@"v1-app-%@",[Helper rndString:12]];
        registerSeedId=0;
        onPublishList=[[NSMutableDictionary alloc] init];
        self->runThread=[[NSThread alloc] initWithTarget:self selector:@selector(runThreadProc) object:nil];
        [self->runThread start];
        while (runLoop==NULL) sleep(0.01);
        session=[[MQTTSession alloc] initWithClientId:clientId runLoop:runLoop forMode:NSDefaultRunLoopMode];
        session.delegate=self;
        waitTime=defalutWaitTime;
        isQuit=false;
        [self reConnect];
    }
    return self;
}

-(void)runThreadProc
{
    runLoop=[NSRunLoop currentRunLoop];
    while([NSThread currentThread].isCancelled)
    {
        [[NSRunLoop currentRunLoop] run];
    }
}

-(int)registerOnPublish:(MQTTProxyOnPublishHandler)onPublishHandler;
{
    @synchronized(onPublishList) {
        registerSeedId++;
        [onPublishList setObject:[onPublishHandler copy] forKey:[NSNumber numberWithUnsignedInteger:registerSeedId]];
        return registerSeedId;
    }
}

-(void)unregisterOnPublish:(int)registerId
{
    @synchronized(onPublishList) {
        [onPublishList removeObjectForKey:[NSNumber numberWithInt:registerId]];
    }
}

-(BOOL)subscribe:(NSString *)topic
{
    return [session subscribeAndWaitToTopic:topic atLevel:MQTTQosLevelAtMostOnce];
}

-(BOOL)unsubscribe:(NSString *)topic
{
    return [session unsubscribeAndWaitTopic:topic];
}
-(BOOL)publish:(NSString*)topic Data:(NSData*)data
{
    return [session publishAndWaitData:data onTopic:topic retain:false qos:MQTTQosLevelAtLeastOnce];
}

-(void)newMessage:(MQTTSession *)session data:(NSData *)data onTopic:(NSString *)topic qos:(MQTTQosLevel)qos retained:(BOOL)retained mid:(unsigned int)mid
{
    NSArray* array=nil;
    @synchronized(onPublishList) {
        [NSArray arrayWithArray:[onPublishList allValues]];
    }
    for (MQTTProxyOnPublishHandler handler in array)
    {
        handler(topic,data);
    }
}
-(void)reConnect
{
    NSLog(@"start connect");
    [session connectToHost:MQTT_HOST port:MQTT_PORT];
}


-(void)connected:(MQTTSession *)session
{
    waitTime=defalutWaitTime;
    self->_connected=true;
    NSLog(@"mqtt connected");
    [self.delegate MQTTProxyConnected:self];
    
}

-(void)connectionClosed:(MQTTSession *)session
{
    NSLog(@"mqtt connectionClosed");
    self->_connected=true;
     [self.delegate MQTTProxyDisconnected:self];
    if (!isQuit)
    {
        sleep(waitTime);
        waitTime=waitTime*2;
        if (waitTime>10) waitTime=10;
        [self reConnect];
    }
}

-(void)connectionError:(MQTTSession *)session error:(NSError *)error
{
    NSLog(@"mqtt connectionError:%@",[error debugDescription]);
}
@end
