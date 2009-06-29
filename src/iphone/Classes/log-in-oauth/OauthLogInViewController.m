//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "OauthLogInViewController.h"
#import "RegexKitLite.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"

static NSInteger loading = 0;

@interface OauthLogInViewController ()

@property (nonatomic, retain) UIWebView * webView;

@property (nonatomic, retain) UINavigationBar * navigationBar;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;
@property (nonatomic, retain) UIBarButtonItem * doneButton;
@property (nonatomic, retain) UIBarButtonItem * startOverButton;

@property (nonatomic, retain) UIView * enterPinView;
@property (nonatomic, retain) UITextField * pinTextField;

@property (nonatomic, retain) UIView * activityView;

- (void)configureViewForState:(AuthState)state;
- (void)displayEnterPinView;

@end

@implementation OauthLogInViewController

@synthesize delegate;
@synthesize navigationBar, cancelButton, doneButton, startOverButton;
@synthesize logInCanBeCancelled;
@synthesize webView, enterPinView, pinTextField, activityView;

- (void)dealloc
{
    self.delegate = nil;
    self.webView = nil;
    self.navigationBar = nil;
    self.cancelButton = nil;
    self.doneButton = nil;
    self.startOverButton = nil;
    self.enterPinView = nil;
    self.pinTextField = nil;
    self.activityView = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.scalesPageToFit = YES;
    self.logInCanBeCancelled = NO;

    /*
    CGRect activityFrame = self.activityView.frame;
    activityFrame.origin.x = 10.0;
    activityFrame.origin.y = 44.0;
    self.activityView.frame = activityFrame;
    */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    authState = kAuthChallenge;
    [self configureViewForState:authState];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self.webView loadRequest:nil];
    [self.pinTextField removeFromSuperview];
}

- (IBAction)userDidCancel
{
    [self.delegate userDidCancel];
}

- (IBAction)userDidFinish
{
    NSString * pin =
        self.pinTextField.text.length ? self.pinTextField.text : nil;
    [self.delegate userIsDone:pin];
}

- (IBAction)userDidStartOver
{
    authState = kAuthChallenge;
    [self configureViewForState:kAuthChallenge];
    [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
    [self.delegate userDidStartOver];
}

- (void)loadAuthRequest:(NSURLRequest *)request
{
    authState = kAuthChallenge;
    [self configureViewForState:authState];
    [self.webView loadRequest:request];
}

- (void)showActivityView:(BOOL)animated
{
    self.activityView.alpha = 0.0;
    [self.view addSubview:self.activityView];

    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone
                               forView:self.activityView
                                 cache:NO];
    }

    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:animated];
    
    self.activityView.alpha = 1.0;

    if (animated)
        [UIView commitAnimations];
}

- (void)hideActivityView:(BOOL)animated
{
    self.activityView.alpha = 1.0;

    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone
                               forView:self.activityView
                                 cache:NO];
    }

    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleDefault animated:animated];

    self.activityView.alpha = 0.0;

    if (animated)
        [UIView commitAnimations];

    [self.activityView removeFromSuperview];
}

#pragma mark UIWebViewDelegate implementation

- (BOOL)webView:(UIWebView *)aWebView
    shouldStartLoadWithRequest:(NSURLRequest *)req
                navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"navigation type: '%d'.", navigationType);
    if (navigationType == UIWebViewNavigationTypeFormSubmitted) {
        static NSString * authUrl = @"http://twitter.com/oauth/authorize";
        NSURL * url = [req URL];
        NSString * body = [[[NSString alloc]
            initWithData:[req HTTPBody] encoding:NSUTF8StringEncoding]
            autorelease];
        NSLog(@"headers: '%@'", [req allHTTPHeaderFields]);
        NSLog(@"body: '%@'", body);
        if ([url.absoluteString isEqual:authUrl]) {
             authState =
                 ([body isMatchedByRegex:@"&cancel="] ||
                 [body isMatchedByRegex:@"^cancel="]) ?
                kOther :
                kEnterPin;

        }
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)view
{
    NSLog(@"Started load: %d", ++loading);
    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)webViewDidFinishLoad:(UIWebView *)view
{
    NSLog(@"Finished load: %d", --loading);
    if (authState == kAuthChallenge)
        [self hideActivityView:YES];

    [self configureViewForState:authState];
    [[UIApplication sharedApplication] networkActivityDidFinish];
}

#pragma mark UI helpers

- (void)configureViewForState:(AuthState)state
{
    UIBarButtonItem * leftButton = nil;

    switch (state) {
        case kAuthChallenge:
            self.navigationBar.topItem.rightBarButtonItem = nil;

            if (self.logInCanBeCancelled)
                [self.navigationBar.topItem
                    setLeftBarButtonItem:self.cancelButton animated:YES];
            else
                [self.navigationBar.topItem
                    setLeftBarButtonItem:nil animated:YES];

            [self.enterPinView removeFromSuperview];

            break;
        case kEnterPin:
            [self displayEnterPinView];
            [self.pinTextField becomeFirstResponder];
            [self.navigationBar.topItem setRightBarButtonItem:self.doneButton
                                                     animated:YES];

             leftButton =
                self.logInCanBeCancelled ?
                self.cancelButton : self.startOverButton;
             [self.navigationBar.topItem setLeftBarButtonItem:leftButton
                                                     animated:YES];

            break;
        case kOther:
            [self.navigationBar.topItem
                setLeftBarButtonItem:self.startOverButton animated:YES];

            [self.enterPinView removeFromSuperview];

            break;
    }
}

- (void)displayEnterPinView
{
    [self.view addSubview:self.enterPinView];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:self.enterPinView
                             cache:NO];

    CGRect originatingFrame =
        CGRectMake(
            5,
            480,
            self.enterPinView.frame.size.width,
            self.enterPinView.frame.size.height);

    CGRect destinationFrame =
        CGRectMake(
            5,
            480 - self.enterPinView.frame.size.height,
            self.enterPinView.frame.size.width,
            self.enterPinView.frame.size.height);

    self.enterPinView.frame = originatingFrame;
    self.enterPinView.frame = destinationFrame;

    [UIView commitAnimations];
}

@end
