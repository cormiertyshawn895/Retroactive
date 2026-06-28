//
//  NSObject+Fixer.m
//  ApertureFixer
//
//

#import <objc/runtime.h>
#import <objc/message.h>
#import <AppKit/AppKit.h>
#import <dlfcn.h>
#import <sys/sysctl.h>
#import "NSObject+Fixer.h"

static BOOL retro_osAtLeastSequoia(void) {
    static int cached = -1;
    if (cached < 0) {
        char release[256]; size_t size = sizeof(release);
        cached = (sysctlbyname("kern.osrelease", release, &size, NULL, 0) == 0 && atoi(release) >= 24) ? 1 : 0;
    }
    return cached == 1;
}

static BOOL retro_osAtLeastTahoe(void) {
    static int cached = -1;
    if (cached < 0) {
        char release[256]; size_t size = sizeof(release);
        cached = (sysctlbyname("kern.osrelease", release, &size, NULL, 0) == 0 && atoi(release) >= 25) ? 1 : 0;
    }
    return cached == 1;
}

static void retro_swizzle(const char *clsName, NSString *sel, SEL replacement) {
    Class cls = objc_getClass(clsName);
    if (!cls) return;
    Method a = class_getInstanceMethod(cls, NSSelectorFromString(sel));
    Method b = class_getInstanceMethod(cls, replacement);
    if (a && b) method_exchangeImplementations(a, b);
}

static void retro_addFallback(const char *clsName, SEL sel, const char *types, id block) {
    Class cls = objc_getClass(clsName);
    if (!cls) return;
    if (class_getInstanceMethod(cls, sel)) return;
    class_addMethod(cls, sel, imp_implementationWithBlock(block), types);
}

static void retro_installProgressFallbacks(void) {
    const char *c = "NSProgressIndicator";
    retro_addFallback(c, @selector(_proIsSpinning),         "c@:",  ^BOOL(id s){ return NO; });
    retro_addFallback(c, @selector(_proAnimationIndex),     "Q@:",  ^unsigned long long(id s){ return 0; });
    retro_addFallback(c, @selector(_setProAnimationIndex:), "v@:Q", ^(id s, unsigned long long v){});
    retro_addFallback(c, @selector(_installHeartBeat:),     "v@:@", ^(id s, id hb){});
    retro_addFallback(c, @selector(_proDelayedStartup),     "c@:",  ^BOOL(id s){ return NO; });
    retro_addFallback(c, @selector(_setProDelayedStartup:), "v@:c", ^(id s, BOOL v){});
}

static NSColorSpace *retro_remapColorSpace(NSColorSpace *cs) {
    if (cs && cs.colorSpaceModel == NSColorSpaceModelRGB) {
        CGColorSpaceRef cg = cs.CGColorSpace;
        if (cg) {
            CFStringRef nm = CGColorSpaceCopyName(cg);
            if (nm) {
                BOOL extended = CFStringFind(nm, CFSTR("xtended"), 0).location != kCFNotFound;
                CFRelease(nm);
                if (extended) return [NSColorSpace sRGBColorSpace];
            }
        }
    }
    return cs;
}

static void retro_installColorSpaceFix(Class cls) {
    unsigned n = 0; Method *ms = class_copyMethodList(cls, &n); BOOL owns = NO;
    for (unsigned i = 0; i < n; i++) if (method_getName(ms[i]) == @selector(colorSpace)) { owns = YES; break; }
    free(ms);
    if (!owns) return;
    Method m = class_getInstanceMethod(cls, @selector(colorSpace));
    if (!m) return;
    IMP orig = method_getImplementation(m);
    IMP rep = imp_implementationWithBlock(^NSColorSpace *(id self) {
        return retro_remapColorSpace(((NSColorSpace *(*)(id, SEL))orig)(self, @selector(colorSpace)));
    });
    method_setImplementation(m, rep);
}

static Class retro_proSegmentedCell(void) {
    static Class c; if (!c) c = objc_getClass("NSProSegmentedCell"); return c;
}

