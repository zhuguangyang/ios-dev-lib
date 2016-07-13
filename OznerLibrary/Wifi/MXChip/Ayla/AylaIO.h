//
//  AylaIO.h
//  OznerLibraryDemo
//
//  Created by 赵兵 on 16/7/13.
//  Copyright © 2016年 Ozner. All rights reserved.
//

#import "BaseDeviceIO.h"
#import <Foundation/Foundation.h>

//#import "AylaIO.h"
#import <AylaNetworks.h>
//@class AylaIO;


//@protocol AylaIOStatusDelegate <NSObject>
//@required
//-(void)IOClosed:(AylaIO*)io;
//@end
@interface AylaIO : BaseDeviceIO
{
    NSThread* runThread;
    
    enum ConnectStatus connectStatus;
    NSString* address;
    NSMutableDictionary* properties;
    
}

@property (weak,nonatomic) AylaDevice* ayladevice;
//-(void)setSecureCode:(NSString*)secureCode;
-(instancetype)init:(AylaDevice*)device;
//-(BOOL)runJob:(nonnull SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait;
-(NSString*)getAddress;
-(void)updateProperty;
-(NSString*) getProperty:(NSString*) name;
@end
