//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "RotatableTabBarController.h"

@implementation RotatableTabBarController

static RotatableTabBarController * gInstance = NULL;

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

// - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)o
// {
//     CGFloat homeTitleWidth;
//     if (o == UIInterfaceOrientationPortrait ||
//         o == UIInterfaceOrientationPortraitUpsideDown)
//         homeTitleWidth = 181;
//     else
//         homeTitleWidth = 250;
// 
//     CGRect homeTitleViewFrame = homeTitleView.frame;
//     homeTitleViewFrame.size.width = homeTitleWidth;
//     homeTitleView.frame = homeTitleViewFrame;
// 
//     return YES;
// }

@end
