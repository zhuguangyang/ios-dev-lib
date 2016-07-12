//
//  AylaSystemUtils.m
//  Ayla Mobile Library
//
//  Created by Daniel Myers on 6/26/12.
//  Copyright (c) 2015 Ayla Networks. All rights reserved.
//

#import "AylaNetworks.h"
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "AylaSystemUtilsSupport.h"
#import "AylaConnectivityListener.h"
#import "AylaErrorSupport.h"
#import "AylaLogManager.h"
#import "NSObject+AylaNetworks.h"

#define AML_APP_ID_SUFFIX_US @"-id"
#define AML_APP_ID_SUFFIX_CN @"-cn-id"
#define AML_APP_ID_SUFFIX_EU @"-eu-id"

@implementation AylaSystemUtils

static NSNumber *_refreshInterval;
static NSNumber *_wifiTimeout;
static NSNumber *_maxCount;
static NSNumber *_serviceType;
static NSNumber *_serviceLocation;
static NSNumber *_newDeviceToServiceConnectionRetries;
static NSNumber *_slowConnection;
static enum AML_LAN_MODE_STATE _lanModeState = DEFAULT_LAN_MODE;
static NSNumber *_serverPortNumber;
static NSNumber *_loggingLevel = nil;
static NSNumber *_loggingOutputs = nil;
static NSString *_version = nil;
//static NSString *_serverPath = DEFAULT_SERVER_BASE_PATH;
//static NSString *_logfileName = DEFAULT_LOGFILE_NAME;
static NSNumber *_loggingEnabled;
static NSString *_settingsFilePath = nil;
static NSString *_usersArchiverFilePath = nil;
static NSString *_devicesArchiverFilePath = nil;
static NSString *_deviceArchiverFilePath = nil;
static NSNumber *_serviceReachableTimeout;
static NSString *_appId = nil;
static NSNumber *_notifyOutstandingEnabled = nil;

static AylaConnectivityListener *_monitor = nil;

//----------------------------- local settings -----------------------------
+ (NSNumber *) refreshInterval
{
  return _refreshInterval;
}

+ (void) refreshInterval:(NSNumber *)refreshInterval
{
  _refreshInterval = refreshInterval;
}

+ (NSNumber *) wifiTimeout
{
  return _wifiTimeout;
}

+ (void) wifiTimeout:wifiTimeout
{
  _wifiTimeout = wifiTimeout;
}

+ (NSNumber *) maxCount
{
  return _maxCount;
}

+ (void) maxCount:(NSNumber *)maxCount
{
  _maxCount = maxCount;
}

+ (NSNumber *) serviceType
{
  return _serviceType;
}

+ (AylaServiceLocation) serviceLocation
{
    return [_serviceLocation integerValue];
}

+ (AylaServiceLocation) serviceLocationWithAppId:(NSString *)appId
{
    /*
     * Update service location by parsing app id. US by default.
     */
    if ([[appId nilIfNull] rangeOfString:AML_APP_ID_SUFFIX_CN].location != NSNotFound) {
        _serviceLocation = [NSNumber numberWithInt:AylaServiceLocationCN];
    }
    else if ([[appId nilIfNull] rangeOfString:AML_APP_ID_SUFFIX_EU].location != NSNotFound) {
        _serviceLocation = [NSNumber numberWithInt:AylaServiceLocationEU];
    }
    else {
        _serviceLocation = [NSNumber numberWithInt:AylaServiceLocationUS];
    }
    return  [AylaSystemUtils serviceLocation];
}

+ (AylaServiceLocation) serviceLocationWithCountryCode:(NSString *)countryCode
{
    /*
     * Update service location by country code. US by default.
     */
    NSString * const USCountryCode = @"US";
    NSString * const CNCountryCode = @"CN";
    NSArray * const EUCountryCodes = @[ @"AL", @"AD", @"AT", @"BA", @"BE", @"BG", @"BY",
                                        @"CH", @"CY", @"CZ", @"DE", @"DK", @"EE", @"ES",
                                        @"FI", @"FO", @"FR", @"GB", @"GI", @"GR", @"HR",
                                        @"HU", @"IE", @"IM", @"IS", @"IT", @"LI", @"LT",
                                        @"LV", @"LU", @"MC", @"MD", @"ME", @"MK", @"MT",
                                        @"NL", @"NO", @"PL", @"PT", @"RO", @"RS", @"RU",
                                        @"SE", @"SI", @"SM", @"SK", @"UA", @"VA" ];
    
    if ([[countryCode nilIfNull] isEqualToString:USCountryCode]) {
        _serviceLocation = [NSNumber numberWithInt:AylaServiceLocationUS];
    }
    else if ([[countryCode nilIfNull] isEqualToString:CNCountryCode]) {
        _serviceLocation = [NSNumber numberWithInt:AylaServiceLocationCN];
    }
    else if ([EUCountryCodes containsObject:[countryCode nilIfNull]]) {
        _serviceLocation = [NSNumber numberWithInt:AylaServiceLocationEU];
    }
    else {
        // Use AylaServiceLocationUS as default service location.
        _serviceLocation = [NSNumber numberWithInt:AylaServiceLocationUS];
    }
    
    return  [AylaSystemUtils serviceLocation];
}

