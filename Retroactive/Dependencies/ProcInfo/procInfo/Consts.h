//
//  File: Consts.h
//  Project: Proc Info
//
//  Created by: Patrick Wardle
//  Copyright:  2017 Objective-See
//  License:    Creative Commons Attribution-NonCommercial 4.0 International License
//

#ifndef Consts_h
#define Consts_h

//OS version x
#define OS_MAJOR_VERSION_X 10

//OS version lion
#define OS_MINOR_VERSION_LION 8

//OS version sierra
#define OS_MINOR_VERSION_SIERRA 12

//audit pipe
#define AUDIT_PIPE "/dev/auditpipe"

//audit class for proc events
#define AUDIT_CLASS_PROCESS 0x00000080

//audit class for exec events
#define AUDIT_CLASS_EXEC 0x40000000

//key for stdout output
#define STDOUT @"stdOutput"

//key for stderr output
#define STDERR @"stdError"

//key for exit code
#define EXIT_CODE @"exitCode"

//path to codesign
#define CODE_SIGN @"/usr/bin/codesign"

//entitlements
#define KEY_SIGNING_ENTITLEMENTS @"entitlements"

#endif /* Consts_h */
