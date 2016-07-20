//
//  AylaIOManager.h
//  OznerLibraryDemo
//
//  Created by 赵兵 on 16/7/13.
//  Copyright © 2016年 Ozner. All rights reserved.
//

#import "IOManager.h"
#import "AylaIO.h"
@interface AylaIOManager : IOManager
{
    //MQTTProxy* proxy;
    NSMutableDictionary* listenDeviceList;
}
-(void) Start:(NSString*) user Token:(NSString*)Token;
-(AylaIO*) createAylaIO:(AylaDevice*)device;
-(void) removeDevice:(NSString*) identifier;
@end
