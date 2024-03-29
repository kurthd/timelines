
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "NetworkAwareViewController.h"
#import "UIColor+TwitchColors.h"

@interface NetworkAwareViewController (Private)

- (NoDataViewController *)noDataViewController;
- (void)updateView;
- (UIView *)updatingView;
- (void)addUpdatingViewAsSubview;
- (void)removeUpdatingViewFromSuperview;
- (void)resetUpdatingView;
- (BOOL)targetViewIsDisplayed;
- (void)showTargetView;
- (void)showNoDataView;

- (CGRect)shownUpdatingViewFrame;
- (CGRect)hiddenUpdatingViewFrame;
- (CGFloat)y;
- (CGFloat)leftUpdatingViewMargin;
- (CGFloat)screenWidth;
- (CGFloat)viewLength;
- (CGFloat)viewHeight;

@end

static const CGFloat ACTIVITY_INDICATOR_LENGTH = 20;

@implementation NetworkAwareViewController

@synthesize delegate, targetViewController, cachedDataAvailable,
    transparentUpdatingViewEnabled;

- (void)dealloc
{
    [delegate release];

    [targetViewController release];
    [noDataViewController release];

    [updatingText release];
    [loadingText release];
    [noConnectionText release];

    [updatingView release];

    [super dealloc];
}

- (void)awakeFromNib
{
    [self initWithTargetViewController:targetViewController];
}

- (id)init
{
    return [self initWithTargetViewController:nil];
}

