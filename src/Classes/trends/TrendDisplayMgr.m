//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendDisplayMgr.h"
#import "TimelineDisplayMgr.h"
#import "SearchDisplayMgr.h"

static const CGFloat WEB_VIEW_WIDTH = 320;
static const CGFloat WEB_VIEW_WIDTH_LANDSCAPE = 480;


@interface TrendDisplayMgr ()
@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain) SearchDisplayMgr * searchDisplayMgr;

@property (nonatomic, retain) Trend * trend;
@property (nonatomic, retain) UIWebView * trendExplanationView;

- (void)loadTrendExplanationWebView;
- (void)displayTrendTimelineWithHeaderView:(UIView *)headerView;
+ (NSString *)wrapHtml:(NSString *)html;
@end

@implementation TrendDisplayMgr

@synthesize navigationController, timelineDisplayMgr, searchDisplayMgr;
@synthesize trend, trendExplanationView;

- (void)dealloc
{
    self.navigationController;
    self.timelineDisplayMgr = nil;
    self.searchDisplayMgr = nil;

    self.trend = nil;
    self.trendExplanationView = nil;

    [super dealloc];
}

- (id)initWithSearchDisplayMgr:(SearchDisplayMgr *)aSearchDisplayMgr
          navigationController:(UINavigationController *)aNavicationController
            timelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr
{
    if (self = [super init]) {
        self.searchDisplayMgr = aSearchDisplayMgr;
        self.navigationController = aNavicationController;
        self.timelineDisplayMgr = aTimelineDisplayMgr;
    }

    return self;
}

#pragma mark Public implementation

- (void)displayTrend:(Trend *)aTrend
{
    self.trend = aTrend;
    [self loadTrendExplanationWebView];
}

#pragma mark Private implementation

- (void)loadTrendExplanationWebView
{
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    CGFloat width = !landscape ? WEB_VIEW_WIDTH : WEB_VIEW_WIDTH_LANDSCAPE;
    CGRect frame = CGRectMake(0, 0, width, 1);

    UIWebView * webView = [[UIWebView alloc] initWithFrame:frame];
    webView.delegate = self;
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    webView.dataDetectorTypes = UIDataDetectorTypeAll;

    // The view must be added as the subview of a visible view, otherwise the
    // height will not be calculated when -sizeToFit: is called in the
    // -webViewDidFinishLoad delegate method. Adding it here seems to have
    // no effect on the display at all, but the view does calculate its frame
    // correctly. Is there a better way to do this?
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:webView];

    NSString * html = [[self class] wrapHtml:self.trend.explanation];
    [webView loadHTMLStringRelativeToMainBundle:html];

    self.trendExplanationView = webView;
    [webView release];
}

- (void)displayTrendTimelineWithHeaderView:(UIView *)headerView
{
    NSLog(@"Displaying trend: %@", trend);

    self.timelineDisplayMgr.wrapperController.navigationItem.title = trend.name;
    [self.searchDisplayMgr displaySearchResults:trend.query
                                      withTitle:trend.name];

    [self.timelineDisplayMgr setService:self.searchDisplayMgr
                                 tweets:nil
                                   page:0
                           forceRefresh:YES
                         allPagesLoaded:NO];
    [self.timelineDisplayMgr setTimelineHeaderView:headerView];

    UIViewController * vc = timelineDisplayMgr.wrapperController;
    [self.navigationController pushViewController:vc animated:YES];
}

+ (NSString *)wrapHtml:(NSString *)html
{
    NSString * cssFile =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        @"dark-theme-tweet-style.css" :
        @"tweet-style.css";

    return
        [NSString stringWithFormat:
        @"<html>"
        "  <head>"
        "   <style media=\"screen\" type=\"text/css\" rel=\"stylesheet\">"
        "     @import url(%@);"
        "   </style>"
        "  </head>"
        "  <body>"
        "    <p class=\"text\">%@</p>"
        "  </body>"
        "</html>",
        cssFile, html];
}

#pragma mark UIWebViewDelegate implementation

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [webView removeFromSuperview];

    BOOL landscape = [[RotatableTabBarController instance] landscape];
    CGFloat width = !landscape ? WEB_VIEW_WIDTH :WEB_VIEW_WIDTH_LANDSCAPE;
    webView.frame = CGRectMake(5, 0, width, 31);

    CGSize size = [webView sizeThatFits:CGSizeZero];
    CGRect frame = webView.frame;
    frame.size.width = size.width;
    frame.size.height = size.height;
    webView.frame = frame;

    [self displayTrendTimelineWithHeaderView:webView];
    self.trendExplanationView = nil;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Failed to load trend explanation in web view: %@\n%@", error,
        self.trend.explanation);

    self.trendExplanationView = nil;
    [self displayTrendTimelineWithHeaderView:nil];
}

@end
