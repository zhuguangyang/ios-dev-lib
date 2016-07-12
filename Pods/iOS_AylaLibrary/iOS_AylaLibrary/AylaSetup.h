//
//  AylaSetup.h
//  Ayla Mobile Library
//
//  Created by Yipei Wang 1/17/13.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

typedef enum {
    AylaSetupSecurityTypeNone = 0,
    AylaSetupSecurityTypeToken = 1,
    AylaSetupSecurityTypeRSA = 2
} AylaSetupSecurityType;

#define AML_SETUP_LOCATION_LONGTITUDE @"longtitude"
#define AML_SETUP_LOCATION_LATITUDE @"latitude"
#define AML_SETUP_DEFAULT_NEW_DEVICE_LAN_IP @"192.168.0.1"
#define AML_SETUP_DEFAULT_NEW_DEVICE_LAN_IP_PREFIX @"192.168."

@class AylaModule;
@class AylaWiFiStatus;
@interface AylaSetup : NSObject 

+ (int) lastMethodCompleted;
+ (NSString *) connectedMode;

+ (NSString *) lanIp;
+ (void) setLanIp:(NSString *)lanIp;

+ (int) newDeviceToServiceConnectionRetries;
+ (void) setNewDeviceToServiceConnectionRetries:(int)newDeviceToServiceConnectionRetries;

+ (int) newDeviceToServiceNoInternetConnectionRetries;
+ (void) setNewDeviceToServiceNoInternetConnectionRetries:(int)_newDeviceToServiceNoInternetConnectionRetries;


//------------------------------------ Begin Setup Task calls ------------------------------------

/**
 * This static method wil return YES if currenct iOS device is connected to a potential new device through Wi-Fi.
 * @discussion In lastest iOS 9 release, Captive Network is deprecated and network interface apis are no longer functional. This change directly impacts our Wi-Fi setup flow: library can't use SSID to check if current iOS device has connected to a AP-Mode new device. Before Hotspot Helper support could be added in library (Also Hotsport Helper requires application developers to request avialability of this feature from Apple.), this api is introduced in library to help applications determine if it has connected to a potential device. Currently library is only using LAN ip to determine device reachability in iOS 9 or above, which has a high probability to give a wrong result. Hence, even if this api returns YES, applications still need to call +connectToNewDevice:failure: to confirm new device availablity.
 *  @note When building with SDK iOS 9 or above, this api will return YES or No based on LAN ip of current iOS device. With older SDKs, this api will return YES or NO based on the name of current connected SSID (To have this work correctly, application must pass in SSID regExp when setting up Ayla library).
 */
+ (BOOL) isConnectedToPotentialNewDevice;

/**
 * This compound static method creates an HTTP connection to the selected new device selected and returns detailed information about it.
 * @param successBlock would be called with a connected module when request is succeeded.
 * @param failureBlock would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (void) connectToNewDevice:
                    /*success:*/(void (^)(AylaResponse *response, AylaModule *newDevice))successBlock
                    failure:(void (^)(AylaError *err))failureBlock;

/**
 * This compound static method returns an array of WLAN APs via a remote device WiFi scan.
 * @param successBlock would be called with a mutable array of discovered APs when request is succeeded.
 * @param failureBlock would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (void) getNewDeviceScanForAPs:
                        /*success:*/(void (^)(AylaResponse *response, NSMutableArray *apList))successBlock
                        failure:(void (^)(AylaError *err))failureBlock;

/**
 * This compound static method directs the selected new device to connect to the Ayla Device Service via the customer selected WLAN AP.
 * @note Param isHidden is deprecated since module is responsible for detecting whether input Wi-Fi network is hidden.
 * @param ssid is ssid of user selected AP
 * @param password is the associated password with selected AP. If the WLAN is an open, unsecured network, then the value of password should be set to “” (empty string).
 * @param successBlock would be called when the connection command is successfully received by device.
 * @param failureBlock would be called with an AylaError object when request is failed.
 * @warning Note that it can take tens of seconds for the new device to connect to the Device Service after this method has successfully executed and returned.
            Please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (void) connectNewDeviceToService:(NSString *)ssid
                          password:(NSString *)password
                    optionalParams:(NSDictionary *)callParams
                           success:(void (^)(AylaResponse *))successBlock
                           failure:(void (^)(AylaError *))failureBlock;

+ (void) connectNewDeviceToService:(NSString *)ssid
                          password:(NSString *)password
                          isHidden:(Boolean)isHidden
                           success:(void (^)(AylaResponse *response))successBlock
                           failure:(void (^)(AylaError *err))failureBlock DEPRECATED_ATTRIBUTE;

+ (void) connectNewDeviceToService:(NSString *)ssid
                          password:(NSString *)password
                    optionalParams:(NSDictionary *)callParams
                          isHidden:(Boolean)isHidden
                           success:(void (^)(AylaResponse *))successBlock
                           failure:(void (^)(AylaError *))failureBlock DEPRECATED_ATTRIBUTE;

/**
 * This compound static method confirms that the new device has successfully connected to the Ayla Device Service. It does this by repeatedly checking with the Ayla Device Service and can take many tens of seconds to complete. By monitoring newDeviceToServiceConnectionRetries a progress indicator can be provided for customer feedback and assurance while this method completes.
 * @param successBlock would be called when device has successfully connected to service.
 * @param failureBlock would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (void) confirmNewDeviceToServiceConnection:
                            /*success:*/(void (^)(AylaResponse *response, NSDictionary *result))successBlock
                            failure:(void (^)(AylaError *err))failureBlock;

/**
 * this method returns an array of past connection attempts from the new device. These are then used to determine and correct the issue. Method only works when iOS device is connected to module.
 * @param successBlock would be called with an object of AylaWifiStatus when request is succeeded.Please see AylaWifiStatus class for details.
 * @param failureBlock would be called with an AylaError object when request is failed.
 * @warning please check iAyla Mobile Library document to find out how to handle returned AylaError object.
 */
+ (void) getNewDeviceWiFiStatus:
                        /*success:*/(void (^)(AylaResponse *response, AylaWiFiStatus *wifiStatus))successBlock
                        failure:(void (^)(AylaError *err))failureBlock;
//-------------------------------------------------------------------------------------------------
//-------------------------------Exit Setup --------------------------------------------------
/**
 * If the Setup Task is abandon before successful completion, the application should call exit(). This method attempts to remove the host-to-device connection & tries to reestablish the customer’s original WiFi connection. This is a best effort attempt to leave the host environment in its original state. There is no need to call exit() if setup completes successfully.
 */
+ (void) exit;
//--------------------------------------------------------------------------------------------

/**
 * If setup completes successfully, this new device would be buffered by library. This method is used to load that stored device. Returned AylaDevice object can only be used to do registration, please check method registerNewDevice in AylaDevice class.
 */
+ (AylaDevice *) load;

/**
 * Remove any new device buffered by library. 
 */
+ (void) clear;

@end