static void retro_installReservationFix(void) {
    Class cls = objc_getClass("HgFSReservation");
    if (!cls) {
        NSString *fw = [[NSBundle mainBundle].privateFrameworksPath
                        stringByAppendingPathComponent:@"iLifeSQLAccess.framework/Versions/A/iLifeSQLAccess"];
        if (fw) dlopen(fw.fileSystemRepresentation, RTLD_LAZY);
        cls = objc_getClass("HgFSReservation");
    }
    if (!cls) return;
    Method a = class_getInstanceMethod(cls, NSSelectorFromString(@"acquireReservation"));
    Method b = class_getInstanceMethod(cls, @selector(retro_acquireReservation));
    if (a && b) method_exchangeImplementations(a, b);
}

static double *retro_segFullWidthSlot(id obj) {
    Ivar iv = class_getInstanceVariable(object_getClass(obj), "_fullWidth");
    return iv ? (double *)((char *)obj + ivar_getOffset(iv)) : NULL;
}

static double retro_segFullWidthAt(id cell, NSInteger seg);

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
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"RKRedRockApp"), NSSelectorFromString(@"_moveCommandSetsToSandboxLocation")),
                                   class_getInstanceMethod(class, @selector(patched_moveCommandSetsToSandboxLocation)));

    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"NSConcretePrintOperation"), NSSelectorFromString(@"runOperation")),
                                   class_getInstanceMethod(class, @selector(patched_runOperation)));
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"RKPrinter"), NSSelectorFromString(@"paperWithID:")),
                                   class_getInstanceMethod(class, @selector(patched_paperWithID:)));
    
    method_exchangeImplementations(class_getInstanceMethod(NSClassFromString(@"IPPrinterPaperSelectionView"), NSSelectorFromString(@"updatePaperMenu")),
                                   class_getInstanceMethod(class, @selector(patched_updatePaperMenu)));

    retro_installProgressFallbacks();

    retro_swizzle("NSWindow", @"setTitle:", @selector(retro_winSetTitle:));
    if (retro_osAtLeastTahoe()) {
        retro_swizzle("NSProWindowFrame", @"_drawTitleBar:", @selector(retro_proDrawTitleBar:));
    }

    if (!retro_osAtLeastSequoia()) return;

    setenv("SWIFT_ENFORCE_EXCLUSIVITY", "off", 1);

    retro_swizzle("NSSegmentedCell", @"_refreshVisualProvider", @selector(retro_refreshVisualProvider));
    retro_swizzle("NSSegmentedCell", @"_visualProvider", @selector(retro_visualProvider));
    retro_swizzle("NSSegmentedCell", @"_visualProviderIfExists", @selector(retro_visualProviderIfExists));

    retro_swizzle("NSSegmentedControlAppearanceBasedVisualProvider", @"updateSegmentItemConfiguration:", @selector(retro_updateSegmentItemConfiguration:));

    retro_swizzle("NSProPopOverWindow", @"orderOutWithAnimationStyle:autorelease:", @selector(retro_proPopOrderOut:autorelease:));

    retro_installReservationFix();

    retro_swizzle("NSApplication", @"runModalSession:", @selector(retro_runModalSession:));

    retro_swizzle("NSWindow", @"isRestorable", @selector(retro_isRestorable));
    retro_swizzle("NSPersistentUIManager", @"hasPersistentStateToRestore", @selector(retro_hasPersistentStateToRestore));
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NSQuitAlwaysKeepsWindows"];
    NSString *bid = [NSBundle mainBundle].bundleIdentifier ?: @"";
    for (NSString *dir in @[[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Saved Application State"], NSTemporaryDirectory()]) {
        [[NSFileManager defaultManager] removeItemAtPath:[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.savedState", bid]] error:nil];
    }

    retro_swizzle("NSProThemeFacet", @"initWithCoder:", @selector(retro_facetInitWithCoder:));
    retro_swizzle("NSProSegmentedCell", @"drawSegment:inFrame:withView:", @selector(retro_drawSegment:inFrame:withView:));
    retro_swizzle("NSProSegmentedControl", @"intrinsicContentSize", @selector(retro_segIntrinsicContentSize));
    retro_swizzle("NSProSegmentedCell", @"displayWidthForSegment:", @selector(retro_displayWidthForSegment:));
    retro_swizzle("NSProSegmentedCell", @"cellSizeForBounds:", @selector(retro_segCellSizeForBounds:));
    retro_swizzle("NSProSegmentedCell", @"_rectForSegment:inFrame:", @selector(retro_rectForSegment:inFrame:));
    retro_swizzle("NSProSegmentedCell", @"_isProSelectedForSegment:", @selector(retro_isProSelectedForSegment:));
    retro_swizzle("NSProButtonCell", @"cellSizeForBounds:", @selector(retro_btnCellSizeForBounds:));
    retro_swizzle("ViewerUnderbarView", @"drawRect:", @selector(retro_vuDrawRect:));
    retro_swizzle("AutoLayoutView", @"_recursiveSetFrame:level:", @selector(retro_recursiveSetFrame:level:));

    retro_swizzle("TUINSCursorUIController", @"invalidateCharacterCoordinates", @selector(retro_invalidateCharacterCoordinates));

    Class colorBase = objc_getClass("NSColor");
    if (colorBase) {
        int count = objc_getClassList(NULL, 0);
        Class *all = (Class *)malloc(sizeof(Class) * count);
        count = objc_getClassList(all, count);
        for (int i = 0; i < count; i++) {
            for (Class c = all[i]; c; c = class_getSuperclass(c)) {
                if (c == colorBase) { retro_installColorSpaceFix(all[i]); break; }
            }
        }
        free(all);
    }
}

- (void)patched_moveCommandSetsToSandboxLocation {
    NSLog(@"asked to move command sets to sandbox location, but Aperture is unboxed, skipping it");
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

- (void)_autoSizeView:(id)a :(id)b :(id)c :(id)d :(id)e {
    NSLog(@"Skipping _autoSizeView");
}

- (void)setShowingRollover:(id)showingRollover {
}

- (CGFloat)_drawingWidth {
    double *fw = retro_segFullWidthSlot(self);
    return fw ? *fw : 0;
}

- (void)set_drawingWidth:(CGFloat)value {
}

- (void)_alignSize:(id)size force:(id)force {
}

- (BOOL)_needsRecalc {
    return retro_segFullWidthSlot(self) ? YES : NO;
}

- (void)_setNeedsRecalc {
}

- (CGFloat)_displayWidth {
    double *fw = retro_segFullWidthSlot(self);
    if (fw && *fw > 0) return *fw;
    if ([self respondsToSelector:@selector(width)]) {
        CGFloat w = ((CGFloat (*)(id, SEL))objc_msgSend)(self, @selector(width));
        if (w > 0) return w;
    }
    if ([self respondsToSelector:@selector(label)]) {
        NSString *l = ((id (*)(id, SEL))objc_msgSend)(self, @selector(label));
        if ([l isKindOfClass:[NSString class]] && l.length) {
            return [l sizeWithAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]]}].width + 16.0;
        }
    }
    return 0;
}

- (void)retro_refreshVisualProvider {
    if (retro_proSegmentedCell() && [self isKindOfClass:retro_proSegmentedCell()]) return;
    [self retro_refreshVisualProvider];
}

- (id)retro_visualProvider {
    if (retro_proSegmentedCell() && [self isKindOfClass:retro_proSegmentedCell()]) return nil;
    return [self retro_visualProvider];
}

- (id)retro_visualProviderIfExists {
    if (retro_proSegmentedCell() && [self isKindOfClass:retro_proSegmentedCell()]) return nil;
    return [self retro_visualProviderIfExists];
}

- (NSSize)retro_btnCellSizeForBounds:(NSRect)bounds {
    if (bounds.size.width > 10000.0 || bounds.size.height > 10000.0) {
        NSSize ts = NSZeroSize, is = NSZeroSize;
        id title = [self respondsToSelector:@selector(title)] ? ((id (*)(id, SEL))objc_msgSend)(self, @selector(title)) : nil;
        if ([title isKindOfClass:[NSString class]] && [title length]) {
            id font = [self respondsToSelector:@selector(font)] ? ((id (*)(id, SEL))objc_msgSend)(self, @selector(font)) : nil;
            if (![font isKindOfClass:[NSFont class]]) font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
            ts = [(NSString *)title sizeWithAttributes:@{NSFontAttributeName: font}];
            ts.width = ceil(ts.width);
        }
        id img = [self respondsToSelector:@selector(image)] ? ((id (*)(id, SEL))objc_msgSend)(self, @selector(image)) : nil;
        if ([img isKindOfClass:[NSImage class]]) is = [(NSImage *)img size];
        long ip = [self respondsToSelector:@selector(imagePosition)] ? ((long (*)(id, SEL))objc_msgSend)(self, @selector(imagePosition)) : 0;
        CGFloat cw, ch;
        switch (ip) {
            case 1:  cw = is.width;                    ch = is.height;                    break;
            case 4: case 5:
                     cw = MAX(ts.width, is.width);     ch = ts.height + is.height + 2.0;  break;
            case 6:  cw = MAX(ts.width, is.width);     ch = MAX(ts.height, is.height);    break;
            default: cw = ts.width + is.width;         ch = MAX(ts.height, is.height);    break;
        }
        if ((ip == 0 || ip == 2 || ip == 3) && [self respondsToSelector:@selector(titleRectForBounds:)]) {
            NSRect saneB = NSMakeRect(0, 0, 4000, 400);
            NSRect tr = [(NSButtonCell *)self titleRectForBounds:saneB];
            CGFloat inset = saneB.size.width - tr.size.width - is.width;
            if (inset > 0 && inset < 200) cw += inset;
        }
        if (bounds.size.width  > 10000.0) bounds.size.width  = cw;
        if (bounds.size.height > 10000.0) bounds.size.height = ch;
    }
    return ((NSSize (*)(id, SEL, NSRect))objc_msgSend)(self, @selector(retro_btnCellSizeForBounds:), bounds);
}

static CGFloat retro_controlFittedWidth(id ctl) {
    id cell = [ctl respondsToSelector:@selector(cell)] ? ((id (*)(id, SEL))objc_msgSend)(ctl, @selector(cell)) : nil;
    if (!cell || ![ctl respondsToSelector:@selector(segmentCount)]) return 0;
    NSInteger n = ((NSInteger (*)(id, SEL))objc_msgSend)(ctl, @selector(segmentCount));
    if (n <= 0) return 0;
    CGFloat content = 0; BOOL any = NO;
    for (NSInteger k = 0; k < n; k++) {
        double fw = retro_segFullWidthAt(cell, k);
        if (fw > 0) { content += fw; any = YES; }
    }
    if (!any || content <= 0) return 0;
    return content + 4.0 + (CGFloat)(n - 1);
}

- (NSSize)retro_segIntrinsicContentSize {
    NSSize sz = [self retro_segIntrinsicContentSize];
    CGFloat w = retro_controlFittedWidth(self);
    if (w > 0) sz.width = w;
    if ([self isKindOfClass:[NSView class]] &&
        [NSStringFromClass([[(NSView *)self superview] class]) containsString:@"ToolbarItemViewer"] &&
        sz.height > 1.0 && sz.height < 30.0) {
        sz.height = 30.0;
    }
    return sz;
}

static const CGFloat kRetroSegTextPad = 38.0;
static double retro_segFullWidthAt(id cell, NSInteger seg) {
    if (![cell respondsToSelector:@selector(_segmentItems)]) return -1;
    id items = ((id (*)(id, SEL))objc_msgSend)(cell, @selector(_segmentItems));
    if (![items isKindOfClass:[NSArray class]] || seg < 0 || seg >= (NSInteger)[items count]) return -1;
    id ctl = [cell respondsToSelector:@selector(controlView)] ? ((id (*)(id, SEL))objc_msgSend)(cell, @selector(controlView)) : nil;
    if ([ctl respondsToSelector:@selector(widthForSegment:)]) {
        double w = (double)((CGFloat (*)(id, SEL, NSInteger))objc_msgSend)(ctl, @selector(widthForSegment:), seg);
        if (w > 0) return w;
    }
    if (ctl && [ctl respondsToSelector:@selector(labelForSegment:)]) {
        NSString *label = ((NSString *(*)(id, SEL, NSInteger))objc_msgSend)(ctl, @selector(labelForSegment:), seg);
        NSImage *im = [ctl respondsToSelector:@selector(imageForSegment:)] ?
            ((NSImage *(*)(id, SEL, NSInteger))objc_msgSend)(ctl, @selector(imageForSegment:), seg) : nil;
        if ([label isKindOfClass:[NSString class]] && label.length && ![im isKindOfClass:[NSImage class]]) {
            NSFont *font = [cell respondsToSelector:@selector(font)] ? ((NSFont *(*)(id, SEL))objc_msgSend)(cell, @selector(font)) : nil;
            if (![font isKindOfClass:[NSFont class]]) {
                NSControlSize cs = [cell respondsToSelector:@selector(controlSize)] ?
                    ((NSControlSize (*)(id, SEL))objc_msgSend)(cell, @selector(controlSize)) : NSControlSizeRegular;
                font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:cs]];
            }
            CGFloat tw = [label sizeWithAttributes:@{ NSFontAttributeName: font }].width;
            if (tw > 0) return tw + kRetroSegTextPad;
        }
    }
    double *fw = retro_segFullWidthSlot([items objectAtIndex:seg]);
    if (fw && *fw > 0) return *fw;
    return -1;
}

