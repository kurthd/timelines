//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwitchBrowserViewController.h"

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
    if (!webView.loading) {
        haltButton.image = [UIImage imageNamed:@"Refresh.png"];
        activityIndicator.hidden = YES;
    }

    NSString * loadedPage = [[webView.request URL] absoluteString];
    titleLabel.text =
        loadedPage || [loadedPage isEqual:@""] ? loadedPage : currentUrl;
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
    haltButton.image = [UIImage imageNamed:@"StopLoading.png"];
    activityIndicator.hidden = NO;
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
    if (webView.loading)
        [webView stopLoading];
    else
        [webView reload];
}

- (IBAction)openInSafari
{
    NSURL * url = [NSURL URLWithString:self.currentUrl];
    [[UIApplication sharedApplication] openURL:url];
}

@end
