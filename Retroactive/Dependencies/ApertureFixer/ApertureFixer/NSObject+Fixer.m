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
	return [self patched_URLForApplicationWithBundleIdentifier:bundleIdentifier ?: @"com.apple.iPhoto"];
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
    
    Class printClass = NSClassFromString(@"RKPrintPanel");
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"RKPrintPanel"), NSSelectorFromString(@"_updatePageSizePopup")),
                                   class_getInstanceMethod(printClass, @selector(patched_updatePageSizePopup)));
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"RKRedRockApp"), NSSelectorFromString(@"_delayedFinishLaunching")),
                                   class_getInstanceMethod(class, @selector(patched_delayedFinishLaunching)));
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"NSConcretePrintOperation"), NSSelectorFromString(@"runOperation")),
                                   class_getInstanceMethod(class, @selector(patched_runOperation)));
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"RKPrinter"), NSSelectorFromString(@"paperWithID:")),
                                   class_getInstanceMethod(class, @selector(patched_paperWithID:)));
}

- (id)patched_paperWithID:(id)arg1 {
    NSLog(@"patching paperWithID to prevent crashes");
    return nil;
}

- (void)patched_runOperation {
    NSLog(@"patching runOperation to run on main queue to prevent Auto Layout crashes");
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"running operation on main queue");
        [self patched_runOperation];
    });
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