- (CGFloat)retro_displayWidthForSegment:(NSInteger)seg {
    CGFloat orig = ((CGFloat (*)(id, SEL, NSInteger))objc_msgSend)(self, @selector(retro_displayWidthForSegment:), seg);
    double fw = retro_segFullWidthAt(self, seg);
    return fw > 0 ? (CGFloat)fw : orig;
}

- (NSSize)retro_segCellSizeForBounds:(NSRect)bounds {
    NSSize sz = ((NSSize (*)(id, SEL, NSRect))objc_msgSend)(self, @selector(retro_segCellSizeForBounds:), bounds);
    if (![self respondsToSelector:@selector(segmentCount)]) return sz;
    NSInteger n = ((NSInteger (*)(id, SEL))objc_msgSend)(self, @selector(segmentCount));
    if (n <= 0) return sz;
    CGFloat content = 0; BOOL any = NO;
    for (NSInteger k = 0; k < n; k++) {
        double fw = retro_segFullWidthAt(self, k);
        if (fw > 0) { content += fw; any = YES; }
    }
    if (!any || content <= 0) return sz;
    sz.width = content + 4.0 + (CGFloat)(n - 1);
    return sz;
}

static NSRect retro_tiledSegRect(id cell, NSInteger seg, NSRect frame, BOOL *ok) {
    if (ok) *ok = NO;
    if (![cell respondsToSelector:@selector(segmentCount)]) return NSZeroRect;
    NSInteger n = ((NSInteger (*)(id, SEL))objc_msgSend)(cell, @selector(segmentCount));
    if (n <= 0 || n > 64 || seg < 0 || seg >= n) return NSZeroRect;
    CGFloat widths[64], total = 0;
    for (NSInteger k = 0; k < n; k++) {
        double fw = retro_segFullWidthAt(cell, k);
        if (fw <= 0) return NSZeroRect;
        widths[k] = (CGFloat)fw; total += widths[k];
    }
    CGFloat chrome = 4.0 + (CGFloat)(n - 1);
    CGFloat full = total + chrome;
    if (full <= 0) return NSZeroRect;
    CGFloat scale = (full > frame.size.width && frame.size.width > 0) ? frame.size.width / full : 1.0;
    CGFloat pos = frame.origin.x, prevEdge = round(pos);
    for (NSInteger k = 0; k < n; k++) {
        pos += (widths[k] + chrome / (CGFloat)n) * scale;
        CGFloat edge = round(pos);
        if (k == seg) { if (ok) *ok = YES; return NSMakeRect(prevEdge, frame.origin.y, edge - prevEdge, frame.size.height); }
        prevEdge = edge;
    }
    return NSZeroRect;
}

