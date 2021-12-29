//
//  NSObject+KeynoteFixer.m
//  KeynoteFixer
//
//  Created by Mac on 11/17/19.
//  Copyright © 2019 Tyshawn Cormier. All rights reserved.
//

#import "NSObject+KeynoteFixer.h"
@import AppKit;

BOOL GeneralFixerOSIsMojaveOrLater() {
    static BOOL isMojaveOrLater;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isMojaveOrLater = [NSProcessInfo processInfo].operatingSystemVersion.minorVersion >= 14;
    });
    return isMojaveOrLater;
}

@implementation NSScreen (KeynoteFixer)

+ (void)load {
    NSLog(@"Loading iWork Fixer");
}

+ (void)_resetScreens {
    NSLog(@"Skipping _resetScreens");
}

@end
