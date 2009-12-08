//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendExplanationViewController.h"
#import "TwitbitShared.h"

@interface TrendExplanationViewController ()
@property (nonatomic, retain) UIWebView * webView;
@property (nonatomic, copy) NSString * explanation;
@end

@implementation TrendExplanationViewController

@synthesize webView, explanation, linkTapTarget, linkTapAction;

- (void)dealloc
{
    self.webView = nil;
    self.explanation = nil;
    self.linkTapTarget = nil;
    [super dealloc];
}

- (id)initWithHtmlExplanation:(NSString *)html
{
    if (self = [super initWithNibName:@"TrendExplanationView" bundle:nil])
        self.explanation = html;

    return self;
}

#pragma mark UIViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    [webView loadHTMLStringRelativeToMainBundle:self.explanation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io
{
    return YES;
}

#pragma mark UIWebViewDelegate implementation

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
                navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [self.linkTapTarget performSelector:self.linkTapAction
                                 withObject:[[request URL] absoluteString]];
        return NO;
    }

    return YES;
}

@end

