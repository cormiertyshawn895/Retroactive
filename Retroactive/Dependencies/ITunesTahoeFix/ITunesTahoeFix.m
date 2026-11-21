// ITunesTahoeFix — compatibility shim for iTunes 12.9.5 on macOS 26 (Tahoe).
//
// -[ITNSButton dealloc] calls setters (setSecondaryIconImage:, ...) that call
// -[ITNSButton setupDrawingCell] -> -[NSButton setCell:]. On Tahoe, AppKit's
// NSButtonAppearanceBasedVisualProvider stores a weak reference to the button,
// which the ObjC runtime refuses (fatal) for an object being deallocated.
// Fix: skip setupDrawingCell while the button is deallocating.
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <os/log.h>

@interface NSObject (ITPrivate)
- (BOOL)_isDeallocating;
@end

static IMP gOrigSetup;

static void ITF_setupDrawingCell(id self, SEL _cmd) {
    if ([self respondsToSelector:@selector(_isDeallocating)] && [self _isDeallocating]) {
        return; // button is going away; rebuilding its cell is pointless and fatal on Tahoe
    }
    ((void (*)(id, SEL))gOrigSetup)(self, _cmd);
}

__attribute__((constructor))
static void ITF_init(void) {
    Class cls = objc_getClass("ITNSButton");
    Method m = cls ? class_getInstanceMethod(cls, sel_registerName("setupDrawingCell")) : NULL;
    if (!m) {
        os_log(OS_LOG_DEFAULT, "ITunesTahoeFix: ITNSButton/setupDrawingCell not found, inactive");
        return;
    }
    gOrigSetup = method_setImplementation(m, (IMP)ITF_setupDrawingCell);
    os_log(OS_LOG_DEFAULT, "ITunesTahoeFix: patched -[ITNSButton setupDrawingCell]");
}

// ---------------------------------------------------------------------------
// Fix 2: silently dismiss the startup "An unknown error occurred (-42408)."
// dialog (iTunes Store / Apple ID auth failure on Tahoe; harmless).
// Only dialogs whose text contains "(-42408)" are affected; every other
// iTunes dialog is shown normally.
// ---------------------------------------------------------------------------
static IMP gOrigDoModal;

static BOOL ITF_viewContainsText(NSView *v, NSString *needle) {
    if ([v isKindOfClass:[NSTextField class]] &&
        [[(NSTextField *)v stringValue] rangeOfString:needle].location != NSNotFound) return YES;
    if ([v isKindOfClass:[NSTextView class]] &&
        [[(NSTextView *)v string] rangeOfString:needle].location != NSNotFound) return YES;
    for (NSView *sub in v.subviews) if (ITF_viewContainsText(sub, needle)) return YES;
    return NO;
}

static NSWindow *ITF_dialogWindow(id self) {
    unsigned n = 0;
    Ivar *ivars = class_copyIvarList([self class], &n);
    NSWindow *w = nil;
    for (unsigned i = 0; i < n && !w; i++) {
        const char *t = ivar_getTypeEncoding(ivars[i]);
        if (t && t[0] == '@') {
            id val = object_getIvar(self, ivars[i]);
            if ([val isKindOfClass:[NSWindow class]]) w = val;
        }
    }
    free(ivars);
    return w;
}

static NSButton *ITF_findOKButton(NSWindow *w) {
    NSView *cv = w.defaultButtonCell.controlView;
    if ([cv isKindOfClass:[NSButton class]]) return (NSButton *)cv;
    NSMutableArray *stack = [NSMutableArray arrayWithObject:w.contentView];
    NSButton *only = nil; int count = 0;
    while (stack.count) {
        NSView *v = stack.lastObject; [stack removeLastObject];
        if ([v isKindOfClass:[NSButton class]] && !v.isHidden) {
            NSButton *b = (NSButton *)v;
            if ([b.keyEquivalent isEqualToString:@"\r"]) return b;
            only = b; count++;
        }
        [stack addObjectsFromArray:v.subviews];
    }
    return count == 1 ? only : nil;
}

static NSInteger ITF_doModal(id self, SEL _cmd) {
    NSWindow *w = ITF_dialogWindow(self);
    if (w && ITF_viewContainsText(w.contentView, @"(-42408)")) {
        // Do what -[CocoaDialogUtilitiesController ok:] does (clearTouchBar, doAction:,
        // then stopModalWithCode:[sender tag]) but without ever running the modal
        // loop, so nothing appears on screen. doModal returns that tag.
        NSButton *okButton = ITF_findOKButton(w);
        if (okButton) {
            if ([self respondsToSelector:sel_registerName("clearTouchBar")])
                ((void (*)(id, SEL))objc_msgSend)(self, sel_registerName("clearTouchBar"));
            ((void (*)(id, SEL, id))objc_msgSend)(self, sel_registerName("doAction:"), okButton);
            [w orderOut:nil];
            os_log(OS_LOG_DEFAULT, "ITunesTahoeFix: dismissed -42408 dialog silently (tag %ld)", (long)okButton.tag);
            return okButton.tag;
        }
        // Fallback: show invisibly and auto-click once the modal loop is running.
        os_log(OS_LOG_DEFAULT, "ITunesTahoeFix: -42408 fallback path");
        w.alphaValue = 0.0;
        CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
            NSButtonCell *def = w.defaultButtonCell;
            if (def) [def performClick:nil]; else [NSApp stopModal];
        });
        CFRunLoopWakeUp(CFRunLoopGetMain());
    }
    return ((NSInteger (*)(id, SEL))gOrigDoModal)(self, _cmd);
}

__attribute__((constructor))
static void ITF_init2(void) {
    Class cls = objc_getClass("CocoaDialogUtilitiesController");
    Method m = cls ? class_getInstanceMethod(cls, sel_registerName("doModal")) : NULL;
    if (!m) { os_log(OS_LOG_DEFAULT, "ITunesTahoeFix: doModal not found, -42408 fix inactive"); return; }
    gOrigDoModal = method_setImplementation(m, (IMP)ITF_doModal);
    os_log(OS_LOG_DEFAULT, "ITunesTahoeFix: patched -[CocoaDialogUtilitiesController doModal]");
}
