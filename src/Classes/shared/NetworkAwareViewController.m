//
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

@synthesize delegate, targetViewController, cachedDataAvailable;

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
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.view == targetViewController.view)
        [targetViewController viewWillAppear:animated];
    [noDataViewController viewWillAppear:animated];

    if ([delegate respondsToSelector:@selector(networkAwareViewWillAppear)])
        [delegate networkAwareViewWillAppear];

    [self resetUpdatingView];
    // yep
    [self performSelector:@selector(resetUpdatingView) withObject:nil
        afterDelay:0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    visible = YES;

    [self addUpdatingViewAsSubview];

    if (self.view == targetViewController.view)
        [targetViewController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    visible = NO;
    [self removeUpdatingViewFromSuperview];

    if (self.view == targetViewController.view)
        [targetViewController viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(NSTimeInterval)duration
{
    [targetViewController willRotateToInterfaceOrientation:orientation
        duration:duration];
    [noDataViewController willRotateToInterfaceOrientation:orientation
        duration:duration];
    if ([delegate respondsToSelector:@selector(viewWillRotateToOrientation:)])
        [delegate viewWillRotateToOrientation:orientation];

    [self updatingView].hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    [targetViewController didRotateFromInterfaceOrientation:orientation];

    [self resetUpdatingView];
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
    if (cachedDataAvailable && self.view != targetViewController.view) {
        self.view = targetViewController.view;
        [targetViewController viewWillAppear:YES];
    } else if (!cachedDataAvailable) {
        self.view = [[self noDataViewController] view];

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
    if (cachedDataAvailable && updatingState == kConnectedAndUpdating)
        self.updatingView.frame = [self shownUpdatingViewFrame];
    else
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
    NSLog(@"Adding updating view as subview");
    [targetViewController.view.superview addSubview:[self updatingView]];
}

- (void)removeUpdatingViewFromSuperview
{
    NSLog(@"Removing updating view from superview");
    [[self updatingView] removeFromSuperview];
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
    return self.interfaceOrientation == UIInterfaceOrientationPortrait || 
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ? 
        338 : 190;
}

- (CGFloat)screenWidth
{
    return self.interfaceOrientation == UIInterfaceOrientationPortrait || 
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ?
        320 : 480;
}

- (CGFloat)viewLength
{
    return self.interfaceOrientation == UIInterfaceOrientationPortrait || 
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ?
        320 : 480;
}

- (CGFloat)viewHeight
{
    return 30;
}

@end
