//
//  NSToolbarItem+Fixer.m
//  ApertureFixer
//

#import "NSToolbarItem+Fixer.h"
#import <objc/runtime.h>
#import <AppKit/AppKit.h>

@implementation NSToolbarItem (Fixer)

static BOOL pretendToHaveAction = NO;

+ (void)load {
    Class class = [self class];
    method_exchangeImplementations(class_getInstanceMethod([NSToolbarItem class], NSSelectorFromString(@"setImage:")),
                                   class_getInstanceMethod(class, @selector(patched_setImage:)));

    method_exchangeImplementations(class_getInstanceMethod([NSToolbarItem class], NSSelectorFromString(@"action")),
                                   class_getInstanceMethod(class, @selector(patched_action)));
}

/*
 Aperture sets the image on NSProToolbarItem first. Without an existing action or title,
 AppKit mistakenly treats us as an image-only toolbar item, and creates an NSToolbarImageView
 instead of a NSToolbarButton, breaking the NSProToolbarItem subclass in ProKit. Pretend to
 have a valid action.
 */
- (void)patched_setImage:(NSImage *)image {
    pretendToHaveAction = YES;
    [self patched_setImage:image];
    pretendToHaveAction = NO;
}

- (SEL)patched_action {
    SEL actualAction = [self patched_action];
    if (pretendToHaveAction && !actualAction) {
        return @selector(copy);
    }
    return actualAction;
}

@end