- (NSRect)retro_effectiveRectForSegment:(NSInteger)seg inFrame:(NSRect)frame {
    NSRect orig = [self retro_rectForSegment:seg inFrame:frame];
    if (![self respondsToSelector:@selector(segmentCount)]) return orig;
    NSInteger n = ((NSInteger (*)(id, SEL))objc_msgSend)(self, @selector(segmentCount));
    if (n <= 0 || seg < 0 || seg >= n) return orig;
    NSRect last = [self retro_rectForSegment:(n - 1) inFrame:frame];
    if (NSMaxX(last) <= NSMaxX(frame) + 0.5) return orig;
    BOOL ok = NO;
    NSRect r = retro_tiledSegRect(self, seg, frame, &ok);
    return ok ? r : orig;
}

- (NSRect)retro_rectForSegment:(NSInteger)seg inFrame:(NSRect)frame {
    return [self retro_effectiveRectForSegment:seg inFrame:frame];
}

- (BOOL)retro_isProSelectedForSegment:(NSInteger)seg {
    if ([self retro_isProSelectedForSegment:seg]) return YES;
    id ctl = [self respondsToSelector:@selector(controlView)] ? ((id (*)(id, SEL))objc_msgSend)(self, @selector(controlView)) : nil;
    if ([ctl respondsToSelector:@selector(isSelectedForSegment:)])
        return ((BOOL (*)(id, SEL, NSInteger))objc_msgSend)(ctl, @selector(isSelectedForSegment:), seg);
    return NO;
}

