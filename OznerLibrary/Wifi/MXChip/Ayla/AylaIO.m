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
#import "OznerManager.h"
@implementation AylaIO
-(instancetype)init:(AylaDevice*)device
{
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
        [self doConnecting];
        properties=[[NSMutableDictionary alloc] init];
        
        self->_aylaDevice=device;
        //privatAylaDevice=device;
        //NSLog(@"");
        [device getProperties:nil success:^(AylaResponse *response, NSArray *Properties) {
            //NSLog(@"%@,%@",response,Properties);
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
        //[self performSelector:@selector(postSend:) onThread:runThread withObject:op waitUntilDone:false];
        [self postSend:op];
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
    NSLog(@"%@",data.data);
    AylaProperty* tmpPros=[self getAylaProperty:[(id)data.data objectForKey:@"name"]];
    if (tmpPros != nil)
    {
        if (data.callback)
            data.callback(nil);
        AylaDatapoint* datapoint=[[AylaDatapoint alloc] init];
        NSString* tmpValue=[(id)data.data objectForKey:@"value"];
        [datapoint setNValue:[NSNumber numberWithInt:tmpValue.intValue]];
        [datapoint setSValue:tmpValue];

        [tmpPros createDatapoint:datapoint success:^(AylaResponse *response, AylaDatapoint *datapointCreated) {
            NSLog(@"postSend:Send Data Success");
            
        } failure:^(AylaError *err) {
            NSLog(@"postSend:Send Data Success%@",err);
            
        }];
        
        return true;
    }else
    {
        if (data.callback)
            data.callback([NSError errorWithDomain:@"Ayla send error" code:0 userInfo:nil]);
        return false;
    }
}
//第一关键
-(void)updateProperty
{
    //NSLog(@"_aylaDeviceName:%@",_aylaDevice.productName);
    if ([[_aylaDevice connectionStatus] isEqualToString:@"OffLine"])
    {
        [self doDisconnect];
        return ;
    }
    else
    {
        [self doConnected];
    }
    [_aylaDevice getProperties:nil success:^(AylaResponse *response, NSArray *Properties) {
        //NSLog(@"%@,%@",response,Properties);
        NSMutableArray* apArr=[[NSMutableArray alloc] init];
        @synchronized(properties) {
            for (int i=0; i<Properties.count; i++) {
                AylaProperty* tmpP=[Properties objectAtIndex:i];
                AylaProperty* property = [properties objectForKey:tmpP.name];
                if (property != nil) {
                    if (property.value != nil) {
                        
                        if (![[property value] isEqual:tmpP.value]) {
                            [apArr addObject:tmpP];
                        }
                    }
                }
                [properties setObject:tmpP forKey:tmpP.name];
            }
            
            NSMutableDictionary *json=[[NSMutableDictionary alloc] init];
            if (apArr.count > 0) {
                for (AylaProperty* p in apArr) {
                    [json setObject:p.value forKey:p.name];
                }
            }
            //第二关键
            [self doRecv:(NSData*)json];
            
        }
    } failure:^(AylaError *err) {
        NSLog(@"%@",err);
    }];
}
-(NSString*) getProperty:(NSString*) name {
    AylaProperty* property = [self getAylaProperty:name];
    if (property != nil) {
        return [property datapoint].value;
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

-(void)runThreadProc
{
    @try {
        if (![[_aylaDevice connectionStatus] isEqualToString:@"OffLine"])
        {
            [self doConnected];
            return ;
        }
        
//        [self doConnecting];
//        
//        
//        [AylaDevice registerNewDevice:_aylaDevice success:^(AylaResponse *response, AylaDevice *registeredDevice) {
//            NSLog(@"Ayla Device Register Success%@",registeredDevice);
//            AylaIO* tmpIo= [[[[OznerManager instance] ioManager] aylaIOManager] createAylaIO:registeredDevice];
//            tmpIo.name=registeredDevice.productName;
//            OznerDevice* device=[[OznerManager instance] getDeviceByIO:tmpIo];
//            //[[OznerManager instance] save:device];
//        } failure:^(AylaError *err) {
//            NSLog(@"%@",err);
//            //runThread=nil;
//            //[self.delegate PairFailure];
//        }];
//        
//        [self doConnected];
//        
//        if (![self doInit])
//            return;
//        
//        [self doReady];
        while (![[NSThread currentThread] isCancelled]) {
            [[NSRunLoop currentRunLoop] run];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception:%@",[exception debugDescription]);
    }
    @finally {
        //[proxy unsubscribe:outKey];
        //[self->proxy unregisterOnPublish:msgId];
        //[self doDisconnect];
    }
}

//-(void)doDisconnect
//{
//    [self.statusDelegate IOClosed:self];
//    [super doDisconnect];
//    
//}

-(void)open
{
    
    if (runThread) return;
    runThread=[[NSThread alloc] initWithTarget:self selector:@selector(runThreadProc) object:nil];
    [runThread start];
}




@end
