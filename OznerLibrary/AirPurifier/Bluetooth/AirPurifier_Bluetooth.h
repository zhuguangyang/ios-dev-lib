//
//  AirPurifier_Bluetooth.h
//  OznerLibraryDemo
//
//  Created by Zhiyongxu on 15/12/10.
//  Copyright © 2015年 Ozner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../Device/OznerDevice.h"
#import "BluetoothAirPurifierSensor.h"




@interface AirPurifier_Bluetooth : OznerDevice
{
    
}
@property (strong,readonly) BluetoothAirPurifierSensor* sensor;
@end