+ (enum AML_LAN_MODE_STATE) lanModeState
{
  return _lanModeState;
}

+ (void) lanModeState: (enum AML_LAN_MODE_STATE) lanModeState
{
  _lanModeState = lanModeState;
}

+ (void) serverPortNumber: (int)serverPortNumber
{
    _serverPortNumber = [NSNumber numberWithInt:serverPortNumber];
}

+ (NSNumber *) serverPortNumber
{
    return _serverPortNumber;
}

+ (AylaSystemLoggingLevel)loggingLevel
{
    return _loggingLevel.intValue;
}

+ (void)loggingLevel:(AylaSystemLoggingLevel)level
{
    _loggingLevel = [NSNumber numberWithInt:level];
}

+ (AylaSystemLoggingOutput)loggingOutputs
{
    return _loggingOutputs.intValue;
}

+ (void)loggingOutputs:(AylaSystemLoggingOutput)outputs
{
    _loggingOutputs = [NSNumber numberWithInt:outputs];
}

+ (void) serviceType:(NSNumber *)serviceType
{
  _serviceType = serviceType;
}

+ (NSString *) settingsFilePath
{
  return _settingsFilePath;
}
+ (NSString *) usersArchiversFilePath
{
  return _usersArchiverFilePath;
}

+ (NSString *) deviceArchiversFilePath
{
    return _deviceArchiverFilePath;
}

+ (NSString *) devicesArchiversFilePath
{
    return _devicesArchiverFilePath;
}

+ (NSNumber *) serviceReachableTimeout
{
    return _serviceReachableTimeout;
}
+ (void) serviceReachableTimeout:(NSNumber *) serviceReachableTimeout
{
    _serviceReachableTimeout = serviceReachableTimeout;
}

+ (NSNumber *) notifyOutstandingEnabled;
{
    return _notifyOutstandingEnabled;
}

+ (void) setNotifyOutstandingEnabled:(NSNumber *)setEnabled
{
    if(!setEnabled) return;
    _notifyOutstandingEnabled = setEnabled;
}

+ (NSNumber *) newDeviceToServiceConnectionRetries
{
    return _newDeviceToServiceConnectionRetries;
}
+ (void) newDeviceToServiceConnectionRetries: (NSNumber *)newDeviceToServiceConnectionRetries
{
    _newDeviceToServiceConnectionRetries = newDeviceToServiceConnectionRetries;
}

+ (NSNumber *) slowConnection
{
    return _slowConnection;
}
+ (void) slowConnection: (NSNumber *)slowConnection
{
    _slowConnection = slowConnection;
}

+ (NSString *)deviceSsidRegex
{
    return deviceSsidRegex;
}

+ (void)setDeviceSsidRegex:(NSString *)_deviceSsidRegex
{
    deviceSsidRegex = _deviceSsidRegex;
}

+ (NSString *) version
{
    return _version;
}
+ (void) version:(NSString *)version
{
    _version = version;
}

+ (NSString *) appId
{
    return _appId;
}
+ (void) appId:(NSString *)appId
{
    _appId = appId;
}

