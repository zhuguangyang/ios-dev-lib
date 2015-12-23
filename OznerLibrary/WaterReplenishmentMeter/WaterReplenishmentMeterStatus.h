//
//  WaterReplenishmentMeterStatus.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/21.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WaterReplenishmentMeterStatus : NSObject

-(instancetype)init;
@property (readonly) BOOL power;
@property (readonly) int battery;
-(void)load:(NSData*)data;
-(void)reset;
@end
