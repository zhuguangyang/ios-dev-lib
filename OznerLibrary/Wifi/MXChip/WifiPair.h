//
//  MXChipPair.h
//  MxChip
//
//  Created by Zhiyongxu on 15/11/26.
//  Copyright © 2015年 Zhiyongxu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpServer_Xu.h"
//#import "MyHTTPConnection.h"
#import "Pair/ConfigurationDevice.h"
#import "../MXChip/MXChipIO.h"
#import "AylaIO.h"
#import <AylaNetworks.h>
#import <CoreLocation/CoreLocation.h>

@class AylaNetworks;

@protocol WifiPairDelegate <NSObject>

///*!
// @function 开始查找Ayla设备
// */
//-(void)StartPairAyla;
/*!
 @function 开始配对
 */
-(void)StartPair;

/*!
 @function 开始发送Wifi信息
 */
-(void)SendConfiguration;

/*!
 @function 等待设备连接
 */
-(void)WaitConnectWifi;

/*!
 @function 等待设备激活
 */
-(void)ActivateDevice;

//配网完成
-(void)PairComplete:(BaseDeviceIO*)io;

//配网失败
-(void)PairFailure;

@end

@interface WifiPair : NSObject<onFTCfinishedDelegate,NSNetServiceBrowserDelegate,NSNetServiceDelegate,CLLocationManagerDelegate>
{
    NSThread* runThread;
    ConfigurationDevice* device;
    NSString* ssid;
    NSString* password;
    NSMutableArray* services;
    dispatch_semaphore_t semaphore;
    NSNetServiceBrowser* serviceBrowser;
    
    CLLocationManager *locationManager;
    AylaDevice* newDevice;
    int runPairCount;
    NSDate* startRunTime;
}
@property (nonatomic, weak) id<WifiPairDelegate> delegate;

/*!
 @function getWifiSSID
 @discussion 获取当前连接Wifi的SSID
 @result 返回null说明当前没有连接wifi
 */
+(NSString*)getWifiSSID;

-(void) start:(NSString*)ssid Password:(NSString*)password;
-(AylaIO*) createAylaIO:(AylaDevice*)device;
-(BOOL)isRuning;
-(void)cancel;


@end