+ (NSString *) getLogFilePath
{
    NSArray *arrayPaths =
    NSSearchPathForDirectoriesInDomains(
                                        NSDocumentDirectory,
                                        NSUserDomainMask,
                                        YES);
    NSString *path = [arrayPaths objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *absolutePath = [path stringByAppendingString: @"/Ayla/aml_log.txt"];
    BOOL isDir;
    return  [fm fileExistsAtPath:absolutePath isDirectory:&isDir]?absolutePath:nil ;
}

+ (NSString *) getSupportMailAddress
{
    return AML_DEFAULT_SUPPORT_MAIL_ADDRESS;
}

+ (NSString *) getLogMailSubjectWithAppId:(NSString *)appId
{
    return [NSString stringWithFormat:@"AppId:%@,LibVer:%@,OS:%@", appId, amlVersion, [[UIDevice currentDevice] systemVersion]];
}

//----------------------------- settings persistence -----------------------------
+ (void)doInitialize
{
    _loggingLevel = [NSNumber numberWithInt:AylaSystemLoggingError];
    // Get the documents directory path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [NSString stringWithFormat:@"%@/Ayla", [paths objectAtIndex:0]];
    _settingsFilePath = [documentsDirectory stringByAppendingPathComponent:@"AylaSettings.plist"];
    _usersArchiverFilePath = [documentsDirectory stringByAppendingPathComponent:@"AylaUserArchiver.arch"];
    _devicesArchiverFilePath = [documentsDirectory stringByAppendingPathComponent:@"AylaDevicesArchiver.arch"];
    _deviceArchiverFilePath = [documentsDirectory stringByAppendingPathComponent:@""];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    if(![manager fileExistsAtPath:documentsDirectory]) {
        NSError *error;
        [manager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if(error){
            saveToLog(@"%@, %@, %@:%@, %@", @"E", @"SystemUtils", @"Failed To Create Dir", error, @"doInitialize");
        }
    }

    saveToLog(@"severity, component, varName:varValue, description");
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"Settings", @"_settingsFilePath", _settingsFilePath, @"Success initializing class AylaSettings");
    saveToLog(@"%@, %@, %@:%@, %@", @"I", @"SystemUtils", @"AML_Version", amlVersion, @"logging");
    saveToLog(@"%@, %@, %@:%@, %@ ", @"I", @"SystemUtils", @"iOS_Version", [[UIDevice currentDevice] systemVersion], @"logging");
    _freeMemory();
    freeStorage();
}


+ (void)initSettings
{
    _serverPortNumber = [NSNumber numberWithInt:DEFAULT_SERVER_PORT_NUMBER];
    _loggingEnabled = [NSNumber numberWithInt: DEFAULT_LOGGING_ENABLED];
    _refreshInterval = [NSNumber numberWithInt:DEFAULT_REFRESH_INTERVAL];
    _wifiTimeout = [NSNumber numberWithInt:DEFAULT_WIFI_TIMEOUT];
    _maxCount = [NSNumber numberWithInt:DEFAULT_MAX_COUNT];
    _serviceType = [NSNumber numberWithInt:DEFAULT_SERVICE];
    _newDeviceToServiceConnectionRetries = [NSNumber numberWithInt:DEFAULT_NEW_DEVICE_TO_SERVICE_CONNECTION_RETRIES];
    _slowConnection = [NSNumber numberWithBool:DEFAULT_SLOW_CONNECTION];
    _serviceReachableTimeout = [NSNumber numberWithInt: AML_SERVICE_REACHABILITY_TIMEOUT];
    deviceSsidRegex = DEFAULT_DEVICE_REG_EXP;
    _loggingLevel = [NSNumber numberWithInt: AylaSystemLoggingError];
    _version = amlVersion;
    _appId = DEFAULT_APP_ID;
    _serviceLocation = [NSNumber numberWithInt:AylaServiceLocationUS];
    _loggingOutputs = [NSNumber numberWithInt:AylaSystemLoggingOutputConsole|AylaSystemLoggingOutputLogFile];
    _notifyOutstandingEnabled = [NSNumber numberWithBool:DEFAULT_NOTIFY_OUTSTANDING_ENABLED];
}

+ (void)initSettingDictionary:(NSMutableDictionary *)settings
{
    [settings setObject:_refreshInterval forKey:@"refreshInterval"];
    [settings setObject:_wifiTimeout forKey:@"wifiTimeout"];
    [settings setObject:_maxCount forKey:@"maxCount"];
    [settings setObject:_serviceType forKey:@"serviceType"];
    [settings setObject:_version forKey:@"version"];
    [settings setObject: deviceSsidRegex forKey:@"deviceSsidRegex"];
    [settings setObject:_slowConnection forKey:@"slowConnection"];
    [settings setObject:_newDeviceToServiceConnectionRetries forKey:@"newDeviceToServiceConnectionRetries"];
    [settings setObject:_serverPortNumber forKey:@"serverPortNumber"];
    [settings setObject:_loggingEnabled forKey:@"loggingEnabled"];
    [settings setObject:_serviceReachableTimeout forKey:@"serviceReachabilityTimeOut"];
    [settings setObject:_loggingLevel forKey:@"loggingLevel"];
    [settings setObject:_appId forKey:@"appId"];
    [settings setObject:_serviceLocation forKey:@"serviceLocation"];
    [settings setObject:_loggingOutputs forKey:@"loggingOutputs"];
    [settings setObject:_notifyOutstandingEnabled?:@(DEFAULT_NOTIFY_OUTSTANDING_ENABLED) forKey:@"notifyOutstandingEnabled"];
}

+ (int)loadSavedSettings
{
  NSNumber *value;
  
  if (_settingsFilePath == nil) {
    [AylaSystemUtils doInitialize];
  }
  NSMutableDictionary *settings = [[NSMutableDictionary alloc]
                                   initWithContentsOfFile:_settingsFilePath];
  if (settings == nil || settings.count == 0) {
    //no file found, create a new setting file.
    return [AylaSystemUtils saveDefaultSettings];
  }
    
  // set initial values
  [self initSettings];
  
  NSString *version = nil;
  version = [settings valueForKey:@"version"];
  if(version == nil){
      version = @"1.0";
  }

  // set the property values
  value = [settings valueForKey:@"refreshInterval"];
  if(value!=nil){
    _refreshInterval = value;
    value = nil;
  }
  value = [settings valueForKey:@"wifiTimeout"];
  if(value!=nil){
    _wifiTimeout = value;
    value = nil;
  }
  value = [settings valueForKey:@"maxCount"];
  if(value!=nil){
    _maxCount = value;
    value = nil;
  }
  value = [settings valueForKey:@"slowConnection"];
  if(value) {
    _slowConnection = value;
    value = nil;
  }
  value = [settings valueForKey:@"newDeviceToServiceConnectionRetries"];
  if(value) {
    _newDeviceToServiceConnectionRetries = value;
    value = nil;
  }
    
  value = [settings valueForKey:@"serviceType"];
  if(value == nil){
      if([version compare:@"2.0"] == NSOrderedAscending){
          // version below 2.0, serviceType is set as a boolean value
          NSNumber *oldValue = [settings valueForKey:@"productionService"];
          if(oldValue == nil)
              _serviceType = [NSNumber numberWithInt: DEFAULT_SERVICE];
          else{
              _serviceType = [NSNumber numberWithInt:[oldValue boolValue]==YES? AML_DEVELOPMENT_SERVICE: AML_STAGING_SERVICE];
          }
      }else{
          _serviceType = [NSNumber numberWithInt: DEFAULT_SERVICE];
      }
  }else {
      _serviceType = value;
  }
  value = nil;
  
  value = [settings valueForKey:@"serviceLocation"];
  if(value) {
    _serviceLocation = value;
    value = nil;
  }
    
  value = [settings valueForKey:@"serverPortNumber"];
  if(value) {
    _serverPortNumber = value;
    value = nil;
  }

  value = [settings valueForKey:@"loggingEnabled"];
  if(value) {
      _loggingEnabled = value;
      value = nil;
  }
  
  value = [settings valueForKey:@"loggingLevel"];
  if(value) {
      _loggingLevel = value;
      value = nil;
  }
  
  value = [settings valueForKey:@"loggingOutputs"];
  if(value) {
      _loggingOutputs = value;
  }
    
  value = [settings valueForKey:@"notifyOutstandingEnabled"];
  if(value) {
      _notifyOutstandingEnabled = value;
  }
  
  value = [settings valueForKey:@"serviceReachabilityTimeOut"];
  if(value) {
    _serviceReachableTimeout = value;
    value = nil;
  }
   
  NSString *id = [settings valueForKey:@"appId"];
  _appId = id? id: DEFAULT_APP_ID;
    
  NSString *exp = [settings valueForKey:@"deviceSsidRegex"];
  if(exp!=nil){
    deviceSsidRegex = exp;
    exp = nil;
  }

  _version = version;
  saveToLog(@"I, Settings, none, Success in loadSavedSettings");
  if(_monitor == nil) {
     _monitor = [AylaConnectivityListener new];
    [_monitor startNotifier];
  }
  return SUCCESS;
}

+ (int)saveDefaultSettings
{
  if (_settingsFilePath == nil) {
    [AylaSystemUtils doInitialize];
  }

  // set to default values
  [AylaSystemUtils initSettings];
    
  // Set pList with default values
  NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile: _settingsFilePath];
  if(!settings) settings = [NSMutableDictionary new];
    [AylaSystemUtils initSettingDictionary:settings];
    
  // Write to nonvolatile memory
  BOOL ret = [settings writeToFile: _settingsFilePath atomically:YES];
  if (ret == YES) {
    saveToLog(@"I, Settings, ret:YES, Success in saveDefaultSettings");
    return SUCCESS;
  } else {
    saveToLog(@"E, Settings, ret:NO, Failed in saveDefaultSettings");
    return FAIL;
  }
}

