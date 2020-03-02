#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSWindow (Retroactive)

- (void)ret_setPreventsActivation:(bool)preventsActivation;

@end

NS_ASSUME_NONNULL_END
