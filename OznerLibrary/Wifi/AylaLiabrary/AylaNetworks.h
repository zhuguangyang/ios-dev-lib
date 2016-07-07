//
//  AylaNetworks.h
//  Ayla Mobile Library
//
//  Top level import file
//
//  Created by Daniel Myers on 6/20/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <Foundation/NSJSONSerialization.h>
#import <AFNetworking/AFNetworking.h>

#ifndef _AYLA_NETWORKS_H_
#define _AYLA_NETWORKS_H_

#import "AylaDevice.h"
#import "AylaDeviceGateway.h"
#import "AylaDeviceNode.h"
#import "AylaSystemUtils.h"
#import "AylaUser.h"
#import "AylaTrigger.h"
#import "AylaSetup.h"
#import "AylaModule.h"
#import "AylaModuleScanResults.h"
#import "AylaWiFiStatus.h"
#import "AylaWiFiConnectHistory.h"
#import "AylaReachability.h"
#import "AylaLanMode.h"
#import "AylaSchedule.h"
#import "AylaScheduleAction.h"
#import "AylaResponse.h"
#import "AylaError.h"
#import "AylaSecurity.h"
#import "AylaCache.h"
#import "AylaTimeZone.h"
#import "AylaLogService.h"
#import "AylaDatum.h"
#import "AylaDeviceNotification.h"
#import "AylaAppNotification.h"
#import "AylaShare.h"
#import "AylaGrant.h"
#import "AylaContact.h"
#import "AylaConnectionOperation.h"
#import "AylaLogManager.h"
#import "AylaLocation.h"
#import "AylaBatchRequest.h"
#import "AylaBatchResponse.h"
#define _TARGET_IOS_

@interface AylaNetworks : NSObject
/**
 * Init Ayla Mobile Library, MUST be called before any other Ayla API calls.
 * @param params accepts following attributes:
 *      AML_APP_ID : Your app id provided by Ayla.
 *      AML_DEVEL_SSID_REG_EXP : Regular expression of devces' ssid.
 *                               Will be used during WiFi Setup.
 * @warning For Apps which have been using LoadSavedSettings as very first call,
 *          please SWITCH to use this one.
 */
+ (BOOL) initWithParams:(NSDictionary *)params;
@end

// ACCEPTABLE PARAMS FOR AylaNetworks.initWithParams
#define AML_APP_ID              @"appId"
#define AML_DEVICE_SSID_REG_EXP @"devSsidRegExp"

// GLOBALS
extern NSString *gblAuthToken;     //Global Authentication Token
extern NSString *deviceSsidRegex;  //Device Ssid Regular Expression

// CONSTANTS
#define amlVersion @"4.4.00"

#define SUCCESS 0
#define FAIL    1

#define AML_APP_SECRET           @"appSecret"

// SERVICE TYPES
#define AML_DEVICE_SERVICE      0
#define AML_FIELD_SERVICE       1
#define AML_DEVELOPMENT_SERVICE 2
#define AML_STAGING_SERVICE     3
#define AML_DEMO_SERVICE        4

// SETTINGS
#define DEFAULT_SERVICE           AML_DEVICE_SERVICE
#define DEFAULT_REFRESH_INTERVAL  5
#define DEFAULT_WIFI_TIMEOUT     10
#define DEFAULT_MAX_COUNT       100
#define DEFAULT_APP_ID            @"Not-Assigned"
#define DEFAULT_ACCESS_TOKEN_REFRESH_THRRESHOLD 21600 //6 hours by default
#define DEFAULT_NOTIFY_OUTSTANDING_ENABLED YES

// DEFAULT DEVICE SSID REGULAR EXPRESSION
#define DEFAULT_DEVICE_REG_EXP @"((^Ayla)|(^Sina-Mobile)|(^T-Stat))-[0-9A-Fa-f]{12}"

// DEFAULT SLOW CONNECTION
#define DEFAULT_SLOW_CONNECTION NO