- (void)retro_drawSegment:(NSInteger)seg inFrame:(NSRect)frame withView:(NSView *)view {
    NSRect box = frame; BOOL tiled = NO;
    if ([view isKindOfClass:[NSView class]]) {
        box = [self retro_effectiveRectForSegment:seg inFrame:view.bounds];
        NSRect origSeg = [self retro_rectForSegment:seg inFrame:view.bounds];
        tiled = !NSEqualRects(box, origSeg);
    }
    CGFloat dx = tiled ? NSMidX(box) - NSMidX(frame) : 0.0;
    CGFloat dy = tiled ? NSMidY(box) - NSMidY(frame) : 0.0;
    if (fabs(dx) > 0.5 || fabs(dy) > 0.5) {
        [NSGraphicsContext saveGraphicsState];
        NSAffineTransform *tf = [NSAffineTransform transform];
        [tf translateXBy:dx yBy:dy];
        [tf concat];
        [self retro_drawSegment:seg inFrame:frame withView:view];
        [NSGraphicsContext restoreGraphicsState];
    } else {
        [self retro_drawSegment:seg inFrame:frame withView:view];
    }
    NSImage *img = [self respondsToSelector:@selector(imageForSegment:)] ?
        ((NSImage *(*)(id, SEL, NSInteger))objc_msgSend)(self, @selector(imageForSegment:), seg) : nil;
    if (![img isKindOfClass:[NSImage class]]) {
        NSString *label = [self respondsToSelector:@selector(labelForSegment:)] ?
            ((NSString *(*)(id, SEL, NSInteger))objc_msgSend)(self, @selector(labelForSegment:), seg) : nil;
        if ([label isKindOfClass:[NSString class]] && label.length) {
            NSDictionary *attrs = nil;
            if ([self respondsToSelector:@selector(_textAttributes)]) {
                id a = ((id (*)(id, SEL))objc_msgSend)(self, @selector(_textAttributes));
                if ([a isKindOfClass:[NSDictionary class]] && [(NSDictionary *)a count]) attrs = a;
            }
            if (!attrs) {
                NSFont *font = [self respondsToSelector:@selector(font)] ? ((NSFont *(*)(id, SEL))objc_msgSend)(self, @selector(font)) : nil;
                if (![font isKindOfClass:[NSFont class]]) {
                    NSControlSize cs = [self respondsToSelector:@selector(controlSize)] ?
                        ((NSControlSize (*)(id, SEL))objc_msgSend)(self, @selector(controlSize)) : NSControlSizeRegular;
                    font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:cs]];
                }
                BOOL enabled = [self respondsToSelector:@selector(isEnabled)] ? ((BOOL (*)(id, SEL))objc_msgSend)(self, @selector(isEnabled)) : YES;
                attrs = @{ NSFontAttributeName: font,
                           NSForegroundColorAttributeName: enabled ? [NSColor controlTextColor] : [NSColor disabledControlTextColor] };
            }
            NSSize ts = [label sizeWithAttributes:attrs];
            NSPoint p = NSMakePoint(round(NSMidX(box) - ts.width / 2.0), round(NSMidY(box) - ts.height / 2.0));
            [label drawAtPoint:p withAttributes:attrs];
        }
        return;
    }
    NSSize is = img.size;
    if (is.width < 1 || is.height < 1) return;
    NSRect r = NSIntegralRect(NSMakeRect(NSMidX(box) - is.width / 2.0,
                                         NSMidY(box) - is.height / 2.0, is.width, is.height));
    if (img.isTemplate) {
        [NSGraphicsContext saveGraphicsState];
        [img drawInRect:r fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0
         respectFlipped:YES hints:nil];
        [[NSColor controlTextColor] set];
        NSRectFillUsingOperation(r, NSCompositingOperationSourceAtop);
        [NSGraphicsContext restoreGraphicsState];
    } else {
        [img drawInRect:r fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0
         respectFlipped:YES hints:nil];
    }
}

