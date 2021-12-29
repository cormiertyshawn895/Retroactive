//
//  NSTextFieldCell+iWorkFixer.m
//  KeynoteFixer
//
//  Created by Tyshawn on 4/26/20.
//  Copyright © 2020 Tyshawn Cormier. All rights reserved.
//

#import "NSTextFieldCell+iWorkFixer.h"

@implementation NSTextFieldCell (iWorkFixer)

- (void)setFrame:(NSRect)frame {
    NSLog(@"No-oping setFrame in NSTextFieldCell: %@", NSStringFromRect(frame));
}

- (void)setHidden:(BOOL)hidden {
    NSLog(@"No-oping setHidden in NSTextFieldCell: %d", hidden);
}

- (id)_vibrantBlendingStyleForSubtree {
    NSLog(@"Return nil for _vibrantBlendingStyleForSubtree in NSTextFieldCell");
    return nil;
}

@end
