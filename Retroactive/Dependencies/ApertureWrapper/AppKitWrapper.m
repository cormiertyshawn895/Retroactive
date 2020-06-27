@import Foundation;
@import AppKit;

extern @interface NSFlippableView : NSView {
}
@end

@implementation NSFlippableView
@end

extern @interface NSToolbarClippedItemsIndicator : NSView {
}
@end

@implementation NSToolbarClippedItemsIndicator
+ (void)setCellClass:(id)setCellClass {
    NSLog(@"Don't set cell class");
}
@end