static const CGFloat kRetroJustifyGap = 6.0;
static void retro_forceJustifyGaps(id alv, NSString *ivarName) {
    NSMapTable *map = nil;
    @try { map = [alv valueForKey:ivarName]; } @catch (...) { return; }
    if (![map respondsToSelector:@selector(keyEnumerator)]) return;
    NSMutableArray *keys = [NSMutableArray array];
    for (id k in [map keyEnumerator]) [keys addObject:k];
    for (id k in keys) {
        if (![k isKindOfClass:[NSView class]]) continue;
        if (((NSView *)k).autoresizingMask & NSViewWidthSizable) continue;
        NSValue *v = [map objectForKey:k];
        if (![v isKindOfClass:[NSValue class]]) continue;
        NSSize s = v.sizeValue;
        if (s.width != kRetroJustifyGap) {
            s.width = kRetroJustifyGap;
            [map setObject:[NSValue valueWithSize:s] forKey:k];
        }
    }
}
- (void)retro_recursiveSetFrame:(NSRect)frame level:(long long)level {
    retro_forceJustifyGaps(self, @"_rightJustifiedSubviewMargins");
    [self retro_recursiveSetFrame:frame level:level];
}

- (void)retro_vuDrawRect:(NSRect)dirty {
    NSView *v = (NSView *)self;
    CGFloat W = v.bounds.size.width;
    BOOL off = NO;
    for (NSView *c in v.subviews)
        if (!c.isHidden && (NSMinX(c.frame) < 0 || NSMaxX(c.frame) > W + 1)) { off = YES; break; }
    if (off && W > 1) {
        const CGFloat M = 7, G = 6;
        CGFloat lx = M, rx = W - M;
        for (NSView *c in v.subviews) {
            if (c.isHidden) continue;
            NSAutoresizingMaskOptions m = c.autoresizingMask;
            if ((m & NSViewMaxXMargin) && !(m & NSViewMinXMargin) && !(m & NSViewWidthSizable)) {
                NSRect f = c.frame; f.origin.x = lx; c.frame = f; lx += f.size.width + G;
            }
        }
        for (NSView *c in [v.subviews reverseObjectEnumerator]) {
            if (c.isHidden) continue;
            NSAutoresizingMaskOptions m = c.autoresizingMask;
            if ((m & NSViewMinXMargin) && !(m & NSViewWidthSizable)) {
                NSRect f = c.frame; f.origin.x = rx - f.size.width; c.frame = f; rx -= f.size.width + G;
            }
        }
        for (NSView *c in v.subviews) {
            if (c.isHidden) continue;
            if (c.autoresizingMask & NSViewWidthSizable) {
                NSRect f = c.frame; f.origin.x = lx + G; f.size.width = MAX(20, (rx - G) - (lx + G)); c.frame = f;
            }
        }
    }
    [self retro_vuDrawRect:dirty];
}