// REACHABILITY
#define AML_SERVICE_REACHABILITY_TIMEOUT 5         // Seconds to wait for service Discovery
#define AML_DEVICE_REACHABILITY_TIMEOUT 2.0

typedef enum {
    AML_REACHABILITY_REACHABLE           =  0,
    AML_REACHABILITY_UNREACHABLE         = -1,
    AML_REACHABILITY_LAN_MODE_DISABLED   = -2,
    AML_REACHABILITY_UNKNOWN             = -3
} AML_REACHABILITY;


// WIFI SETUP
#define DEFAULT_SECURE_SETUP YES
#define DEFAULT_SETUP_WIFI_HTTP_TIMEOUT 6
#define DEFAULT_SETUP_TOKEN_LEN 8
#define DEFAULT_NEW_DEVICE_TO_SERVICE_CONNECTION_RETRIES 7
#define DEFAULT_NEW_DEVICE_TO_SERVICE_NO_INTERNET_CONNECTION_RETRIES 9
#define DEFAULT_SETUP_STATUS_POLLING_INTERVAL 3

// LAN MODE VALUES
#define DEFAULT_LAN_MODE 1 //DISABLED, must ENABLE for LAN Mode operation

#define AML_LAN_MODE_TIMEOUT_SAFETY 3           // Seconds subtracted from secure session keep-alive timer value
#define AML_LAN_MODE_MDNS_DISCOVERY_TIMEOUT 1.5 // Seconds to wait for mDNS discovery
#define DEFAULT_LOCAL_WIFI_HTTP_TIMEOUT 4

#define AML_LANMODE_IGNORE_BASETYPES @"float file stream"
#define DEFAULT_SERVER_PORT_NUMBER 10275

enum AML_LAN_MODE_STATE {ENABLED, DISABLED, STARTING, RUNNING, STOPPING, STOPPED, FAILED};

#define AML_NOTIFY_TYPE_SESSION     @"session"
#define AML_NOTIFY_TYPE_PROPERTY    @"property"
#define AML_NOTIFY_TYPE_NODE        @"node"

// LOGGING SERVICE
#define DEFAULT_LOGFILE_NAME @"aml_log"
#define DEFAULT_LOGGING_ENABLED NO

#define AML_DEFAULT_SUPPORT_MAIL_ADDRESS @"mobile-libraries@aylanetworks.com"

// TEMPLATE ATTRIBUTES
#define AML_EMAIL_TEMPLATE_ID      @"email_template_id"
#define AML_EMAIL_SUBJECT          @"email_subject"
#define AML_EMAIL_BODY_HTML        @"email_body"

// SCHEDULE
#define DEFAULT_MAX_SCHEDULES 5
#define DEFAULT_MAX_SCHEDULE_ACTIONS 10

