//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwitchBrowserViewController.h"
#import "RegexKitLite.h"

@interface TwitchBrowserViewController ()

- (void)updateViewForNotLoading;
- (void)updatePageTitle;

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
    activityIndicator.hidden = NO;
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
    NSURL * url = [NSURL URLWithString:self.currentUrl];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)updateViewForNotLoading
{
    haltButton.image = [UIImage imageNamed:@"Refresh.png"];
    activityIndicator.hidden = YES;
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

@end
