//
//  NSObject+Fixer.m
//  ApertureFixer
//
//

#import <objc/runtime.h>
#import <AppKit/AppKit.h>
#import "NSObject+Fixer.h"

static
@implementation NSObject (Fixer)

+ (NSFont *)swizzled_proSystemFontWithFontName:(NSString *)name pointSize:(CGFloat)size fontAppearance:(id)appearance useSystemHelveticaAdjustments:(BOOL)adjustments {
	return [NSFont systemFontOfSize:size];
}

- (NSURL *)patched_URLForApplicationWithBundleIdentifier:(NSString *)bundleIdentifier {
    NSString *appBundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
    if (!bundleIdentifier) {
        if ([appBundleIdentifier containsString:@"com.apple.iPhoto"]) {
            bundleIdentifier = @"com.apple.Aperture3";
        } else {
            bundleIdentifier = @"com.apple.iPhoto9";
        }
    }
    NSURL *urlForBundle = [self patched_URLForApplicationWithBundleIdentifier:bundleIdentifier];
    NSLog(@"this app is %@, looking for %@ at %@", appBundleIdentifier, bundleIdentifier, urlForBundle);
	return urlForBundle;
}

- (void)_addToolTipRects {
}

+ (void)load {
	Class class = [self class];
	
	// patch out +[NSProFont _proSystemFontWithFontName:pointSize:fontAppearance:useSystemHelveticaAdjustments]
	method_exchangeImplementations(class_getClassMethod(NSClassFromString(@"NSProFont"), NSSelectorFromString(@"_proSystemFontWithFontName:pointSize:fontAppearance:useSystemHelveticaAdjustments:")),
								   class_getClassMethod(class, @selector(swizzled_proSystemFontWithFontName:pointSize:fontAppearance:useSystemHelveticaAdjustments:)));

	method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"NSWorkspace"), NSSelectorFromString(@"URLForApplicationWithBundleIdentifier:")),
								   class_getInstanceMethod(class, @selector(patched_URLForApplicationWithBundleIdentifier:)));
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"RKPrintPanel"), NSSelectorFromString(@"_updatePageSizePopup")),
                                   class_getInstanceMethod(class, @selector(patched_updatePageSizePopup)));
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"RKRedRockApp"), NSSelectorFromString(@"_delayedFinishLaunching")),
                                   class_getInstanceMethod(class, @selector(patched_delayedFinishLaunching)));
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"NSConcretePrintOperation"), NSSelectorFromString(@"runOperation")),
                                   class_getInstanceMethod(class, @selector(patched_runOperation)));
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"RKPrinter"), NSSelectorFromString(@"paperWithID:")),
                                   class_getInstanceMethod(class, @selector(patched_paperWithID:)));
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"IPPrinterPaperSelectionView"), NSSelectorFromString(@"updatePaperMenu")),
                                   class_getInstanceMethod(class, @selector(patched_updatePaperMenu)));
}

- (id)patched_paperWithID:(id)arg1 {
    NSLog(@"patching paperWithID to prevent crashes");
    return nil;
}

- (void)patched_updatePaperMenu {
    NSLog(@"skipping updatePaperMenu to prevent crashes");
}

- (void)patched_runOperation {
    NSLog(@"patching runOperation");
    if ([NSThread isMainThread]) {
        NSLog(@"current thread is already main thread, calling runOperation as is");
        [self patched_runOperation];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"running operation on main queue after dispatching to main queue");
            [self patched_runOperation];
        });
    }
}

- (void)patched_delayedFinishLaunching {
    NSLog(@"kick delayedFinishLaunching to the next run loop, so that the adjustments menu can populate");
    [self performSelector:@selector(patched_delayedFinishLaunching) withObject:nil afterDelay:0];
}

- (void)patched_updatePageSizePopup {
    NSLog(@"skipping updatePageSizePopup to prevent a crash");
}

- (BOOL)_hasRowHeaderColumn {
	return NO;
	
}
@end
