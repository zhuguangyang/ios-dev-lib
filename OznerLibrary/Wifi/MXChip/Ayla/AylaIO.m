//
//  AylaIO.m
//  OznerLibraryDemo
//
//  Created by 赵兵 on 16/7/13.
//  Copyright © 2016年 Ozner. All rights reserved.
//

#import "AylaIO.h"
#import "BaseDeviceIO.hpp"
#import "Helper.h"
@implementation AylaIO
-(instancetype)init:(AylaDevice*)device
{
    //
    NSString* tmpMac=device.mac.uppercaseString;
    self->address=[NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",
                   [tmpMac substringWithRange:NSMakeRange(0, 2)],
                   [tmpMac substringWithRange:NSMakeRange(2, 2)],
                   [tmpMac substringWithRange:NSMakeRange(4, 2)],
                   [tmpMac substringWithRange:NSMakeRange(6, 2)],
                   [tmpMac substringWithRange:NSMakeRange(8, 2)],
                   [tmpMac substringWithRange:NSMakeRange(10, 2)]];
    if (self=[super init:self->address Type:device.model])
    {
        _ayladevice=device;
        [device getProperties:nil success:^(AylaResponse *response, NSArray *Properties) {
            NSLog(@"%@,%@",response,Properties);
            @synchronized(properties) {
                for (int i=0; i<Properties.count; i++) {
                    AylaProperty* tmpPro=(AylaProperty*)[Properties objectAtIndex:i];
                    [properties setValue:tmpPro forKey:tmpPro.name];
                }
            }
            [self doConnected];
            [self doInit];
            [self doReady];
        } failure:^(AylaError *err) {
            NSLog(@"%@",err);
        }];
        [self doConnecting];
    }
    return self;
}
-(void) doConnected
{
    self->connectStatus=Connected;
    [super doConnected];
}
-(void) doDisconnect
{
    self->connectStatus=Disconnect;
    [super doDisconnect];
}
-(void) doConnecting
{
    self->connectStatus=Connecting;
    [super doConnecting];
}
//私有的
-(AylaProperty*)getAylaProperty:(NSString*) name
{
    @synchronized(properties) {
        return (AylaProperty*)[properties objectForKey:name];
    }
}
-(NSString*)getAddress{
    return address;
}


-(void)close
{
    if (runThread)
    {
        [runThread cancel];
        runThread=nil;
    }
    
}
-(void)send:(NSData *)data Callback:(OperateCallback)cb
{
    if (!runThread)
    {
        return;
    }
    OperateData* op=[OperateData Operate:data Callback:cb];
    if ([[NSThread currentThread] isEqual:runThread])
    {
        [self postSend:op];
    }else
    {
        [self performSelector:@selector(postSend:) onThread:runThread withObject:op waitUntilDone:false];
    }
}

-(BOOL)send:(NSData*) data
{
    if (!runThread) return false;
    OperateData* op=[OperateData Operate:data Callback:nil];
    if ([[NSThread currentThread] isEqual:runThread])
    {
        return [self postSend:op];
    }else
    {
        [self performSelector:@selector(postSend:) onThread:runThread withObject:op waitUntilDone:false];
        return errorinfo==nil;
    }
}

