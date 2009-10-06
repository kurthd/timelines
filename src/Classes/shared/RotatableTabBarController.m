//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "RotatableTabBarController.h"

@implementation RotatableTabBarController

static RotatableTabBarController * gInstance = NULL;

@synthesize effectiveOrientation;

+ (RotatableTabBarController *)instance
{
    return gInstance;
}

- (void)viewDidLoad
{
    gInstance = self;
}

- (void)dealloc
{
    [homeTitleView release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)o
{
    effectiveOrientation = o;

    CGFloat homeTitleWidth;
    if (o == UIInterfaceOrientationPortrait ||
        o == UIInterfaceOrientationPortraitUpsideDown)
        homeTitleWidth = 181;
    else
        homeTitleWidth = 250;

    CGRect homeTitleViewFrame = homeTitleView.frame;
    homeTitleViewFrame.size.width = homeTitleWidth;
    homeTitleView.frame = homeTitleViewFrame;

    return YES;
}

// - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)o
// {
//     return o == UIInterfaceOrientationPortrait ||
//         o == UIInterfaceOrientationPortraitUpsideDown;
// }

- (BOOL)landscape
{
    return effectiveOrientation == UIInterfaceOrientationLandscapeLeft ||
        effectiveOrientation == UIInterfaceOrientationLandscapeRight;
}

@end
