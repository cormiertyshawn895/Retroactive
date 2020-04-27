//
//  NSScroller+iWorkFixer.m
//  KeynoteFixer
//
//  Created by Tyshawn on 4/13/20.
//  Copyright © 2020 Tyshawn Cormier. All rights reserved.
//

#import "NSScroller+iWorkFixer.h"
#import "NSObject+KeynoteFixer.h"
#import <objc/runtime.h>

@interface NSScroller ()
- (CGFloat)overlayScrollerKnobAlpha;
- (CGFloat)overlayScrollerTrackAlpha;
- (NSScrollerStyle)_lionScrollerStyle;
@end

@implementation NSScroller (Fixer)

+ (void)load {
    if (!GeneralFixerOSIsMojaveOrLater()) {
        return;
    }

    NSLog(@"On macOS Mojave, the scroll bar is sometimes behind the document canvas. Don't want layer if the knob and track are invisible.");

    Class scrollerClass = [self class];
    
    method_exchangeImplementations(class_getInstanceMethod(scrollerClass, NSSelectorFromString(@"wantsLayer")),
                                   class_getInstanceMethod(scrollerClass, @selector(swizzled_wantsLayer)));
    
    method_exchangeImplementations(class_getInstanceMethod(scrollerClass, NSSelectorFromString(@"_really_setLionScrollerStyle:")),
                                   class_getInstanceMethod(scrollerClass, @selector(_swizzled_really_setLionScrollerStyle:)));
    
    method_exchangeImplementations(class_getInstanceMethod(scrollerClass, NSSelectorFromString(@"setOverlayScrollerKnobAlpha:")),
                                   class_getInstanceMethod(scrollerClass, @selector(swizzled_setOverlayScrollerKnobAlpha:)));
    
    method_exchangeImplementations(class_getInstanceMethod(scrollerClass, NSSelectorFromString(@"setOverlayScrollerTrackAlpha:")),
                                   class_getInstanceMethod(scrollerClass, @selector(swizzled_setOverlayScrollerTrackAlpha:)));
}

- (BOOL)_scrollerWantsLayer {
    return [self _lionScrollerStyle] == NSScrollerStyleOverlay && ([self overlayScrollerKnobAlpha] > 0.0 || [self overlayScrollerTrackAlpha] > 0.0);
}

- (void)_updateWantsLayer {
    [self setWantsLayer:[self _scrollerWantsLayer]];
}

- (BOOL)swizzled_wantsLayer {
    return ([self _scrollerWantsLayer] || [super wantsLayer]);
}

- (void)_swizzled_really_setLionScrollerStyle:(NSScrollerStyle)newScrollerStyle {
#if DEBUG
    NSLog(@"_really_setLionScrollerStyle");
#endif
    [self _swizzled_really_setLionScrollerStyle:newScrollerStyle];
    [self _updateWantsLayer];
}

- (void)swizzled_setOverlayScrollerKnobAlpha:(CGFloat)alpha {
#if DEBUG
    NSLog(@"swizzled_setOverlayScrollerKnobAlpha");
#endif
    [self swizzled_setOverlayScrollerKnobAlpha:alpha];
    [self _updateWantsLayer];
}

- (void)swizzled_setOverlayScrollerTrackAlpha:(CGFloat)alpha {
#if DEBUG
    NSLog(@"swizzled_setOverlayScrollerTrackAlpha");
#endif
    [self swizzled_setOverlayScrollerTrackAlpha:alpha];
    [self _updateWantsLayer];
}

@end
