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

- (void)changeHeightOfView:(UIView *)theView
                  toHeight:(CGFloat)height
         animationDuration:(NSTimeInterval)animationDuration;

- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

- (void)registerForKeyboardNotifications;
- (void)unregisterForKeyboardNotifications;

- (CGRect)keyboardRectFromNotification:(NSNotification *)n;
- (NSTimeInterval)keyboardAnimationDurationForNotification:(NSNotification *)n;

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

//
// HACK: To correctly move the PIN number into place when the entry field has
// focus, we reposition the webview when the PIN text field has focus. To do
// this, we have to register for keyboard notifications so we can retrieve the
// keyboard's size and animation duration. But if we do this all the time, we
// will also receive notifications when the username/password fields in the
// Twitter oauth screen have focus. Therefore we track when the PIN text field
// has focus and only reposition the webview when it has focus.
//
static BOOL textFieldHasFocus = NO;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textFieldHasFocus = YES;
    [self registerForKeyboardNotifications];

    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    // HACK: Do this after a delay so that the keyboard event will be processed
    // before the 'textFieldHasFocus' is reset and the notification observer
    // removed.
    [self performSelector:@selector(processTextFieldShouldEndEditing)
               withObject:nil
               afterDelay:1.0];

    return YES;
}

- (void)processTextFieldShouldEndEditing
{
    textFieldHasFocus = NO;
    [self unregisterForKeyboardNotifications];
}

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

- (void)changeHeightOfView:(UIView *)theView
                  toHeight:(CGFloat)height
         animationDuration:(NSTimeInterval)animationDuration
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];

    CGRect rect = theView.frame;
    rect.size.height = height;
    theView.frame = rect;

    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!textFieldHasFocus)
        return;

    CGRect rect = [self keyboardRectFromNotification:notification];
    NSTimeInterval duration =
        [self keyboardAnimationDurationForNotification:notification];
    CGFloat height = self.webView.frame.size.height - rect.size.height;

    [self changeHeightOfView:self.webView
                    toHeight:height
           animationDuration:duration];

    // HACK: Scroll the PIN number into view; it's otherwise obscured by
    // the keyboard, and it's impossible to manually scroll it into view
    [self.webView stringByEvaluatingJavaScriptFromString:
        @"var x = document.getElementById('oauth-pin');"
         "if (x != null) { x.scrollIntoView(true); }"];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (!textFieldHasFocus)
        return;

    CGRect rect = [self keyboardRectFromNotification:notification];
    NSTimeInterval duration =
        [self keyboardAnimationDurationForNotification:notification];
    CGFloat height = self.webView.frame.size.height + rect.size.height;

    [self changeHeightOfView:self.webView
                    toHeight:height
           animationDuration:duration];
}

- (void)registerForKeyboardNotifications
{
    NSNotificationCenter * notificationCenter =
        [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillShow:)
                               name:UIKeyboardWillShowNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillHide:)
                               name:UIKeyboardWillHideNotification
                             object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    NSNotificationCenter * notificationCenter =
        [NSNotificationCenter defaultCenter];

    [notificationCenter removeObserver:self
                                  name:UIKeyboardWillShowNotification
                                object:nil];
    [notificationCenter removeObserver:self
                                  name:UIKeyboardWillHideNotification
                                object:nil];
}

- (CGRect)keyboardRectFromNotification:(NSNotification *)n
{
    CGRect rect;
    [[n.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&rect];

    return rect;
}

- (NSTimeInterval)keyboardAnimationDurationForNotification:(NSNotification *)n
{
    NSValue * value =
        [n.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration = 0;
    [value getValue:&duration];

    return duration;
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
