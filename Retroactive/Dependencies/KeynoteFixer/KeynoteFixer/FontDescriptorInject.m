//
//  FontDescriptorInject.m
//  KeynoteFixer
//
//  Created by Tyshawn on 4/26/20.
//  Copyright © 2020 Tyshawn Cormier. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "fishhook.h"

@interface IWFEmptyClass : NSObject
@end

@implementation IWFEmptyClass
@end

static CFStringRef IWFCoreTextBundleIdentifier = CFSTR("com.apple.CoreText");
static CFStringRef IWFDefaultFontFallbacksPlistName = CFSTR("DefaultFontFallbacks.plist");

static CFURLRef (*orig_CFBundleCopyResourceURL)(CFBundleRef, CFStringRef, CFStringRef, CFStringRef);
CFURLRef replacement_CFBundleCopyResourceURL(CFBundleRef bundle, CFStringRef resourceName, CFStringRef resourceType, CFStringRef subDirName) {
    static BOOL hasReplacedFontFallbacksURL = NO;
    if (hasReplacedFontFallbacksURL) {
        orig_CFBundleCopyResourceURL(bundle, resourceName, resourceType, subDirName);
    }
    CFStringRef bundleIdentifier = CFBundleGetIdentifier(bundle);
    if (CFStringCompare(IWFDefaultFontFallbacksPlistName, resourceName, kCFCompareCaseInsensitive) == kCFCompareEqualTo && CFStringCompare(IWFCoreTextBundleIdentifier, bundleIdentifier, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
        NSURL *overrideFallbackURL = [[NSBundle bundleForClass:[IWFEmptyClass class]] URLForResource:@"DefaultFontFallbacks" withExtension:@"plist"];
        NSLog(@"Replacing the CoreText DefaultFontFallbacks plist with our own at %@. Subsequent calls to CFBundleCopyResourceURL will always use the original implementation.", overrideFallbackURL);
        if (overrideFallbackURL) {
            hasReplacedFontFallbacksURL = YES;
            return CFBridgingRetain(overrideFallbackURL);
        }
    }
    return orig_CFBundleCopyResourceURL(bundle, resourceName, resourceType, subDirName);
}

__attribute__((constructor))
static void ctor(void) {
    rebind_symbols((struct rebinding[1]){{"CFBundleCopyResourceURL", replacement_CFBundleCopyResourceURL, (void *)&orig_CFBundleCopyResourceURL}}, 1);
}