+ (int)saveCurrentSettings
{
  if (_settingsFilePath == nil) {
    [self doInitialize];
  }
  
  _version = amlVersion;
  NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile: _settingsFilePath];
  if(!settings) settings = [NSMutableDictionary new];
  [AylaSystemUtils initSettingDictionary:settings];
    
  BOOL ret = [settings writeToFile: _settingsFilePath atomically:YES];
  if (ret == YES) {
    saveToLog(@"I, Settings, ret:YES, Success in saveCurrentSettings");
    return SUCCESS;
  } else {
    saveToLog(@"E, Settings, ret:NO, Failed in saveCurrentSettings");
    return FAIL;
  }
}

// ------------------- Support Methods --------------

+ (NSString *)rootDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

// Given an NSError, returns a short error string that we can print, handling 
// some special cases along the way.
//
+ (NSString *)shortErrorFromError:(NSError *)error
{
  NSString *result;
  assert(error != nil);
  result = nil;
/*  
  // Handle DNS errors as a special case.

   NSNumber *      failureNum;
   int             failure;
   const char *    failureStr;
   
   if ( [[error domain] isEqual:(NSString *)kCFErrorDomainCFNetwork] && ([error code] == kCFHostErrorUnknown) ) {
    failureNum = [[error userInfo] objectForKey:(id)kCFGetAddrInfoFailureKey];
      if ( [failureNum isKindOfClass:[NSNumber class]] ) {
        failure = [failureNum intValue];
        if (failure != 0) {
          failureStr = gai_strerror(failure);
          if (failureStr != NULL) {
            result = [NSString stringWithUTF8String:failureStr];
            assert(result != nil);
          }
        }
      }
   }
 // Otherwise try various properties of the error object.
*/
  if(result == nil) {
    result = [error localizedFailureReason];
  }
  if(result == nil) {
    result = [error localizedDescription];
  }
  if(result == nil) {
    result = [error description];
  }
  assert(result != nil);
  return result;
}

