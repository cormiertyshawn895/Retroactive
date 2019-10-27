//
//  Created by Frank Gregor on 10.01.15.
//  Copyright (c) 2015 cocoa:naut. All rights reserved.
//
//  Initial idea has been adapted from BFNavigationController, but with some improvements.
//  @see: https://github.com/bfolder/BFNavigationController/blob/master/BFNavigationController/BFNavigationController.m

/*
 The MIT License (MIT)
 Copyright © 2016 Frank Gregor, <phranck@cocoanaut.com>
 http://cocoanaut.mit-license.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the “Software”), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <objc/runtime.h>
#import "CCNNavigationController.h"

NSString *const CCNNavigationControllerWillShowViewControllerNotification = @"CCNNavigationControllerWillShowViewControllerNotification";
NSString *const CCNNavigationControllerDidShowViewControllerNotification = @"CCNNavigationControllerDidShowViewControllerNotification";
NSString *const CCNNavigationControllerWillPopViewControllerNotification = @"CCNNavigationControllerWillPopViewControllerNotification";
NSString *const CCNNavigationControllerDidPopViewControllerNotification = @"CCNNavigationControllerDidPopViewControllerNotification";

NSString *const CCNNavigationControllerNotificationUserInfoKey = @"viewController";


@interface CCNNavigationController () {
    NSMutableArray *_viewControllers;
}
@end

@implementation CCNNavigationController

#pragma mark - Creating Navigation Controllers

- (instancetype)initWithRootViewController:(__kindof NSViewController *)viewController {
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;

    _delegate = nil;
    _viewControllers = [NSMutableArray array];

    if (!viewController) {
        viewController = [[NSViewController alloc] init];
        viewController.view = [[NSView alloc] initWithFrame:NSZeroRect];
    }

    NSRect viewControllerFrame = viewController.view.bounds;

    [_viewControllers addObject:viewController];

    self.view = [[NSView alloc] initWithFrame:viewControllerFrame];
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.view.wantsLayer = YES;

    // setup configuration
    self.configuration = [CCNNavigationControllerConfiguration defaultConfiguration];
    self.backgroundColor = [NSColor clearColor];

    // inject navigation controller
    if ([viewController respondsToSelector:@selector(setNavigationController:)]) {
        [viewController performSelector:@selector(setNavigationController:) withObject:self];
    }

    [self.view addSubview:viewController.view];
    viewController.view.translatesAutoresizingMaskIntoConstraints = self.view.translatesAutoresizingMaskIntoConstraints;
    viewController.view.autoresizingMask = self.view.autoresizingMask;
    viewController.view.wantsLayer = self.view.wantsLayer;

    // Initial controller will appear on startup
    if ([viewController respondsToSelector:@selector(viewWillAppear:)]) {
        [(id<CCNViewController>)viewController viewWillAppear:NO];
    }

    return self;
}

#pragma mark - Pushing and Popping Stack Items

- (void)setViewControllers:(NSArray<__kindof NSViewController *> *)viewControllers {
    [self setViewControllers:viewControllers animated:NO];
}

- (void)setViewControllers:(NSArray<__kindof NSViewController *> *)viewControllers animated:(BOOL)animated {
    NSViewController *currentVisibleController = self.visibleViewController;
    NSViewController *newVisibleController = [viewControllers lastObject];

    BOOL push = !([_viewControllers containsObject:newVisibleController] && [_viewControllers indexOfObject:newVisibleController] < [_viewControllers count] - 1);
    _viewControllers = [viewControllers mutableCopy];

    for (NSViewController *viewController in _viewControllers) {
        if ([viewController respondsToSelector:@selector(setNavigationController:)]) {
            [viewController performSelector:@selector(setNavigationController:) withObject:self];
        }
    }

    [self _transitionFromViewController:currentVisibleController toViewController:newVisibleController animated:animated push:push];
}

- (void)pushViewController:(__weak __kindof NSViewController *)viewController animated:(BOOL)animated {
    NSViewController *visibleViewController = self.visibleViewController;
    [_viewControllers addObject:viewController];

    [self _transitionFromViewController:visibleViewController toViewController:viewController animated:animated push:YES];
}

- (__kindof NSViewController *)popViewControllerAnimated:(BOOL)animated {
    if ([_viewControllers count] == 1) return nil;

    NSViewController *visibleViewController = self.visibleViewController;
    [_viewControllers removeLastObject];

    [self _transitionFromViewController:visibleViewController toViewController:_viewControllers.lastObject animated:animated push:NO];

    return visibleViewController;
}

- (NSArray<__kindof NSViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    NSViewController *rootController = _viewControllers.firstObject;
    [_viewControllers removeObject:rootController];

    NSArray<NSViewController *> *poppedViewControllers = [NSArray arrayWithArray:_viewControllers];
    _viewControllers = [NSMutableArray arrayWithObject:rootController];

    for (NSViewController *aViewController in poppedViewControllers) {
        if ([aViewController respondsToSelector:@selector(setNavigationController:)]) {
            [aViewController performSelector:@selector(setNavigationController:) withObject:nil];
        }
    }

    [self _transitionFromViewController:poppedViewControllers.lastObject toViewController:rootController animated:animated push:NO];

    return poppedViewControllers;
}

- (NSArray<__kindof NSViewController *> *)popToViewController:(__kindof NSViewController *)viewController animated:(BOOL)animated {
    NSViewController *fromViewController = self.visibleViewController;

    if (![_viewControllers containsObject:viewController] || fromViewController == viewController) {
        return [NSArray array];
    }

    NSUInteger index = [_viewControllers indexOfObject:viewController] + 1;
    NSUInteger length = [_viewControllers count] - index;
    NSRange range = NSMakeRange(index, length);
    NSArray *poppedViewControllers = [_viewControllers subarrayWithRange:range];
    [_viewControllers removeObjectsInArray:poppedViewControllers];

    for (NSViewController *aViewController in poppedViewControllers) {
        if ([aViewController respondsToSelector:@selector(setNavigationController:)]) {
            [aViewController performSelector:@selector(setNavigationController:) withObject:nil];
        }
    }

    [self _transitionFromViewController:fromViewController toViewController:viewController animated:animated push:NO];

    return poppedViewControllers;
}

- (void)_transitionFromViewController:(__kindof NSViewController *)current toViewController:(__kindof NSViewController *)next animated:(BOOL)animated push:(BOOL)push {

    // inject navigation controller
    if ([next respondsToSelector:@selector(setNavigationController:)]) {
        [next performSelector:@selector(setNavigationController:) withObject:self];
    }

    // call the delegate and push a notification
    [self navigationController:self willPopViewController:current animated:animated];
    [self navigationController:self willShowViewController:next animated:animated];

    if ([next respondsToSelector:@selector(viewWillAppear:)]) {
        [(id<CCNViewController>)next viewWillAppear:animated];
    }

    if ([current respondsToSelector:@selector(viewWillDisappear:)]) {
        [(id<CCNViewController>)current viewWillDisappear:animated];
    }

    NSRect bounds = self.view.bounds;
    NSRect nextStartFrame = bounds;
    NSRect nextEndFrame = bounds;
    NSRect currentEndFrame = bounds;

    [self.view addSubview:next.view];
    next.view.translatesAutoresizingMaskIntoConstraints = YES;
    next.view.autoresizingMask = self.view.autoresizingMask;
    next.view.wantsLayer = YES;

    CCNNavigationControllerTransition transition = self.configuration.transition;
    CCNNavigationControllerTransitionStyle transitionStyle = self.configuration.transitionStyle;

    // default animation group
    void (^animationGroup)(NSAnimationContext *context) = nil;

    switch (transitionStyle) {
        case CCNNavigationControllerTransitionStyleShift: {
            switch (transition) {
                case CCNNavigationControllerTransitionToLeft: {
                    currentEndFrame.origin.x = (push ? -NSWidth(bounds) : NSWidth(bounds));
                    nextStartFrame.origin.x = (push ? NSWidth(bounds) : -NSWidth(bounds));
                    break;
                }
                case CCNNavigationControllerTransitionToRight: {
                    currentEndFrame.origin.x = (push ? NSWidth(bounds) : -NSWidth(bounds));
                    nextStartFrame.origin.x = (push ? -NSWidth(bounds) : NSWidth(bounds));
                    break;
                }
                case CCNNavigationControllerTransitionToDown: {
                    currentEndFrame.origin.y = (push ? -NSHeight(bounds) : NSHeight(bounds));
                    nextStartFrame.origin.y = (push ? NSHeight(bounds) : -NSHeight(bounds));
                    break;
                }
                case CCNNavigationControllerTransitionToUp: {
                    currentEndFrame.origin.y = (push ? NSHeight(bounds) : -NSHeight(bounds));
                    nextStartFrame.origin.y = (push ? -NSHeight(bounds) : NSHeight(bounds));
                    break;
                }
            }
            animationGroup = ^(NSAnimationContext *context) {
                context.duration = (animated ? self.configuration.transitionDuration : 0);
                context.timingFunction = self.configuration.mediaTimingFunction;
                
                [[current.view animator] setFrame:currentEndFrame];
                [[next.view animator] setFrame:nextEndFrame];
            };
            break;
        }
            
        case CCNNavigationControllerTransitionStyleStack: {
            switch (transition) {
                case CCNNavigationControllerTransitionToLeft: {
                    currentEndFrame.origin.x = (push ? NSMinX(bounds) : NSWidth(bounds));
                    nextStartFrame.origin.x = (push ? NSWidth(bounds) : NSMinX(bounds));
                    break;
                }
                case CCNNavigationControllerTransitionToRight: {
                    currentEndFrame.origin.x = (push ? NSMinX(bounds) : -NSWidth(bounds));
                    nextStartFrame.origin.x = (push ? -NSWidth(bounds) : NSMinX(bounds));
                    break;
                }
                case CCNNavigationControllerTransitionToDown: {
                    currentEndFrame.origin.y = (push ? NSMinY(bounds) : NSHeight(bounds));
                    nextStartFrame.origin.y = (push ? NSHeight(bounds) : NSMinY(bounds));
                    break;
                }
                case CCNNavigationControllerTransitionToUp: {
                    currentEndFrame.origin.y = (push ? NSMinY(bounds) : -NSHeight(bounds));
                    nextStartFrame.origin.y = (push ? -NSHeight(bounds) : NSMinY(bounds));
                    break;
                }
            }
            
            [self.view bringSubViewToFront:(push ? next.view : current.view)];
            
            animationGroup = ^(NSAnimationContext *context) {
                context.duration = (animated ? self.configuration.transitionDuration : 0);
                context.timingFunction = self.configuration.mediaTimingFunction;
                
                [[current.view animator] setFrame:currentEndFrame];
                [[next.view animator] setFrame:nextEndFrame];
            };
            
            break;
        }
    }
    
    next.view.frame = nextStartFrame;
    
    __weak typeof(self) wSelf = self;
    [NSAnimationContext runAnimationGroup:animationGroup
                        completionHandler:^{
                            if ([next respondsToSelector:@selector(viewDidAppear:)]) {
                                [(id<CCNViewController>)next viewDidAppear:animated];
                            }
                            [self navigationController:wSelf didShowViewController:next animated:animated];
                            
                            [current.view removeFromSuperview];

                            // remove possible injected navigation controller
                            if ([current respondsToSelector:@selector(setNavigationController:)]) {
                                [current performSelector:@selector(setNavigationController:) withObject:nil];
                            }

                            if ([current respondsToSelector:@selector(viewDidDisappear:)]) {
                                [(id<CCNViewController>)current viewDidDisappear:animated];
                            }
                            [self navigationController:wSelf didPopViewController:current animated:animated];
                        }];
}

#pragma mark - Custom Accessors

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    self.view.layer.backgroundColor = backgroundColor.CGColor;
}

- (__kindof NSViewController *)topViewController {
    return self.viewControllers.lastObject;
}


- (__kindof NSViewController *)previousViewController {
    NSUInteger count = self.viewControllers.count;
    if (count < 2) {
        return nil;
    }
    return self.viewControllers[count - 2];
}

- (__kindof NSViewController *)visibleViewController {
    return self.viewControllers.lastObject;
}

- (NSArray<__kindof NSViewController *> *)viewControllers {
    return [NSArray arrayWithArray:_viewControllers];
}

#pragma mark - CCNNavigationControllerDelegate

- (void)navigationController:(CCNNavigationController *)navigationController willShowViewController:(__kindof NSViewController *)viewController animated:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:CCNNavigationControllerWillShowViewControllerNotification object:self userInfo:@{CCNNavigationControllerNotificationUserInfoKey : viewController}];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate navigationController:navigationController willShowViewController:viewController animated:animated];
    }
}

- (void)navigationController:(CCNNavigationController *)navigationController didShowViewController:(__kindof NSViewController *)viewController animated:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:CCNNavigationControllerDidShowViewControllerNotification object:self userInfo:@{CCNNavigationControllerNotificationUserInfoKey : viewController}];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

- (void)navigationController:(CCNNavigationController *)navigationController willPopViewController:(__kindof NSViewController *)viewController animated:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:CCNNavigationControllerWillPopViewControllerNotification object:self userInfo:@{CCNNavigationControllerNotificationUserInfoKey : viewController}];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate navigationController:navigationController willPopViewController:viewController animated:animated];
    }
}

- (void)navigationController:(CCNNavigationController *)navigationController didPopViewController:(__kindof NSViewController *)viewController animated:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:CCNNavigationControllerDidPopViewControllerNotification object:self userInfo:@{CCNNavigationControllerNotificationUserInfoKey : viewController}];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate navigationController:navigationController didPopViewController:viewController animated:animated];
    }
}

@end


// =====================================================================================================================
#pragma mark - NSView+CCNNavigationController
@implementation NSView (CCNNavigationController)
- (BOOL)hasSubView:(NSView *)theSubView {
    return [self.subviews containsObject:theSubView];
}

- (void)bringSubViewToFront:(NSView *)theSubView {
    if ([self hasSubView:theSubView]) {
        [theSubView removeFromSuperviewWithoutNeedingDisplay];
        [self addSubview:theSubView positioned:NSWindowAbove relativeTo:nil];
    }
}
@end



// =====================================================================================================================
#pragma mark - NSViewController+CCNNavigationController
@implementation NSViewController (CCNNavigationController)
- (CCNNavigationController *)navigationController {
    return objc_getAssociatedObject(self, @selector(navigationController));
}

- (void)setNavigationController:(CCNNavigationController *)navigationController {
    objc_setAssociatedObject(self, @selector(navigationController), navigationController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end



// =====================================================================================================================
#pragma mark - CCNNavigationControllerConfiguration
@implementation CCNNavigationControllerConfiguration

+ (instancetype)defaultConfiguration {
    return [[[self class] alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _backgroundColor     = [NSColor windowBackgroundColor];
    _transition          = CCNNavigationControllerTransitionToLeft;
    _transitionStyle     = CCNNavigationControllerTransitionStyleShift;
    _transitionDuration  = 0.35;
    _mediaTimingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    return self;
}

@end
