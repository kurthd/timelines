//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "OauthLogInViewController.h"
#import "RegexKitLite.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"

@interface OauthLogInViewController ()

@property (nonatomic, retain) UIWebView * webView;

@property (nonatomic, retain) UINavigationBar * navigationBar;
@property (nonatomic, retain) UIBarButtonItem * cancelButton;
@property (nonatomic, retain) UIBarButtonItem * doneButton;
@property (nonatomic, retain) UIBarButtonItem * savePinButton;

@property (nonatomic, retain) UIView * enterPinView;
@property (nonatomic, retain) UITextField * pinTextField;

- (void)displayEnterPinView;

@end

@implementation OauthLogInViewController

@synthesize delegate;
@synthesize navigationBar, cancelButton, doneButton, savePinButton;
@synthesize webView, enterPinView, pinTextField;

- (void)dealloc
{
    self.delegate = nil;
    self.webView = nil;
    self.navigationBar = nil;
    self.cancelButton = nil;
    self.doneButton = nil;
    self.savePinButton = nil;
    self.enterPinView = nil;
    self.pinTextField = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.scalesPageToFit = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    // reset the view
    [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
    [self.enterPinView removeFromSuperview];
    [self.navigationBar.topItem
        setRightBarButtonItem:self.doneButton animated:YES];
}

- (IBAction)userDidCancel
{
    [self.delegate userDidCancel];
}

- (IBAction)userIsDone
{
    [self displayEnterPinView];
    [self.navigationBar.topItem
        setRightBarButtonItem:self.savePinButton animated:YES];
}

- (IBAction)userDidSavePin
{
    NSString * pin =
        self.pinTextField.text.length ? self.pinTextField.text : nil;
    [self.delegate userIsDone:pin];
}

- (void)loadAuthRequest:(NSURLRequest *)request
{
    [self.webView loadRequest:request];
}

#pragma mark UIWebViewDelegate implementation

- (void)webViewDidStartLoad:(UIWebView *)view
{
    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)webViewDidFinishLoad:(UIWebView *)view
{
    [[UIApplication sharedApplication] networkActivityDidFinish];
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
            3,
            480,
            self.enterPinView.frame.size.width,
            self.enterPinView.frame.size.height);

    CGRect destinationFrame =
        CGRectMake(
            3,
            480 - self.enterPinView.frame.size.height,
            self.enterPinView.frame.size.width,
            self.enterPinView.frame.size.height);

    self.enterPinView.frame = originatingFrame;
    self.enterPinView.frame = destinationFrame;

    [UIView commitAnimations];

    [self.pinTextField becomeFirstResponder];
}

@end
