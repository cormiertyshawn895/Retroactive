//
//  NSObject+KeynoteFixer.m
//  KeynoteFixer
//
//  Created by Mac on 11/17/19.
//  Copyright © 2019 Tyshawn Cormier. All rights reserved.
//

#import "NSObject+KeynoteFixer.h"
@import AppKit;

@implementation NSScreen (KeynoteFixer)

+ (void)load {
    NSLog(@"Loading KeynoteFixer");
    
}

+ (void)_resetScreens {
    NSLog(@"skipping _resetScreens");
}

@end
