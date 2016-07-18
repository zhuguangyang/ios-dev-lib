//
//  MXChipPair.m
//  MxChip
//
//  Created by Zhiyongxu on 15/11/26.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import "WifiPair.h"
#import "Pair/EasyLinkSender.h"
#import <SystemConfiguration/CaptiveNetwork.h>
//#import "HTTPServer.h"
#import "HttpServer_Xu.h"
#import "../../OznerManager.h"


#import <AylaNetworks.h>
//#import "AylaUser+AylaControl.h"

#define Timeout 120
@implementation WifiPair
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



//庆科配网

-(void)run_QK
{
    
    @try {
        [services removeAllObjects];
        device=NULL;
        HttpServer_Xu* httpServer=[[HttpServer_Xu alloc] init:8000];
        httpServer.delegate=self;
        [httpServer start];
        [self.delegate SendConfiguration];
        EasyLinkSender* easy=[[EasyLinkSender alloc] init:ssid Password:password];
        @try {
            NSDate* time=[NSDate dateWithTimeIntervalSinceNow:0];
            bool v2=YES;
            while (!device)
            {
                
                if ([NSThread currentThread].isCancelled)
                    return;
                
                if (v2==YES)
                {
                    NSLog(@"send v2");
                    [easy send_easylink_v2];
                }
                else
                {
                    NSLog(@"send v3");
                    [easy send_easylink_v3];
                }
                
                [NSThread sleepForTimeInterval:1.0f];
                int t=abs((int)[time timeIntervalSinceNow]);
                v2=!v2;
                if (t>Timeout)
                {
                    break;
                }
            }
        }
        
        @finally {
            [httpServer close];
            //[MyHTTPConnection setFtcDelegate:nil];
            //[httpServer stop];
        }
        
        if (!device)
        {
            [self.delegate PairFailure];
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
                    [self.delegate PairComplete:io];
                    
                    return;
                }
            }
        }
        
        [self.delegate WaitConnectWifi];
        [self performSelectorOnMainThread:@selector(startMDNS) withObject:self waitUntilDone:false];
        self->semaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_wait(self->semaphore,  dispatch_time(DISPATCH_TIME_NOW, Timeout * NSEC_PER_SEC));
        if ([NSThread currentThread].isCancelled)
            return;
        
        NSLog(@"dispatch_semaphore_wait");
        if (device.ip==nil)
        {
            [self.delegate PairFailure];
            return;
        }
        [self.delegate ActivateDevice];
        
        if (![self activeDevice])
        {
            [self.delegate PairFailure];
        }
        
        MXChipIO* io=[[OznerManager instance].ioManager.mxchip createMXChipIO:device.mac Type:device.type];
        if (io!=NULL)
        {
            io.name=device.name;
            [self.delegate PairComplete:io];
        }else
        {
            [self.delegate PairFailure];
            return;
        }

    }
    @catch (NSException *exception) {
        [self.delegate PairFailure];
        NSLog(@"exception:%@",[exception debugDescription]);
    }
    @finally {
        runThread=nil;
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
-(void)onFTCfinished:(NSString *)json
{
    NSLog(@"json:%@",json);
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
-(void) start:(NSString*)Ssid Password:(NSString*)Password;
{

    
    if (runThread)
    {
        return;
    }
    self->services=[[NSMutableArray alloc] init];
    self->ssid=[NSString stringWithString:Ssid];
    self->password=[NSString stringWithString:Password];
    if ((runPairCount % 2)==0)
    {
        runThread=[[NSThread alloc] initWithTarget:self selector:@selector(run_Ayla) object:NULL];
    }else
    {
        runThread=[[NSThread alloc] initWithTarget:self selector:@selector(run_QK) object:NULL];
    }
    runPairCount++;
    [runThread start];
    startRunTime=[NSDate dateWithTimeIntervalSinceNow:0];
    //[self runNext];
    
}

//ayla所用--获取位置信息
- (void)initLocationManager
{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
}

//AYLA 配网步骤
-(void)run_Ayla
{
    
    [self initLocationManager];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=WIFI"]];
    [self connectToNewDevice];
    
}
//1
static AylaModule *foundDevice_Ayla = nil;
-(void)connectToNewDevice{
    [AylaSetup connectToNewDevice:^(AylaResponse *response, AylaModule *newdevice) {
        NSLog(@"%@",newdevice.dsn);
        foundDevice_Ayla=newdevice;
        [self getNewDeviceScanForAPs];
    } failure:^(AylaError *err) {
        NSLog(@"%@",err);
        sleep(2.0f);
        int t=abs((int)[startRunTime timeIntervalSinceNow]);
        if (t<30) {
            [self connectToNewDevice];
        }else{
            [self.delegate PairFailure];
            runThread=nil;
        }
        
    }];
}
//2
-(void)getNewDeviceScanForAPs{
    [AylaSetup getNewDeviceScanForAPs:^(AylaResponse *response, NSMutableArray *apList) {
        
        [self connectNewDeviceToService];
    } failure:^(AylaError *err) {
        NSLog(@"%@",err);
        runThread=nil;
    }];
}
//3
-(void)connectNewDeviceToService{
    [self.delegate SendConfiguration];
    /**
     * Try to connect device to service through user dedicated WLAN AP.
     */
    //get location information from location manager
    NSDictionary *params = nil;
    if(locationManager && locationManager.location.coordinate.latitude!=0)
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  [NSNumber numberWithDouble:locationManager.location.coordinate.latitude], AML_SETUP_LOCATION_LATITUDE,
                  [NSNumber numberWithDouble:locationManager.location.coordinate.longitude], AML_SETUP_LOCATION_LONGTITUDE,
                  nil];
    NSLog(@"Params: %@", params);
    [AylaSetup connectNewDeviceToService:ssid password:password optionalParams:params success:^(AylaResponse *resp) {
        /**
         * Confirm whether device has successfully connected to service.
         */
        [AylaSetup confirmNewDeviceToServiceConnection:^(AylaResponse *response, NSDictionary *result) {
            NSString * success = [result valueForKeyPath:@"success"];
            NSLog(@"%@",success );
            if([success isEqualToString:@"success"]){
                // success then then try to register
                newDevice = [result objectForKey: @"device"];
                // wifi setup completed, try to register
                [self registerStar];
            }
        } failure:^(AylaError *err) {
            NSLog(@"%@",err);
            runThread=nil;
        }];
    } failure:^(AylaError *err) {
        NSLog(@"%@",err);
        runThread=nil;
    }];
}
//4
-(void)registerStar{
    [self.delegate ActivateDevice];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        AylaDevice *dev = [AylaSetup load];
        [self doRegistration:dev];
        
    });
}
//5
-(void)doRegistration:(AylaDevice*)dev
{
    double delayInSeconds = 2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

          [self continueRegistration:dev];

    });
}
//6
-(void)continueRegistration:(AylaDevice*)dev
{
    [AylaDevice registerNewDevice:dev success:^(AylaResponse *response, AylaDevice *registeredDevice) {
        NSLog(@"Ayla Device Register Success%@",registeredDevice);
        AylaIO* tmpIo= [[[[OznerManager instance] ioManager] aylaIOManager] createAylaIO:registeredDevice];
        tmpIo.name=registeredDevice.productName;
        [self.delegate PairComplete:tmpIo];
        runThread=nil;
    } failure:^(AylaError *err) {
        NSLog(@"%@",err);
        runThread=nil;
    }];
}
@end
