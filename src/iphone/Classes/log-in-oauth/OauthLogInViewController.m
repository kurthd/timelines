//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "OauthLogInViewController.h"

@interface OauthLogInViewController ()

@property (nonatomic, retain) UIWebView * webView;

@property (nonatomic, retain) UIBarButtonItem * cancelButton;
@property (nonatomic, retain) UIBarButtonItem * doneButton;

@property (nonatomic, retain) UIView * enterPinView;
@property (nonatomic, retain) UITextField * pinTextField;

@property (nonatomic, retain) NSURLRequest * request;

- (void)displayEnterPinView;

@end

@implementation OauthLogInViewController

@synthesize delegate, webView, cancelButton, doneButton, request;
@synthesize enterPinView, pinTextField;

- (void)dealloc
{
    self.delegate = nil;
    self.webView = nil;
    self.cancelButton = nil;
    self.doneButton = nil;
    self.enterPinView = nil;
    self.pinTextField = nil;
    self.request = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.scalesPageToFit = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.request)
        [self.webView loadRequest:self.request];
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

- (IBAction)userIsDone
{
    NSString * pin =
        self.pinTextField.text.length ? self.pinTextField.text : nil;
    [self.delegate userIsDone:pin];
}

- (void)loadRequest:(NSURLRequest *)aRequest
{
    self.request = aRequest;
}

#pragma mark UIWebViewDelegate implementation

- (BOOL)webView:(UIWebView *)aWebView
    shouldStartLoadWithRequest:(NSURLRequest *)req
                navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeFormSubmitted) {
        static NSString * authUrl = @"http://twitter.com/oauth/authorize";
        NSURL * url = [req URL];
        if ([url.absoluteString isEqual:authUrl]) {
            [self displayEnterPinView];
            [self.pinTextField becomeFirstResponder];
        }
    }

    return YES;
}

#pragma mark UI helpers

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
