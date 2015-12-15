//
//  MXChipPair.m
//  MxChip
//
//  Created by Zhiyongxu on 15/11/26.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "MXChipPair.h"
#import "Pair/EasyLinkSender.h"
#import <SystemConfiguration/CaptiveNetwork.h>

#import "../../OznerManager.h"


@implementation MXChipPair
+(NSString*)getWifiSSID
{
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
    }
    NSDictionary *dctySSID = (NSDictionary *)info;
    NSString *ssid = [dctySSID objectForKey:@"SSID"];
    return ssid;
}
-(void) startMDNS
{
    self->serviceBrowser =[[NSNetServiceBrowser alloc] init];
    self->serviceBrowser.delegate=self;
    [self->serviceBrowser searchForServicesOfType:@"_easylink._tcp" inDomain:@"local."];
}
#define Timeout 120

-(void)run
{
//    if (![MXChipPair getWifiSSID])
//    {
//        [self.delegate mxChipFailure];
//    }
    [services removeAllObjects];
    device=NULL;
//    self->device=[[ConfigurationDevice alloc] init];
//    //device.ip=@"192.168.1.184";
//    device.name=@"EMW3162(43FD77)";
//    device.login_id=@"admin";
//    device.devPasswd=@"12345678";
    
    HttpServer* httpServer=[[HttpServer alloc] init:8000];
    httpServer.delegate=self;
    [httpServer start];
    [self.delegate mxChipPairSendConfiguration];
    EasyLinkSender* easy=[[EasyLinkSender alloc] init:ssid Password:password];
    @try {
        NSDate* time=[NSDate dateWithTimeIntervalSinceNow:0];
        BOOL v2=true;
        while (!device)
        {
            if ([NSThread currentThread].isCancelled)
                return;
            
            if (v2)
                [easy send_easylink_v2];
            else
                [easy send_easylink_v3];
            [NSThread sleepForTimeInterval:1.5f];
            
            
            int t=abs((int)[time timeIntervalSinceNow]);
            if ((t % 10)==0)
            {
                v2=!v2;
            }
            
            if (t>Timeout)
            {
                break;
            }
            
        }
    }
    @catch (NSException *exception) {
        NSLog(@"except:%@",[exception debugDescription]);
    }
    @finally {
        [httpServer close];
    }
  
    if (!device)
    {
        [self.delegate mxChipFailure];
        return;
    }
    if (device.activated)
    {
        NSRange range=[device.deviceId rangeOfString:@"/"];
        if (range.location!=NSNotFound)
        {
            NSString* tmp=[[device.deviceId substringFromIndex:range.length+range.length] uppercaseString];
            if (tmp.length== 12) {
                NSString* mac=[NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",
                               [tmp substringWithRange:NSMakeRange(0, 2)],
                               [tmp substringWithRange:NSMakeRange(2, 2)],
                               [tmp substringWithRange:NSMakeRange(4, 2)],
                               [tmp substringWithRange:NSMakeRange(6, 2)],
                               [tmp substringWithRange:NSMakeRange(8, 2)],
                               [tmp substringWithRange:NSMakeRange(10, 2)]];
                device.mac=mac;
                MXChipIO* io=[[OznerManager instance].ioManager.mxchip createMXChipIO:device.mac Type:device.type];
                io.name=device.name;
                [self.delegate mxChipComplete:io];
                
                return;
            }
        }
    }
    
    [self.delegate mxChipPairWaitConnectWifi];
    [self performSelectorOnMainThread:@selector(startMDNS) withObject:self waitUntilDone:false];
    self->semaphore = dispatch_semaphore_create(0);
    dispatch_semaphore_wait(self->semaphore,  dispatch_time(DISPATCH_TIME_NOW, Timeout * NSEC_PER_SEC));
    if ([NSThread currentThread].isCancelled)
        return;
    
    NSLog(@"dispatch_semaphore_wait");
    if (device.ip==nil)
    {
        [self.delegate mxChipFailure];
        return;
    }
    @try {
        [self.delegate mxChipPairActivate];
        
        if (![self activeDevice])
        {
            [self.delegate mxChipFailure];
        }
        
        MXChipIO* io=[[OznerManager instance].ioManager.mxchip createMXChipIO:device.mac Type:device.type];
        if (io!=NULL)
        {
            io.name=device.name;
            [self.delegate mxChipComplete:io];
        }else
        {
            [self.delegate mxChipFailure];
        }
        
        
      
    }
    @catch (NSException *exception) {
        [self.delegate mxChipFailure];
        runThread=nil;
    }
    @finally {
    }
}

