//
//  NSObject+VideoFixer.m
//  VideoFixer
//
//  Created by Tyshawn on 11/16/19.
//  Copyright © 2019 Tyshawn Cormier. All rights reserved.
//

#import "NSObject+VideoFixer.h"
#import <objc/runtime.h>

@import AppKit;

int NoProSplash() {
    return 0;
}

@implementation NSObject (VideoFixer)

+ (void)load {
    NSLog(@"Loading VideoFixer");
    
    Class textFieldCellClass = NSClassFromString(@"NSTextFieldCell");
    method_exchangeImplementations(class_getInstanceMethod(textFieldCellClass, NSSelectorFromString(@"setFont:")), class_getInstanceMethod(self, @selector(hook_setFont:)));
    
    Class exceptionClass = [NSException class];
    method_exchangeImplementations(class_getClassMethod(exceptionClass, NSSelectorFromString(@"raise:format:")), class_getClassMethod(self, @selector(hook_raise:format:)));
    method_exchangeImplementations(class_getInstanceMethod(exceptionClass, NSSelectorFromString(@"raise")), class_getInstanceMethod(self, @selector(hook_raise)));
    
    Class canvasClass = NSClassFromString(@"OZCanvasView");
    method_exchangeImplementations(class_getInstanceMethod(canvasClass, NSSelectorFromString(@"setSubViewLayout:")), class_getInstanceMethod(self, @selector(hook_setSubViewLayout:)));
    
    Class alertClass = NSClassFromString(@"NSAlert");
    method_exchangeImplementations(class_getInstanceMethod(alertClass, NSSelectorFromString(@"setDontWarnDefaultsKey:defaultReturnCode:")), class_getInstanceMethod(self, @selector(hook_setSubViewLayout:)));

}

- (void)_stopAnimationWithWait:(float)seconds {
    NSLog(@"skipping _stopAnimationWithWait");
}

- (void)setDontWarnDefaultsKey:(id)key defaultReturnCode:(id)code { }

- (void)changeCluster:(id)arg { }

- (void)_autoreopenDocuments { }

- (void)_scrollLastColumnMaxXEdgeToVisible { }

- (void)_shouldInvalidateShadow { }

- (void)hook_setFont:(NSFont *)sender {
    NSFont *newFont = [NSFont fontWithName:[sender.fontName stringByReplacingOccurrencesOfString:@"HelveticaNeue-" withString:@".AppleSystemUIFont"] size:sender.pointSize];
    [self hook_setFont:newFont];
}

- (BOOL)_hasRowHeaderColumn {
    return NO;
}

- (void)hook_raise
{
    NSLog(@"Silencing exception %@.", self);
}

- (void)hook_setSubViewLayout:(id)arg1 {
    NSLog(@"Skipping setSubViewLayout");
}

- (void)hook_raise:(id)arg1 format:(id)arg2
{
    NSLog(@"Silencing exception %@, %@.", arg1, arg2);
}

@end
