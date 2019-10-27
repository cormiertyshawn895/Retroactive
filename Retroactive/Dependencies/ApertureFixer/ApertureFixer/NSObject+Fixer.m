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
}

- (BOOL)_hasRowHeaderColumn {
	return NO;
	
}
@end
