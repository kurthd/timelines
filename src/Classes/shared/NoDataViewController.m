//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "NoDataViewController.h"
#import "RotatableTabBarController.h"
#import "SettingsReader.h"

@interface NoDataViewController ()

- (void)updateViewForOrientation:(UIInterfaceOrientation)o;

@end

@implementation NoDataViewController

- (void)dealloc {
    [label release];
    [activityIndicator release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        label.textColor = [UIColor whiteColor];
        label.shadowColor = [UIColor blackColor];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateViewForOrientation:
        [[RotatableTabBarController instance] effectiveOrientation]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)o
    duration:(NSTimeInterval)duration
{
    [self updateViewForOrientation:o];
}

- (void)updateViewForOrientation:(UIInterfaceOrientation)o
{
    CGFloat labelX;
    CGFloat activityIndicatorX;
    CGFloat labelY;
    CGFloat activityIndicatorY;
    if (o == UIInterfaceOrientationPortrait ||
        o == UIInterfaceOrientationPortraitUpsideDown) {

        labelX = 21;
        labelY = 132;
        activityIndicatorX = 142;
        activityIndicatorY = 87;
    } else {
        labelX = 105;
        labelY = 92;
        activityIndicatorX = 222;
        activityIndicatorY = 47;
    }

    CGRect labelFrame = label.frame;
    labelFrame.origin.y = labelY;
    labelFrame.origin.x = labelX;
    label.frame = labelFrame;

    CGRect activityIndicatorFrame = activityIndicator.frame;
    activityIndicatorFrame.origin.y = activityIndicatorY;
    activityIndicatorFrame.origin.x = activityIndicatorX;
    activityIndicator.frame = activityIndicatorFrame;
}

- (void)setLabelText:(NSString *)text
{
    label.text = text;
}

- (void)startAnimatingActivityIndicator
{
    [activityIndicator startAnimating];
}

- (void)stopAnimatingActivityIndicator
{
    [activityIndicator stopAnimating];
}

@end