- (void)retro_updateSegmentItemConfiguration:(id)configuration {
    @try {
        NSArray *items = [self valueForKey:@"_segmentItems"];
        NSInteger idx = [configuration respondsToSelector:@selector(index)]
            ? ((NSInteger (*)(id, SEL))objc_msgSend)(configuration, @selector(index)) : -1;
        if (![items isKindOfClass:[NSArray class]] || idx < 0 || idx >= (NSInteger)items.count) return;
        [self retro_updateSegmentItemConfiguration:configuration];
    } @catch (NSException *exception) {
    }
}

- (BOOL)retro_acquireReservation {
    return YES;
}

- (NSModalResponse)retro_runModalSession:(NSModalSession)session {
    NSModalResponse response = [self retro_runModalSession:session];
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.005, true);
    return response;
}

- (BOOL)retro_isRestorable {
    return NO;
}

- (BOOL)retro_hasPersistentStateToRestore {
    return NO;
}

- (void)retro_invalidateCharacterCoordinates {
}

- (void)retro_proPopOrderOut:(int)animationStyle autorelease:(BOOL)autorel {
    [self retro_proPopOrderOut:animationStyle autorelease:autorel];
    NSWindow *w = (NSWindow *)self;
    if (![w isKindOfClass:[NSWindow class]]) return;
    double dur = 0.3;
    if ([self respondsToSelector:@selector(animationDuration)]) {
        double d = ((double (*)(id, SEL))objc_msgSend)(self, @selector(animationDuration));
        if (d > 0) dur = d;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((dur + 0.1) * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (w.isVisible && w.alphaValue <= 0.05) {
            [w orderOut:nil];
        }
    });
}

