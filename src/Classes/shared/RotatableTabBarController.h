//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RotatableTabBarController : UITabBarController
{
    IBOutlet UIView * homeTitleView;

    // This is set as soon as the interface starts to change, instead of after
    // it finishes animating
    UIInterfaceOrientation effectiveOrientation;
}

@property (nonatomic, readonly) UIInterfaceOrientation effectiveOrientation;
- (BOOL)landscape;

+ (RotatableTabBarController *)instance;

@end
