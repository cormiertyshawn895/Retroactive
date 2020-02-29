//
//  NSImage+Fixer.m
//  OriginFixer
//
//  Created by Tyshawn on 2/27/20.
//  Copyright © 2020 Tyshawn. All rights reserved.
//

#import <objc/runtime.h>
#import <AppKit/AppKit.h>
#import "BDAlias.h"
#import <Carbon/Carbon.h>
#import "NSImage+Fixer.h"

@interface FIXInBundleClass : NSObject
@end

@implementation FIXInBundleClass
@end

@implementation NSImage (Fixer)

+ (void)load {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    if ([version hasPrefix:@"12."]) {
        NSLog(@"OriginFixer is running on iTunes 12.");
        Class class = [self class];
        method_exchangeImplementations(class_getClassMethod([NSImage class], @selector(imageNamed:)),
                                       class_getClassMethod(class, @selector(fix_imageNamed:)));
        [self fix_clearAlbumCache];
    } else {
        NSLog(@"OriginFixer is not running on iTunes 12.");
    }
}

+ (void)fix_clearAlbumCache {
    NSError *error = nil;
    NSString *lastClearLibraryCacheFolderKey = @"LastClearLibraryCacheFolder";
    NSString *lastCacheFolder = [[NSUserDefaults standardUserDefaults] stringForKey:lastClearLibraryCacheFolderKey];
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:@"alis:1:iTunes Library Location"];
    if (!data) { return; }
    BDAlias *alias = [BDAlias aliasWithData:data];
    if (!alias) { return; }

    NSString *artCachePath = [[alias.fullPath stringByAppendingPathComponent:@"Album Artwork"] stringByAppendingPathComponent:@"Cache"];
    if (!artCachePath.length || [artCachePath isEqualToString:lastCacheFolder]) {
        NSLog(@"Cache folder %@ already cleared once, not clearing it again.", artCachePath);
        return;
    }

    NSLog(@"Library is at %@, artwork is cached at %@", alias.fullPath, artCachePath);
    [[NSFileManager defaultManager] removeItemAtPath:artCachePath error:&error];
    if (error) {
        NSLog(@"Can't remove the album artwork cache folder %@", error);
    } else {
        NSLog(@"Removed album artwork cache folder");
        [[NSUserDefaults standardUserDefaults] setValue:artCachePath forKey:lastClearLibraryCacheFolderKey];
    }
}

+ (NSImage *)fix_imageNamed:(NSString *)name
{
    if ([name isEqualToString:@"DeviceAppMask"]) {
        NSBundle *bundle = [NSBundle bundleForClass:[FIXInBundleClass class]];
        NSImage *mask = [bundle imageForResource:@"FixDeviceAppMask"];
        NSLog(@"Returning fixed app mask %@ in bundle %@", mask, bundle);

        return mask;
    }
    return [self fix_imageNamed:name];
}

@end
