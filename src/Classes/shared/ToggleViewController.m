//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ToggleViewController.h"

@implementation ToggleViewController

@synthesize childController;

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(NSTimeInterval)duration
{
    [childController willRotateToInterfaceOrientation:orientation
        duration:duration];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [childController viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [childController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [childController viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [childController viewDidAppear:animated];
}

- (void)setChildController:(UIViewController *)aChildController
{
    CGRect frame = CGRectMake(0, 0, 320, 367);
    aChildController.view.frame = frame;

    [childController.view removeFromSuperview];

    [aChildController retain];
    [childController release];
    childController = aChildController;

    [childController viewWillAppear:NO];
    [self.view addSubview:childController.view];
    [childController viewDidAppear:NO];
}

@end
