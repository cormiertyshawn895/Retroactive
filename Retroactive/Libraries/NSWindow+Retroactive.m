#import "NSWindow+Retroactive.h"

@interface NSWindow (Private)
- (void)_setPreventsActivation:(bool)preventsActivation;
@end

@implementation NSWindow (Retroactive)

- (void)ret_setPreventsActivation:(bool)preventsActivation {
    if ([self respondsToSelector:@selector(_setPreventsActivation:)]) {
        [self _setPreventsActivation:preventsActivation];
    }
}

@end
