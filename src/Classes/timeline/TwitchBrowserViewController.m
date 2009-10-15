//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwitchBrowserViewController.h"
#import "RegexKitLite.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "RotatableTabBarController.h"
#import "SettingsReader.h"

@interface TwitchBrowserViewController ()

- (void)updateViewForNotLoading;
- (void)updatePageTitle;
- (void)animatedActivityIndicators:(BOOL)animating;
- (void)displayComposerMailSheet;
- (void)displayForPortraitMode;
- (void)displayForOrientation:(UIInterfaceOrientation)orientation;

@end

@implementation TwitchBrowserViewController

@synthesize currentUrl, delegate;

- (void)dealloc
{
    [navItem release];
    [browserToolbar release];
    [browserNavBar release];
    [webView release];
    [backButton release];
    [forwardButton release];
    [haltButton release];
    [titleLabel release];
    [activityIndicator release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        browserToolbar.barStyle = UIBarStyleBlackOpaque;
        browserNavBar.barStyle = UIBarStyleBlackOpaque;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIInterfaceOrientation orientation =
        [[RotatableTabBarController instance] effectiveOrientation];
    [self displayForOrientation:orientation];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self displayForPortraitMode];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
                                duration:(NSTimeInterval)duration
{
    [self displayForOrientation:orientation];
}

- (void)displayForOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown)
        [self displayForPortraitMode];
    else {
        CGRect activityIndicatorFrame = activityIndicator.frame;
        activityIndicatorFrame.origin.x = 451;
        activityIndicator.frame = activityIndicatorFrame;

        CGRect titleLabelFrame = titleLabel.frame;
        titleLabelFrame.size.width = 378;
        titleLabel.frame = titleLabelFrame;
    }
}

- (void)displayForPortraitMode
{
    CGRect activityIndicatorFrame = activityIndicator.frame;
    activityIndicatorFrame.origin.x = 291;
    activityIndicator.frame = activityIndicatorFrame;

    CGRect titleLabelFrame = titleLabel.frame;
    titleLabelFrame.size.width = 218;
    titleLabel.frame = titleLabelFrame;
}

#pragma mark UIWebViewDelegate implementation

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    // HACK: this allows links that should open in another window to load
    [webView stringByEvaluatingJavaScriptFromString:@"{\
        var a = document.getElementsByTagName(\"a\"); \
    	for (var i=0; i<a.length; i++) \
    	    a[i].target = \"_self\";\
    	}"];

    backButton.enabled = [webView canGoBack];
    forwardButton.enabled = [webView canGoForward];
    if (!webView.loading)
        [self updateViewForNotLoading];
    [self updatePageTitle];
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
    haltButton.image = [UIImage imageNamed:@"StopLoading.png"];
    [self animatedActivityIndicators:YES];
    [self updatePageTitle];
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)sheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"User clicked button at index: %d.", buttonIndex);

    switch (buttonIndex) {
        case 0:
            [self openInSafari];
            break;
        case 1:
            [self postInTweet];
            break;
        case 2:
            [self sendInEmail];
            break;
        case 3:
            [self readLater];
            break;
    }

    [sheet autorelease];
}

#pragma mark MFMailComposeViewControllerDelegate implementation

- (void)mailComposeController:(MFMailComposeViewController *)controller
    didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultFailed) {
        NSString * title =
            NSLocalizedString(@"photobrowser.emailerror.title", @"");
        UIAlertView * alert =
            [UIAlertView simpleAlertViewWithTitle:title
            message:[error description]];
        [alert show];
    }

    [controller dismissModalViewControllerAnimated:YES];
}

#pragma mark TwitchBrowserViewController implementation

- (void)setUrl:(NSString *)urlString
{
    self.currentUrl = urlString;
    titleLabel.text = urlString;

    NSURL * url = [NSURL URLWithString:urlString];
    NSURLRequest * request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];

    backButton.enabled = NO;
    forwardButton.enabled = NO;
}