- (void)retro_winSetTitle:(NSString *)title {
    if ([title isKindOfClass:[NSString class]] && [title hasSuffix:@" (unboxed)"]) {
        title = [title substringToIndex:title.length - (NSUInteger)10];
    }
    [self retro_winSetTitle:title];
}

- (void)retro_proDrawTitleBar:(NSRect)rect {
    [self retro_proDrawTitleBar:rect];
    if (![self isKindOfClass:[NSView class]]) return;
    NSView *frame = (NSView *)self;
    NSString *title = frame.window.title;
    if (!title.length) return;
    for (NSView *s in frame.subviews) {
        if (!s.isHidden && [s isKindOfClass:[NSTextField class]] &&
            [((NSTextField *)s).stringValue isEqualToString:title]) {
            s.hidden = YES;
        }
    }
}

- (id)retro_facetInitWithCoder:(id)coder {
    id facet = [self retro_facetInitWithCoder:coder];
    if (!facet) return facet;
    Ivar iv = class_getInstanceVariable([facet class], "_themeIndex");
    unsigned long long *sentinel = (unsigned long long *)dlsym(RTLD_DEFAULT, "NSProZeroCodeAppTheme");
    if (iv && sentinel) {
        unsigned long long *slot = (unsigned long long *)((char *)facet + ivar_getOffset(iv));
        if (*slot == *sentinel && [facet respondsToSelector:@selector(instantiateWithObjectInstantiator:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(facet, @selector(instantiateWithObjectInstantiator:), nil);
        }
    }
    return facet;
}

@end
