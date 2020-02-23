//
//  NSView+Fixer.m
//  OriginFixer
//
//  Created by Tyshawn on 2/22/20.
//  Copyright © 2020 Tyshawn. All rights reserved.
//

#import <objc/runtime.h>
#import "NSView+Fixer.h"
#import <AppKit/AppKit.h>

@implementation NSView (Fixer)

+ (void)load {
    Class class = [self class];
    
    method_exchangeImplementations(class_getInstanceMethod([NSView class], @selector(setFrameOrigin:)),
                                   class_getInstanceMethod(class, @selector(fix_setFrameOrigin:)));
}

- (void)fix_setFrameOrigin:(NSPoint)newOrigin
{
    @try {
        [self fix_setFrameOrigin:newOrigin];
    }
    @catch (NSException *exception) {
        NSLog(@"Caught exception %@ when setting frame origin to %@", exception, NSStringFromPoint(newOrigin));
    }
}

@end
