//
//  NSView+iWorkFixer.m
//  KeynoteFixer
//
//  Created by Tyshawn on 3/28/20.
//  Copyright © 2020 Tyshawn Cormier. All rights reserved.
//

#import "NSView+iWorkFixer.h"
#import "NSObject+KeynoteFixer.h"
#import <objc/runtime.h>

@implementation NSView (iWorkFixer)

+ (void)load {
    if (!GeneralFixerOSIsMojaveOrLater()) {
        return;
    }

    NSString *bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
    NSLog(@"Bundle identifier is %@", bundleIdentifier);
    if (![bundleIdentifier containsString:@"com.apple.iWork.Pages"]) {
        return;
    }

    NSLog(@"On macOS Mojave, viewWillDraw significantly degrades the performance of Pages when typing and scrolling. Swap it with a no-op.");
    method_exchangeImplementations(class_getInstanceMethod([self class], @selector(viewWillDraw)),
                                   class_getInstanceMethod([self class], @selector(swizzled_viewWillDraw)));
}

- (void)swizzled_viewWillDraw {
}

@end