- (id)initWithTargetViewController:(UIViewController *)aTargetViewController
{
    if (self = [super init]) {
        CGRect frame = CGRectMake(0, 0, 320, 416);
        self.view = [[UIView alloc] initWithFrame:frame];

        [self noDataViewController].view.backgroundColor =
            [UIColor twitchBackgroundColor];

        [self setUpdatingText:NSLocalizedString(@"nodata.updating.text", @"")];
        [self setLoadingText:NSLocalizedString(@"nodata.loading.text", @"")];
        NSString * tempNoConnectionText =
            NSLocalizedString(@"nodata.noconnection.text", @"");
        [self setNoConnectionText:tempNoConnectionText];

        [aTargetViewController retain];
        [targetViewController release];
        targetViewController = aTargetViewController;

        transparentUpdatingViewEnabled = NO;
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.view.frame = CGRectMake(0, 0, 320, 416);

    if ([self targetViewIsDisplayed])
        [targetViewController viewWillAppear:animated];
    else
        [noDataViewController viewWillAppear:animated];

    if ([delegate respondsToSelector:@selector(networkAwareViewWillAppear)])
        [delegate networkAwareViewWillAppear];

    [self resetUpdatingView];
    // yep
    [self performSelector:@selector(resetUpdatingView) withObject:nil
        afterDelay:0];

    // This enables putting view controllers on the 'more' tab, makes room for
    // a back button
    if (self.navigationController &&
        [self.navigationController.viewControllers count] > 1) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    visible = YES;
    
    [self addUpdatingViewAsSubview];

    if ([self targetViewIsDisplayed])
        [targetViewController viewDidAppear:animated];
    else
        [noDataViewController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    visible = NO;
    [self removeUpdatingViewFromSuperview];

    if ([delegate respondsToSelector:@selector(networkAwareViewWillDisappear)])
        [delegate networkAwareViewWillDisappear];

    if ([self targetViewIsDisplayed])
        [targetViewController viewWillDisappear:animated];
    else
        [noDataViewController viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if ([self targetViewIsDisplayed])
        [targetViewController viewDidDisappear:animated];
    else
        [noDataViewController viewDidDisappear:animated];
}

- (void)resetUpdatingView
{
    [self updatingView].frame =
        updatingState == kConnectedAndUpdating && cachedDataAvailable ?
        [self shownUpdatingViewFrame] : [self hiddenUpdatingViewFrame];
    [self updatingView].hidden = NO;
}

#pragma mark State updating methods

- (void)setUpdatingState:(NSInteger)state
{
    updatingState = state;
    [self updateView];
}

- (void)setCachedDataAvailable:(BOOL)available
{
    // Not sure why, but setting the following seems to fix a bug where the
    // 'updating' view won't reappear as expected
    // Leaving the code structure in place for now in case it needs to be
    // reversed
    BOOL transitioningToAvailable = YES;
    // !cachedDataAvailable && available && ![[self updatingView] superview];
    cachedDataAvailable = available;
    [self updateView];
    if (transitioningToAvailable && visible) {
        NSLog(@"Showing updating view");
        [self addUpdatingViewAsSubview];
    }
}

- (void)setUpdatingText:(NSString *)text
{
    text = [text copy];
    [updatingText release];
    updatingText = text;
    
    [self updateView];
}

- (void)setLoadingText:(NSString *)text
{
    text = [text copy];
    [loadingText release];
    loadingText = text;
    
    [self updateView];
}

- (void)setNoConnectionText:(NSString *)text
{
    text = [text copy];
    [noConnectionText release];
    noConnectionText = text;
    
    [self updateView];
}

#pragma mark Private helper methods

- (NoDataViewController *)noDataViewController
{    
    if (!noDataViewController)
        noDataViewController =
            [[NoDataViewController alloc] initWithNibName:@"NoDataView"
            bundle:nil];
    
    return noDataViewController;
}

- (void)updateView
{
    // set view
    if (cachedDataAvailable && ![self targetViewIsDisplayed]) {
        [self showTargetView];
        [targetViewController viewWillAppear:YES];
    } else if (!cachedDataAvailable) {
        [self showNoDataView];

        // this seems to get overwritten on the device occasionally, so force
        // it here
        [self noDataViewController].view.backgroundColor =
            [UIColor twitchBackgroundColor];

        // set no data text
        NSString * labelText =
            updatingState == kDisconnected ? noConnectionText : loadingText;
        [[self noDataViewController] setLabelText:labelText];
    }

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:self.updatingView cache:NO];

    // position updating view
    if (cachedDataAvailable && updatingState == kConnectedAndUpdating) {
        NSLog(@"Showing the updating view");
        self.updatingView.frame = [self shownUpdatingViewFrame];
    } else
        self.updatingView.frame = [self hiddenUpdatingViewFrame];

    [UIView commitAnimations];

    // set no data activity indicator animation state
    if (updatingState == kDisconnected)
        [[self noDataViewController] stopAnimatingActivityIndicator];
    else
        [[self noDataViewController] startAnimatingActivityIndicator];
}

- (UIView *)updatingView
{
    if (!updatingView) {
        updatingView =
            [[UIView alloc]
            initWithFrame:[self hiddenUpdatingViewFrame]];
        updatingView.backgroundColor =
            [[UIColor blackColor] colorWithAlphaComponent:0.7];

        CGRect labelFrame =
            CGRectMake([self viewHeight], 0,
            [self viewLength] - [self viewHeight], [self viewHeight]);
        UILabel * updatingLabel = [[UILabel alloc] initWithFrame:labelFrame];
        updatingLabel.text = updatingText;
        updatingLabel.textColor = [UIColor whiteColor];
        updatingLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        updatingLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        updatingLabel.font = [UIFont boldSystemFontOfSize:18];
        updatingLabel.shadowOffset = CGSizeMake(0, 1);
        updatingLabel.shadowColor = [UIColor blackColor];
        [updatingView addSubview:updatingLabel];

        CGRect darkLineFrame = CGRectMake(0, 0, 320, 1);
        UIView * darkLine =
            [[[UIView alloc] initWithFrame:darkLineFrame] autorelease];
        darkLine.backgroundColor =
            [[UIColor blackColor] colorWithAlphaComponent:0.4];
        [updatingView addSubview:darkLine];

        CGRect lightLineFrame = CGRectMake(0, 1, 320, 1);
        UIView * lightLine =
            [[[UIView alloc] initWithFrame:lightLineFrame] autorelease];
        lightLine.backgroundColor =
            [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        [updatingView addSubview:lightLine];

        const CGFloat ACTIVITY_INDICATOR_MARGIN =
            ([self viewHeight] - ACTIVITY_INDICATOR_LENGTH) / 2;
        CGRect activityIndicatorFrame =
            CGRectMake(ACTIVITY_INDICATOR_MARGIN, ACTIVITY_INDICATOR_MARGIN, 20,
            20);
        UIActivityIndicatorView * activityIndicator =
            [[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicator.frame = activityIndicatorFrame;
        [activityIndicator startAnimating];
        [updatingView addSubview:activityIndicator];
    }

    return updatingView;
}

- (void)addUpdatingViewAsSubview
{
    if (transparentUpdatingViewEnabled) {
        NSLog(@"Adding updating view as subview");
        [targetViewController.view.superview addSubview:[self updatingView]];
    }
}

- (void)removeUpdatingViewFromSuperview
{
    NSLog(@"Removing updating view from superview");
    [[self updatingView] removeFromSuperview];
}

- (BOOL)targetViewIsDisplayed
{
    return self.view == targetViewController.view.superview;
}

- (void)showTargetView
{
    [targetViewController.view removeFromSuperview];
    [[[self noDataViewController] view] removeFromSuperview];
    [self.view addSubview:targetViewController.view];
}

- (void)showNoDataView
{
    [targetViewController.view removeFromSuperview];
    [[[self noDataViewController] view] removeFromSuperview];
    [self.view addSubview:[[self noDataViewController] view]];
}

#pragma mark Static helper methods

- (CGRect)shownUpdatingViewFrame
{
    return CGRectMake([self leftUpdatingViewMargin], [self y],
        [self viewLength], [self viewHeight]);
}

- (CGRect)hiddenUpdatingViewFrame
{
    return CGRectMake([self leftUpdatingViewMargin],
        [self y] + [self viewHeight], [self viewLength], [self viewHeight]);
}

- (CGFloat)leftUpdatingViewMargin
{
    return ([self screenWidth] - [self viewLength]) / 2;
}

- (CGFloat)y
{
    return 190;
}

- (CGFloat)screenWidth
{
    return 480;
}

- (CGFloat)viewLength
{
    return 480;
}

- (CGFloat)viewHeight
{
    return 30;
}

@end
