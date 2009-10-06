//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "OauthLogInViewController.h"
#import "RegexKitLite.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"
#import "WebViewController.h"

@interface OauthLogInViewController ()

@property (nonatomic, retain) UIWebView * webView;


@property (nonatomic, retain) UIBarButtonItem * activityButton;
@property (nonatomic, retain) UIActivityIndicatorView * activityIndicator;

@property (nonatomic, retain) UITextField * pinTextField;

@property (nonatomic, readonly) UIViewController * helpViewController;

- (void)showActivity;
- (void)hideActivity;

@end

@implementation OauthLogInViewController

@synthesize delegate;
@synthesize cancelButton, doneButton;
@synthesize activityButton, activityIndicator;
@synthesize webView, pinTextField;

- (void)dealloc
{
    self.delegate = nil;
    self.webView = nil;
    self.cancelButton = nil;
    self.doneButton = nil;
    self.activityButton = nil;
    self.activityIndicator = nil;
    self.pinTextField = nil;
    [helpViewController release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.doneButton.enabled = NO;
    self.pinTextField.text = @"";
}

// - (BOOL)shouldAutorotateToInterfaceOrientation:
//     (UIInterfaceOrientation)orientation
// {
//     return YES;
// }

- (IBAction)userDidCancel
{
    [self.delegate userDidCancel];

    // reset the view
    [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
}

- (IBAction)userIsDone
{
    NSString * pin =
        self.pinTextField.text.length ? self.pinTextField.text : nil;
    [self.delegate userIsDone:pin];

    // reset the view
    [self.webView loadHTMLString:@"<html></html>" baseURL:nil];
}

- (IBAction)showHelpView
{
    [self.navigationController pushViewController:self.helpViewController
        animated:YES];
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
    [self.navigationItem setRightBarButtonItem:self.activityButton
        animated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)hideActivity
{
    [self.navigationItem setRightBarButtonItem:self.doneButton animated:YES];
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

- (UIViewController *)helpViewController
{
    if (!helpViewController) {
        helpViewController =
            [[WebViewController alloc] initWithHtmlFilename:@"log-in-help"];
        helpViewController.navigationItem.title =
            NSLocalizedString(@"loginhelpview.title", @"");
    }

    return helpViewController;
}

@end