// URLs
#define GBL_USER_SERVICE_URL                @"https://user.aylanetworks.com/"               // url to the user service
#define GBL_USER_DEVELOP_URL                @"https://user.aylanetworks.com/"               // url to the development user service
#define GBL_USER_STAGING_URL                @"https://staging-user.ayladev.com/"       // url to the staged user service
#define GBL_USER_DEMO_URL                   @"https://ayla-user.aylanetworks.com/"          // url to the demo user service
#define GBL_DEVICE_SERVICE_URL              @"https://ads-field.aylanetworks.com/apiv1/"    // url to the device service
#define GBL_DEVICE_DEVELOP_URL              @"https://ads-dev.aylanetworks.com/apiv1/"      // url to the development device service
#define GBL_DEVICE_STAGING_URL              @"https://staging-ads.ayladev.com/apiv1/"  // url to the staging device service
#define GBL_DEVICE_DEMO_URL                 @"https://ayla-ads.aylanetworks.com/apiv1/"     // url to the demo device service
#define GBL_DEVICE_SUFFIX_URL               @"-device.aylanetworks.com/apiv1/"              // url to compose to-device-service url
#define GBL_NON_SECURE_DEVICE_SERVICE_URL   @"http://ads-field.aylanetworks.com/apiv1/"     // url to the device service
#define GBL_NON_SECURE_DEVICE_DEVELOP_URL   @"http://ads-dev.aylanetworks.com/apiv1/"       // url to the development service
#define GBL_NON_SECURE_DEVICE_STAGING_URL   @"http://staging-ads.ayladev.com/apiv1/"   // url to the staging device service
#define GBL_NON_SECURE_DEVICE_DEMO_URL      @"http://ayla-ads.aylanetworks.com/apiv1/"      // url to the demo device service
#define GBL_NON_SECURE_DEVICE_SUFFIX_URL    @"-device.aylanetworks.com/apiv1/"              // url to compose to-device-service url
#define GBL_APPTRIGGER_SERVICE_URL          @"https://ads-field.aylanetworks.com/apiv1/"    // url to the device service
#define GBL_APPTRIGGER_DEVELOP_URL          @"https://ads-dev.aylanetworks.com/apiv1/"      // url to the development device service
#define GBL_APPTRIGGER_STAGING_URL          @"https://staging-ads.ayladev.com/apiv1/"  // url to the staging device service
#define GBL_APPTRIGGER_DEMO_URL             @"https://ayla-ads.aylanetworks.com/apiv1/"     // url to the demo device service
#define GBL_APPTRIGGER_SUFFIX_URL           @"-device.aylanetworks.com/apiv1/"              // url to compose to-device-service url
#define GBL_SIGNUP_SERVICE_URL              @"https://developer.aylanetworks.com/users/sign_up/" // url to the production sign-up
#define GBL_SIGNUP_DEVELOP_URL              @"https://developer.aylanetworks.com/users/sign_up/" // url to the development sign-up
#define GBL_SIGNUP_STAGING_URL              @"https://staging-developer.ayladev.com/users/sign_up/" // url to the staging service
#define GBL_SIGNUP_DEMO_URL                 @"https://ayla-developer.aylanetworks.com/users/sign_up/" // url to the demo service
#define GBL_LOG_SERVICE_URL                 @"https://log.aylanetworks.com/api/v1/"         // url to the production log service
#define GBL_LOG_DEVELOP_URL                 @"https://log.aylanetworks.com/api/v1/"         // url to the development log service
#define GBL_LOG_STAGING_URL                 @"https://staging-log.ayladev.com/api/v1/" // url to the staging log service
#define GBL_LOG_DEMO_URL                    @"https://log.aylanetworks.com/api/v1/"         // url to the demo log service

#define GBL_MODULE_DEFAULT_WIFI_IPADDR      @"http://192.168.0.1/"

#define GBL_DSN_PREFIX  @"Ayla-AC" // Early SSID prefix
#define GBL_MAC_PREFIX  @"Ayla-60" // Current SSID prefix
#define GBL_FILE_URL    @"./ayla"  // Local test file data

#define GBL_DEVICES_DIRECTORY       @"devices"
#define GBL_PROPERTIES_DIRECTORY    @"properties"
#define GBL_TRIGGERS_DIRECTORY      @"triggers"
#define GBL_AJAX_TIMEOUT            @"6000"     // 6 seconds

// DEVICE CONNECTED MODES
#define AML_CONNECTION_UNKNOWN @"Unknown"
#define AML_IN_AP_MODE @"AP Mode"
#define AML_CONNECTED_TO_HOST @"Host"
#define AML_CONNECTED_TO_SERVICE @"Service"

// WIFI SECURITY TYPES
#define AML_WPA2        @"WPA2"
#define AML_WPA         @"WPA"
#define AML_WEP         @"WEP"
#define AML_OPEN        @"OPEN"
#define AML_WPA_EAP     @"WPA_EAP"  // EAP Enterprise fields
#define AML_IEEE8021X   @"IEEE8021X"
#define AML_EAP_METHOD  = [ @"PEAP", @"TLS", @"TTLS" ]

