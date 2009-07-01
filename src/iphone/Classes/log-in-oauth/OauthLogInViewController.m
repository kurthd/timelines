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

@property (nonatomic, retain) UIBarButtonItem * activityButton;
@property (nonatomic, retain) UIActivityIndicatorView * activityIndicator;

@property (nonatomic, retain) UITextField * pinTextField;

- (void)showActivity;
- (void)hideActivity;

@end

@implementation OauthLogInViewController

@synthesize delegate;
@synthesize navigationBar, cancelButton, doneButton;
@synthesize activityButton, activityIndicator;
@synthesize webView, pinTextField;

- (void)dealloc
{
    self.delegate = nil;
    self.webView = nil;
    self.navigationBar = nil;
    self.cancelButton = nil;
    self.doneButton = nil;
    self.activityButton = nil;
    self.activityIndicator = nil;
    self.pinTextField = nil;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.doneButton.enabled = NO;
    self.pinTextField.text = @"";
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    // reset the view
    [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
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

- (void)loadAuthRequest:(NSURLRequest *)request
{
    [self.webView loadRequest:request];
}

#pragma mark UITextFieldDelegate implementation

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)s
{
    NSString * newString =
        [self.pinTextField.text
        stringByReplacingCharactersInRange:range withString:s];
    self.doneButton.enabled = newString.length > 0;

    return YES;
}

#pragma mark UIWebViewDelegate implementation

- (void)webViewDidStartLoad:(UIWebView *)view
{
    [self showActivity];
}

- (void)webViewDidFinishLoad:(UIWebView *)view
{
    [self hideActivity];
}

#pragma mark UI Helpers

- (void)showActivity
{
    [self.navigationBar.topItem setRightBarButtonItem:self.activityButton
                                             animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)hideActivity
{
    [self.navigationBar.topItem setRightBarButtonItem:self.doneButton
                                             animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark Accessors

- (UIBarButtonItem *)activityButton
{
    if (activityButton)
        activityButton =
            [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];

    return activityButton;
}

@end
