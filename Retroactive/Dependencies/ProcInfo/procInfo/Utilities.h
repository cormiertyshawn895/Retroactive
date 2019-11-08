//
//  File: Utilities.h
//  Project: Proc Info
//
//  Created by: Patrick Wardle
//  Copyright:  2017 Objective-See
//  License:    Creative Commons Attribution-NonCommercial 4.0 International License
//

#ifndef Utilties_h
#define Utilties_h

#import <Foundation/Foundation.h>

//given a path to binary
// parse it back up to find app's bundle
NSBundle* PI_findAppBundle(NSString* binaryPath);

//check if current OS version is supported
BOOL PI_isSupportedOS(void);

//get OS version
NSDictionary* PI_getOSVersion(void);

//enumerate all running processes
NSMutableArray* PI_enumerateProcesses(void);

//given a bundle
// find its executable
NSString* PI_findAppBinary(NSString* appPath);

//given a 'short' path or process name
// find the full path by scanning $PATH
NSString* PI_which(NSString* processName);

#endif
