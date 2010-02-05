//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "OauthLogInViewController.h"
#import "RegexKitLite.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"
#import "WebViewController.h"
#import "SettingsReader.h"

@interface OauthLogInViewController ()

@property (nonatomic, retain) UIWebView * webView;


@property (nonatomic, readonly) UIBarButtonItem * activityButton;
@property (nonatomic, retain) UIActivityIndicatorView * activityIndicator;

@property (nonatomic, retain) UITextField * pinTextField;

@property (nonatomic, readonly) UIViewController * helpViewController;

- (void)showActivity;
- (void)hideActivity;

@end

@implementation OauthLogInViewController

@synthesize delegate;
@synthesize cancelButton, doneButton;
@synthesize activityIndicator;
@synthesize webView, pinTextField;

- (void)dealloc
{
    self.delegate = nil;
    self.webView = nil;
    self.cancelButton = nil;
    self.doneButton = nil;
    [activityButton release];
    self.activityIndicator = nil;
    self.pinTextField = nil;
    [helpViewController release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([SettingsReader displayTheme] == kDisplayThemeDark)
        self.navigationController.navigationBar.barStyle =
            UIBarStyleBlackOpaque;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"Showing oauth login view");
    [super viewWillAppear:animated];

    self.doneButton.enabled = NO;
    self.pinTextField.text = @"";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.pinTextField resignFirstResponder];    
}

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

    NSString * pin =
        [[view stringByEvaluatingJavaScriptFromString:
        @"document.getElementById('oauth-pin').innerHTML"]
        stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (pin && pin.length > 0) {
        self.pinTextField.text = pin;
        self.doneButton.enabled = YES;
    }
}

#pragma mark UI Helpers

- (void)showActivity
{
    [self.navigationItem setRightBarButtonItem:self.activityButton
        animated:YES];
    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)hideActivity
{
    [self.navigationItem setRightBarButtonItem:self.doneButton animated:YES];
    [[UIApplication sharedApplication] networkActivityDidFinish];
}

#pragma mark Accessors

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

- (UIBarButtonItem *)activityButton
{
    if (!activityButton) {
        NSString * backgroundImageFilename =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            @"NavigationButtonBackgroundDarkTheme.png" :
            @"NavigationButtonBackground.png";
        UIView * view =
            [[UIImageView alloc]
            initWithImage:[UIImage imageNamed:backgroundImageFilename]];
        UIActivityIndicatorView * activityView =
            [[[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]
            autorelease];
        activityView.frame = CGRectMake(7, 5, 20, 20);
        [view addSubview:activityView];

        activityButton =
            [[UIBarButtonItem alloc] initWithCustomView:view];

        [activityView startAnimating];

        [view release];
    }

    return activityButton;
}

@end
