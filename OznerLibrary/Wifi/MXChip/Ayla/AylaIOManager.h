//
//  AylaIOManager.h
//  OznerLibraryDemo
//
//  Created by 赵兵 on 16/7/13.
//  Copyright © 2016年 Ozner. All rights reserved.
//

#import "IOManager.h"

@interface AylaIOManager : IOManager
{
    //MQTTProxy* proxy;
    NSMutableDictionary* listenDeviceList;
}
@end