-(BOOL)postSend:(OperateData*)data
{
    
    AylaProperty* tmpPros=[self getAylaProperty:[(id)data objectForKey:@"name"]];
    if (tmpPros != nil)
    {
        if (data.callback)
            data.callback(nil);
        AylaDatapoint* datapoint;
        if ([[tmpPros baseType] isEqualToString:@"boolean"]) {
            [datapoint setNValue:[(id)data objectForKey:@"value"]];
            //datapoint.nValue(new Byte(object.getBoolean("value") ? (byte) 1 : (byte) 0));
        } else
            [datapoint setNValue:[(id)data objectForKey:@"value"]];
        [tmpPros createDatapoint:datapoint success:^(AylaResponse *response, AylaDatapoint *datapointCreated) {
            NSLog(@"%@,%@",response,datapointCreated);
            
        } failure:^(AylaError *err) {
            NSLog(@"%@",err);
            
        }];
        //property.createDatapoint(new ParamHandler(callback), datapoint);
        return true;
    }else
    {
        if (data.callback)
            data.callback([NSError errorWithDomain:@"Ayla send error" code:0 userInfo:nil]);
        return false;
    }
}
-(void)updateProperty
{
    
    [_ayladevice getProperties:nil success:^(AylaResponse *response, NSArray *Properties) {
        NSLog(@"%@,%@",response,Properties);
        NSMutableArray* ap;
        @synchronized(properties) {
            for (int i=0; i<Properties.count; i++) {
                AylaProperty* tmpP=[Properties objectAtIndex:i];
                AylaProperty* property = [properties objectForKey:tmpP.name];
                if (property != nil) {
                    if (property.value != nil) {
                        
                        if (![[property value] isEqual:tmpP.value]) {
                            [ap addObject:tmpP];
                        }
                    }
                }
                [properties setObject:tmpP forKey:tmpP.name];
            }
            
            NSMutableDictionary *json;
            if (ap.count > 0) {
                for (AylaProperty* p in ap) {
                    [json setObject:p.value forKey:p.name];
                }
            }
            
            [self doRecv:[NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil]];
            
        }
    } failure:^(AylaError *err) {
        NSLog(@"%@",err);
    }];
}
-(NSString*) getProperty:(NSString*) name {
    AylaProperty* property = [self getAylaProperty:name];
    if (property != nil) {
        return [property datapoint].value;//.datapoint.value();
    } else
        return nil;
}
-(BOOL)runJob:(SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait
{
    if (runThread==NULL) return false;
    if (runThread.isCancelled) return false;
    [self performSelector:aSelector onThread:runThread withObject:arg waitUntilDone:wait];
    return true;
}

//-(void)runThreadProc
//{
//    int msgId=0;
//    @try {
//        if (!proxy.connected)
//            return ;
//        [self doConnecting];
//        
//        msgId=[proxy registerOnPublish:^(NSString *topic, NSData *data) {
//            if (outKey)
//            {
//                if ([topic isEqualToString:outKey])
//                    [self doRecv:data];
//            }
//        }];
//        
//        if (![proxy subscribe:outKey])
//            return;
//        [self doConnected];
//        
//        if (![self doInit])
//            return;
//        
//        [self doReady];
//        while (![[NSThread currentThread] isCancelled]) {
//            [[NSRunLoop currentRunLoop] run];
//        }
//    }
//    @catch (NSException *exception) {
//        NSLog(@"exception:%@",[exception debugDescription]);
//    }
//    @finally {
//        [proxy unsubscribe:outKey];
//        [self->proxy unregisterOnPublish:msgId];
//        [self doDisconnect];
//    }
//}

//-(void)doDisconnect
//{
//    [self.statusDelegate IOClosed:self];
//    [super doDisconnect];
//    
//}

-(void)open
{
//    if (StringIsNullOrEmpty(outKey))
//    {
//        @throw [NSException exceptionWithName:@"MXChioIO" reason:@"out IsNull" userInfo:nil];
//    }
//    if (runThread) return;
//    runThread=[[NSThread alloc] initWithTarget:self selector:@selector(runThreadProc) object:nil];
//    [runThread start];
}

//-(void)setSecureCode:(NSString*)secureCode;
//{
//    self->inKey=[NSString stringWithFormat:@"%@/%@/in",secureCode,[[self.identifier stringByReplacingOccurrencesOfString:@":" withString:@""] lowercaseString]];
//    self->outKey=[NSString stringWithFormat:@"%@/%@/out",secureCode,[[self.identifier stringByReplacingOccurrencesOfString:@":" withString:@""] lowercaseString]];
//}


@end