-(NSString*)activeDevice
{
    @try {
        NSString* url=[NSString stringWithFormat:@"http://%@:%d/dev-activate",device.ip,8000];
        NSMutableURLRequest* request= [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        [request setHTTPMethod:@"POST"];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSMutableDictionary* dict=[[NSMutableDictionary alloc] init];
        [dict setObject:device.login_id forKey:@"login_id"];
        [dict setObject:device.devPasswd forKey:@"dev_passwd"];
        int token=[[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970]*1000;
        [dict setObject:[NSString stringWithFormat:@"%d",token] forKey:@"user_token"];
        NSError* error;
        NSError* jerror;
        
        NSData* data=[NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:&error];
        [request addValue:[NSString stringWithFormat:@"%d",(int)data.length] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:data];
        NSData* respone=[NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
        if (error!=NULL)
        {
            NSLog(@"request %@",[error debugDescription]);
        }
        NSDictionary* json= [NSJSONSerialization JSONObjectWithData:respone
                             options:NSJSONReadingMutableLeaves error:&jerror];
        
        return [NSString stringWithString:[json objectForKey:@"device_id"]];
    }
    @catch (NSException *exception) {
        NSLog(@"active exception:%@",[exception debugDescription]);
    }
    @finally {
        
    }

    
}
-(void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
    NSLog(@"netServiceBrowserWillSearch");
}
-(void)netServiceDidResolveAddress:(NSNetService *)sender
{
    for (NSData* ip in sender.addresses) {
        struct sockaddr_in* addr=(struct sockaddr_in*)[ip bytes];
        NSString* ip=[NSString stringWithCString:inet_ntoa(addr->sin_addr) encoding:NSASCIIStringEncoding];
        NSRange range=[sender.name rangeOfString:@"#"];
        if (range.location!=NSNotFound)
        {
            NSString* mac=[sender.name substringFromIndex:range.location+range.length];
            if ([device.name rangeOfString:mac].location!=NSNotFound)
            {
                device.ip=ip;
                NSDictionary* dict= [NSNetService dictionaryFromTXTRecordData:sender.TXTRecordData];
                device.mac=[[[NSString alloc]initWithData:[dict objectForKey:@"MAC"] encoding:NSUTF8StringEncoding] uppercaseString];
                dispatch_semaphore_signal(semaphore);
            }
        }
    }
}
-(void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
    NSLog(@"netServiceBrowserDidStopSearch");
}
-(void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    [services addObject:service];
    service.delegate=self;
    [service resolveWithTimeout:10];
}

-(void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *,NSNumber *> *)errorDict
{
    dispatch_semaphore_signal(semaphore);
}
-(void)onFTCfinished:(HttpServer *)server JSON:(NSString *)json
{
    @try {
        self->device=[ConfigurationDevice withJSON:json];
    }
    @catch (NSException *exception) {
        NSLog(@"onFTCfinished exception:%@",[exception debugDescription]);
    }
}
-(BOOL)isRuning
{
    return runThread!=nil;
}
-(void)cancel
{
    [runThread cancel];
    if (semaphore)
    {
        dispatch_semaphore_signal(semaphore);
    }
    
    runThread=nil;
}
-(void) start:(NSString*)ssid Password:(NSString*)password;
{
    if (runThread)
    {
        return;
    }
    self->services=[[NSMutableArray alloc] init];
    self->ssid=[NSString stringWithString:ssid];
    self->password=[NSString stringWithString:password];
    runThread=[[NSThread alloc] initWithTarget:self selector:@selector(run) object:NULL];
    [runThread start];
}
@end
