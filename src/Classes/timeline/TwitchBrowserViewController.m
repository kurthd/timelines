//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwitchBrowserViewController.h"
#import "RegexKitLite.h"

@interface TwitchBrowserViewController ()

- (void)updateViewForNotLoading;
- (void)updatePageTitle;
- (void)animatedActivityIndicators:(BOOL)animating;

@end

@implementation TwitchBrowserViewController

@synthesize currentUrl;

- (void)dealloc
{
    [navItem release];
    [webView release];
    [backButton release];
    [forwardButton release];
    [haltButton release];
    [titleLabel release];
    [activityIndicator release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
    (UIInterfaceOrientation)orientation {

    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortrait) {

        CGRect activityIndicatorFrame = activityIndicator.frame;
        activityIndicatorFrame.origin.x = 291;
        activityIndicator.frame = activityIndicatorFrame;

        CGRect titleLabelFrame = titleLabel.frame;
        titleLabelFrame.size.width = 218;
        titleLabel.frame = titleLabelFrame;
    } else {
        CGRect activityIndicatorFrame = activityIndicator.frame;
        activityIndicatorFrame.origin.x = 451;
        activityIndicator.frame = activityIndicatorFrame;

        CGRect titleLabelFrame = titleLabel.frame;
        titleLabelFrame.size.width = 378;
        titleLabel.frame = titleLabelFrame;
    }

	return YES;
}

#pragma mark UIWebViewDelegate implementation

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
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

- (IBAction)openInSafari
{
    NSURL * url = [webView.request URL];
    url = url ? url : [NSURL URLWithString:self.currentUrl];
    [[UIApplication sharedApplication] openURL:url];
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
