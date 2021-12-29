//
//  NSButtonCell+iWorkFixer.m
//  KeynoteFixer
//
//  Created by Tyshawn on 4/13/20.
//  Copyright © 2020 Tyshawn Cormier. All rights reserved.
//

#import "NSButtonCell+iWorkFixer.h"
#import "NSObject+KeynoteFixer.h"
#import <objc/runtime.h>

@implementation NSButtonCell (iWorkFixer)

+ (void)load {
    if (!GeneralFixerOSIsMojaveOrLater()) {
        return;
    }

    NSLog(@"On macOS Mojave, SFIFormatBarSegmentedButtonCell's interiorBackgroundFillColor defaults to white. Replace it with nil so the format controls look correct.");
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"SFIFormatBarSegmentedButtonCell"), NSSelectorFromString(@"_interiorBackgroundFillColor")),
                                   class_getInstanceMethod([self class], @selector(swizzle_interiorBackgroundFillColor)));
    
}

- (NSColor *)swizzle_interiorBackgroundFillColor {
    return nil;
}

@end
