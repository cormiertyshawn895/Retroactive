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

// ---------------------------------------------------------------------------
// Fix 3: error 13021 / 13026 when iTunes has to create a new library
// (first launch, or no "iTunes Library.itl" in the library folder).
// iTunes keys its .itdb SQLite databases with sqlite3_key() and attaches them
// with "ATTACH DATABASE ... KEY X'...'". Recent macOS ships libsqlite3 without
// encryption support: sqlite3_key() is a stub returning SQLITE_MISUSE (21), and
// ATTACH ... KEY on an existing database fails with SQLITE_NOTADB (26). iTunes
// turns these into errors 13021 / 13026 and stops before writing the .itl.
// Only when this macOS lacks encryption support: report sqlite3_key() as
// success and drop the KEY clause from ATTACH, so the databases are used
// unencrypted (the only thing this libsqlite3 can do anyway).
// ---------------------------------------------------------------------------
#include <sqlite3.h>
int sqlite3_key(sqlite3 *db, const void *key, int nKey);

static BOOL ITF_sqliteKeyUnsupported(void) {
    static BOOL unsupported;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sqlite3 *db = NULL;
        if (sqlite3_open(":memory:", &db) == SQLITE_OK) {
            unsupported = (sqlite3_key(db, "probe", 5) == SQLITE_MISUSE);
        }
        if (db) sqlite3_close(db);
        if (unsupported) os_log(OS_LOG_DEFAULT, "ITunesTahoeFix: libsqlite3 has no encryption support, using unencrypted iTunes databases");
    });
    return unsupported;
}

static int ITF_sqlite3_key(sqlite3 *db, const void *key, int nKey) {
    int rc = sqlite3_key(db, key, nKey);
    if (rc == SQLITE_MISUSE && ITF_sqliteKeyUnsupported()) return SQLITE_OK;
    return rc;
}

// "ATTACH DATABASE "path" AS name KEY X'hex'" -> "ATTACH DATABASE "path" AS name"
static int ITF_sqlite3_exec(sqlite3 *db, const char *sql, int (*cb)(void *, int, char **, char **), void *arg, char **err) {
    if (sql && strncasecmp(sql, "ATTACH", 6) == 0 && ITF_sqliteKeyUnsupported()) {
        const char *k = strstr(sql, " KEY X'");
        if (k) {
            const char *end = strchr(k + 7, '\'');
            if (end) {
                size_t head = (size_t)(k - sql);
                char *copy = malloc(strlen(sql) + 1);
                if (copy) {
                    memcpy(copy, sql, head);
                    strcpy(copy + head, end + 1);
                    int rc = sqlite3_exec(db, copy, cb, arg, err);
                    free(copy);
                    return rc;
                }
            }
        }
    }
    return sqlite3_exec(db, sql, cb, arg, err);
}

__attribute__((used, section("__DATA,__interpose")))
static struct { const void *replacement; const void *original; } ITF_interpose_sqlite[] = {
    { (const void *)ITF_sqlite3_key,  (const void *)sqlite3_key },
    { (const void *)ITF_sqlite3_exec, (const void *)sqlite3_exec },
};