+ (NSString *) stringFromJsonObject:(id)object
{
    if(!object) return nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (!jsonData) {
        saveToLog(@"%@, %@, %@:%@, %@", @"E", @"SystemUtils", @"err", error.description, @"stringFromJsonObject");
        return nil;
    } else {
        return  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

+ (NSString *) jsonEscapedStringFromString:(NSString *)string
{
    NSMutableString *mutableString = [string mutableCopy];
    [mutableString replaceOccurrencesOfString:@"\\" withString:@"\\\\"
                                      options:NSCaseInsensitiveSearch
                                        range:NSMakeRange(0, [mutableString length])];
    [mutableString replaceOccurrencesOfString:@"\"" withString:@"\\\""
                                      options:NSCaseInsensitiveSearch
                                        range:NSMakeRange(0, [mutableString length])];
    return [NSString stringWithString:mutableString];
}

+ (NSString *) uriEscapedStringFromString:(NSString *)string
{
    if(!string) return nil;
    NSString * encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                   NULL,
                                                                                   (__bridge CFStringRef)string,
                                                                                   NULL,
                                                                                   CFSTR("~!*'();:@&=+$,/?%#[]{}<>`^\\-_"),
                                                                                   kCFStringEncodingUTF8 ));
    return encodedString;
}

+ (Class)classFromClassName:(NSString *)className
{
    return NSClassFromString(className);
}

