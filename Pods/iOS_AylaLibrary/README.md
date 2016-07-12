
iOS Ayla Mobile Library (iAML)
=======================


Build
=====
$ pod —-version (0.38.2+)
$ pod update


Documentation & Coding Examples
===============================
See “Ayla Mobile Library for iOS.docx” in the root library repo directory for an over view of how the library is organized, common error handling, paradigms and conventions.
AppleDoc is available in the Documentation folder:
  <repo>/iOS_AylaLibrary/Documentations/html/index.html
See  “Getting Started with the Ayla Mobile Control.docx” in the root iMCA application repo directory.
Use the iOS Ayla Mobile Control App (iMCA) for a basic working example using iAML.
For additional coding examples refer to the unit test code in <repoDir>/iOS_AylaLibraryTests/


Release Notes
=============

iAML v4.4.00                                     01/25/16
- Add sharing a device with a role feature
- eMail validation improvement - Customer Bug: AAML-165
- OAuth authentication create an AylaUser object
- SMS country code leading zeros are stripped before submitting to app service

iAML v4.3.20                                     12/15/15
- Add Ayla SSO support for external identity providers
- Add hidden network support in Wi-Fi Setup
- Add a new API to get device with DSN (for dealer/distributor apps only)
- Add property role & role tags to AylaUser
- (IAML-15) Fix device manager maintaining duplicate zigbee nodes
- Includes hotfix 4.3.01

iAML v4.3.01                                     10/29/15
- (IAML-17) Fixed one compiling error when adding library to a new project

iAML v4.3.00                                     10/18/15
 — iOS 9 support  
 - To-device batch datapoints support (Cloud only)
 - Enable time range filter in datapoints query
 - Add property 'type' to AylaProperty
 - Add option to enable/disable notify outstanding
 - (IAML-12) Extend LAN session for 30 seconds when application enters background
 - Includes hotfix 4.2.1

###iOS 9 App Change                                   09/07/15  
    Symptom: LAN Mode does not work on iOS 9  
    Symptom: WiFi Setup does not work on iOS 9  
    
    Scope: All application using iOS_AylaLibraries

    Required: info.plist ATS changes

    Two changes are required for IoT applications built on Ayla Mobile Libraries (AML) to
    support iOS 9. Both are related to  privacy and security tightening by Apple in the new
    release. The changes may not be submitted to iTunes Connect until iOS 9 is released and
    the capabilities of the release may change from the writing of this document. We will
    continue to monitor the iOS 9 GM release to ensure compatibility.

    These changes were tested with iOS 9 GM using XCode 7 GM.


    Symptom: Cannot complete user login
    Symptom: LAN Mode does not work on iOS 9

    In iOS 9, the allowance of arbitrary loads must be added to the application info.plist to
    allow for communication between the mobile libraries and the cloud user service & between
    the device/gateway and the Ayla Mobile Libraries. To correct the issue include the
    following in the application info.plist:

        <key>NSAppTransportSecurity</key>
        <dict>
          <key>NSAllowsArbitraryLoads</key>
          <true/>
        </dict>

    This allows for HTTP communication to happen between the device/gateway and the Ayla Mobile
    Libraries. Security is ensured by a per session key used with an AES256 CBC based hash with
    initialization vector to encrypt the HTTP payload. 


    Symptom: WiFi Setup does not work on iOS 9

    Applications implementing Wi-Fi Setup with SDK 9.0, must use the ATS info.plist fix.
    Failure to do so will cause Wi-Fi Setup to stop working when a user upgrades their iPhone or
    Tablet to iOS 9.

    In iOS 9, Captive Network support is deprecated and will be fully addressed in the next release.
    This change directly impacts our Wi-Fi setup flow as AML accesses the currently connected SSID
    to check if the device has connected to an AP-Mode new device.

    Notes

    1) To release your application prior to the iOS 9 release, build your app with the 8.4 SDK.
    No ATS exceptions are required.

    2) For applications built using the iOS 9 SDK, include the ATS exceptions to the application
    plist, and upgrade to the next available library release.


iAML v4.2.0                                      08/15/15  
  - Generic Gateway ACKed properties, cloud & LAN  
  - Generic Gateway batched datapoints, cloud & LAN  
  - Default mDNS port handling for Generic Gateway  
  - Improved setup and registration flow  
  - New file and console logger service  
  - Improved background logging and diagnostics  
  - Support for phone country codes & time zones that match the service  
  - Includes hotfix 4.1.01 through 4.1.04  

iAML v4.1.0                                      07/16/15
  - PropertyTriggerApp and DeviceNotificationApp by contactId support
  - Generic Gateway (GG) Cloud Support
  - GG lan-mode support
  - Multi-LAN mode support

iAML v4.0.0                                      06/10/15
  - Architecture support for devices, gateways, and nodes