- (IBAction)dismissView
{
    [webView stopLoading];
    [self dismissModalViewControllerAnimated:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (IBAction)moveBackAPage
{
    [webView goBack];
}

- (IBAction)moveForwardAPage
{
    [webView goForward];
}

- (IBAction)haltLoading
{
    if (webView.loading) {
        [self updateViewForNotLoading];
        [webView stopLoading];
    } else
        [webView reload];
}

- (IBAction)showActions
{
    NSString * cancel = NSLocalizedString(@"browserview.actions.cancel", @"");
    NSString * browser = NSLocalizedString(@"browserview.actions.browser", @"");
    NSString * post = NSLocalizedString(@"browserview.actions.post", @"");
    NSString * email = NSLocalizedString(@"browserview.actions.email", @"");

    NSString * readlater =
        NSLocalizedString(@"browserview.actions.readlater", @"");

    UIActionSheet * sheet =
        [[UIActionSheet alloc]
        initWithTitle:nil delegate:self cancelButtonTitle:cancel
        destructiveButtonTitle:nil
        otherButtonTitles:browser, post, email, readlater, nil];

    [sheet showInView:self.view];
}

- (void)openInSafari
{
    NSLog(@"Opening page in safari");
    NSURL * url = [webView.request URL];
    url = url ? url : [NSURL URLWithString:self.currentUrl];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)sendInEmail
{
    NSLog(@"Sending page link in email");
    if ([MFMailComposeViewController canSendMail]) {
        [self displayComposerMailSheet];
    } else {
        NSString * title =
            NSLocalizedString(@"photobrowser.unabletosendmail.title", @"");
        NSString * message =
            NSLocalizedString(@"photobrowser.unabletosendmail.message", @"");
        UIAlertView * alert =
            [UIAlertView simpleAlertViewWithTitle:title message:message];
        [alert show];
    }
}

- (void)displayComposerMailSheet
{
	MFMailComposeViewController * picker =
	    [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;

    [picker setSubject:titleLabel.text];

    NSURL * url = [webView.request URL];
    url = url ? url : [NSURL URLWithString:self.currentUrl];
    NSString * urlAsString = [url absoluteString];

    [picker setMessageBody:urlAsString isHTML:NO];

	[self presentModalViewController:picker animated:YES];

    [picker release];
}

- (void)postInTweet
{
    NSLog(@"Posting page link in tweet");

    NSURL * url = [webView.request URL];
    NSString * urlAsString =
        [url absoluteString].length == 0 ?
        self.currentUrl : [url absoluteString];

    [self dismissView];
    [delegate performSelector:@selector(composeTweetWithLink:)
        withObject:urlAsString afterDelay:0.5];
}

- (void)readLater
{
    NSLog(@"Sending the page to Instapaper");

    NSURL * url = [webView.request URL];
    NSString * urlAsString =
        [url absoluteString].length == 0 ?
        self.currentUrl : [url absoluteString];

    [delegate readLater:urlAsString];
}

- (void)updateViewForNotLoading
{
    haltButton.image = [UIImage imageNamed:@"Refresh.png"];
    [self animatedActivityIndicators:NO];
}

- (void)updatePageTitle
{
    NSString * innerHtml =
        [webView
        stringByEvaluatingJavaScriptFromString:
        @"document.documentElement.outerHTML"];
    NSString * title =
        [[innerHtml stringByMatching:@"<\\s*title\\s*>.*<\\s*/\\s*title\\s*>"]
        stringByReplacingOccurrencesOfRegex:
        @"<\\s*/?\\s*title\\s*>" withString:@""];
    title =
        [title stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    title =
        [title stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];

    NSString * loadedPage =
        title ? title : [[webView.request URL] absoluteString];
    titleLabel.text =
        loadedPage && ![loadedPage isEqual:@""] ? loadedPage : self.currentUrl;
}

- (void)animatedActivityIndicators:(BOOL)animating
{
    activityIndicator.hidden = !animating;
    [UIApplication sharedApplication].networkActivityIndicatorVisible =
        animating;
}

@end
