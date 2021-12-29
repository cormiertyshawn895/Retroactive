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

    NSLog(@"On macOS Mojave, -[SLScrollView viewWillDraw] significantly degrades the performance of Pages when typing and scrolling. Swap it with a no-op.");
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"SLScrollView"), @selector(viewWillDraw)),
                                   class_getInstanceMethod([self class], @selector(swizzled_viewWillDraw)));
}

- (void)swizzled_viewWillDraw {
    NSString *classString = NSStringFromClass([self class]);
    // Even though we're swizzling SLScrollView, this method still gets called for NSScrollView,
    // which causes problems with the Template Chooser and the Page Thumbnails or Search sidebar.
    // Only bail early if it is SLScrollView.
    if ([classString isEqualToString:@"SLScrollView"]) {
        return;
    }
    [self swizzled_viewWillDraw];
}

@end