// REGISTRATION TYPES
#define AML_REGISTRATION_TYPE_SAME_LAN      @"Same-LAN"
#define AML_REGISTRATION_TYPE_BUTTON_PUSH   @"Button-Push"
#define AML_REGISTRATION_TYPE_AP_MODE       @"AP-Mode"
#define AML_REGISTRATION_TYPE_DISPLAY       @"Display"
#define AML_REGISTRATION_TYPE_DSN           @"Dsn"
#define AML_REGISTRATION_TYPE_NODE          @"Node"
#define AML_REGISTRATION_TYPE_NONE          @"None"

// Error codes for compound method registerNewDevice
#define AML_GET_REGISTRATION_CANDIDATE 1500
#define AML_GET_MODULE_REGISTRATION_TOKEN 1501
#define AML_REGISTER_DEVICE 1502

// Error codes for device setup
#define AML_TASK_ORDER_ERROR 1009
#define AML_NO_DEVICE_CONNECTED 1010
#define AML_SETUP_CONNECTION_ERROR 1011
#define AML_SETUP_CONFIRMATION_ERROR 1012
#define AML_SETUP_DEVICE_ERROR 1013

// Connect Host To New Device
#define AML_GET_NEW_DEVICE_DETAIL 1513
#define AML_SET_NEW_DEVICE_TIME 1514

// Get New Device Scan for APs
#define AML_SET_NEW_DEVICE_SCAN_FOR_APS 1516
#define AML_GET_NEW_DEVICE_SCAN_FOR_APS 1517

// Connect New Device to Service
#define AML_CONNECT_NEW_DEVICE_TO_SERVICE 1520

// Confirm New Device To Service Connection
#define AML_DISCONNECT_NEW_DEVICE 1530
#define AML_GET_NEW_DEVICE_CONNECTED 1531

// Get New Device WiFi Status
#define AML_GET_NEW_DEVICE_WIFI_STATUS 1532

// WiFi Setup Task States
#define AML_SETUP_TASK_NONE 0
#define AML_SETUP_TASK_INIT 1
#define AML_SETUP_TASK_CONNECT_TO_NEW_DEVICE 3
#define AML_SETUP_TASK_GET_DEVICE_SCAN_FOR_APS 4
#define AML_SETUP_TASK_CONNECT_NEW_DEVICE_TO_SERVICE 5
#define AML_SETUP_TASK_CONFIRM_NEW_DEVICE_TO_SERVICE_CONNECTION 6
#define AML_SETUP_TASK_GET_NEW_DEVICE_WIFI_STATUS 7
#define AML_SETUP_TASK_EXIT 8

// Get BLOBS compound method
#define AML_GET_BLOBS_GET 1601
#define AML_GET_BLOBS_GET_LOCATION 1602
#define AML_GET_BLOBS_SAVE_TO_FILE 1603
#define AML_BLOBS_MARK_FETCHED 1604
#define AML_BLOBS_MARK_FINISH 1605

//#define wifiErrorMsg = [ \\
                               "No Error", \\
                               "Resource problem, out of memory or buffers", \\
                               "Connection timed out", \\
                               "Invalid key", \\
                               "SSID not found", \\
                               "Not authenticated via 802.11 or failed to associate with the AP", \\
                               "Incorrect key", \\
                               "Failed to get IP address from DHCP", \\
                               "Failed to get default gateway from DHCP", \\
                               "Failed to get NDS server from DHCP", \\
                               "Disconnected by AP", \\
                               "Signal lost from AP (beacon miss)", \\
                               "Device service host lookup failed", \\
                               "Device service GET was redirected", \\
                               "Device service connection timed out", \\
                               "No empty Wifi profile slots", \\
                               "Security methond used by AP not supported",\\
                               "Network type (e.g. ad-hoc) is not supported", \\
                               "The server responded in an incompatible way. The AP may be a Wi-Fi hotspot", \\
                               "Unknown error." \\
                               ]

#endif