//----------------------- System Info -------------------------
void freeMemory(void){
  static unsigned last_resident_size=0;
  static unsigned greatest = 0;
  static unsigned last_greatest = 0;
  
  struct task_basic_info info;
  mach_msg_type_number_t size = sizeof(info);
  kern_return_t kerr = task_info(mach_task_self(),
                                 TASK_BASIC_INFO,
                                 (task_info_t)&info,
                                 &size);
  if( kerr == KERN_SUCCESS ) {
    int diff = (int)info.resident_size - (int)last_resident_size;
    unsigned latest = (unsigned int)info.resident_size;
    if( latest > greatest   )   greatest = latest;  // track greatest mem usage
    int greatest_diff = greatest - last_greatest;
    int latest_greatest_diff = latest - greatest;

    NSLog(@"Mem: %10lu (%10d) : %10d :   greatest: %10u (%d)", info.resident_size, diff, latest_greatest_diff, greatest, greatest_diff  );
  } else {
    NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
  }
  last_resident_size = (unsigned int)info.resident_size;
  last_greatest = greatest;
}

void _freeMemory ()
{
  mach_port_t host_port;
  mach_msg_type_number_t host_size;
  vm_size_t pagesize;
  
  host_port = mach_host_self();
  host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
  host_page_size(host_port, &pagesize);        
  
  vm_statistics_data_t vm_stat;
  
  if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
    NSLog(@"Failed to fetch vm statistics");
  
  /* Stats in bytes */
  natural_t oneK = 1024;
  natural_t mem_used = (vm_stat.active_count +
                        vm_stat.inactive_count +
                        vm_stat.wire_count) * (unsigned)pagesize;
  natural_t mem_free = vm_stat.free_count * (unsigned)pagesize;
  natural_t mem_total = mem_used + mem_free;
  //saveToLog(@"used: %u free: %u total: %u", mem_used, mem_free, mem_total);
  saveToLog(@"%@, %@, UsedMemory:%uKB, FreeMemory:%uKB, TotalMemory:%uKB, %@",  @"I", @"SystemUtils",
            mem_used/oneK, mem_free/oneK, mem_total/oneK, @"logging");
}

uint64_t freeStorage()
{
  uint64_t totalSpace = 0;
  uint64_t totalFreeSpace = 0;
  
  __autoreleasing NSError *error = nil;  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);  
  NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];  
  
  if (dictionary) {  
    NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];  
    NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
    totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
    totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
    //NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    saveToLog(@"%@, %@, TotalInternalStorage:%lluMB, FreeInternalStorage:%lluMB, %@",  @"I", @"SystemUtils", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll) , @"logging");
  } else {  
    NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
  }  
  return totalFreeSpace;
}

+ (NSString *)getIPAddress
{    
  struct ifaddrs *interfaces = NULL;
  struct ifaddrs *temp_addr = NULL;
  NSString *wifiAddress = nil;
  NSString *cellAddress = nil;
  
  // retrieve the current interfaces - returns 0 on success
  if(!getifaddrs(&interfaces)) {
    // Loop through linked list of interfaces
    temp_addr = interfaces;
    while(temp_addr != NULL) {
      sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
      if(sa_type == AF_INET || sa_type == AF_INET6) {
        NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
        NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0     
        
        if(([name isEqualToString:@"en0"] || [name isEqualToString:@"en1"] )&& ![addr isEqualToString:@"0.0.0.0"]) {
          // Interface is the wifi connection on the iPhone
          wifiAddress = addr;    
        } else
          if([name isEqualToString:@"pdp_ip0"]) {
            // Interface is the cell connection on the iPhone
            cellAddress = addr;    
          }
      }
      temp_addr = temp_addr->ifa_next;
    }
    // Free memory
    freeifaddrs(interfaces);
  }
  NSString *addr = wifiAddress ? wifiAddress : cellAddress;
  return addr ? addr : @"0.0.0.0";
}

+ (NSDateFormatter*)timeFmt
{
    static NSDateFormatter *formatter = nil;
    if(formatter == nil){
        formatter= [[NSDateFormatter alloc] init];
        NSTimeZone *zone = [NSTimeZone timeZoneWithName:@"UTC"];
        [formatter setTimeZone:zone];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    }
    return formatter;
}

//-----------TokenGeneration-----------------------------
+ (NSString*) randomToken:(int)len{
    
    static NSString *list = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    int list_len =62;
    NSMutableString *s = [NSMutableString stringWithCapacity:len];
    for (NSUInteger i = 0U; i < len; i++) {
        u_int32_t r = arc4random() % list_len;
        unichar c = [list characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    return s;
}

@end
