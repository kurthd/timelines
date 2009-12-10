//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendDisplayMgr.h"
#import "TimelineDisplayMgr.h"
#import "SearchDisplayMgr.h"
#import "TrendExplanationViewController.h"

static const CGFloat WEB_VIEW_WIDTH = 320;
static const CGFloat WEB_VIEW_WIDTH_LANDSCAPE = 480;

@interface TrendDisplayMgr ()
@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain) SearchDisplayMgr * searchDisplayMgr;

+ (NSString *)wrapHtml:(NSString *)html;
@end

@implementation TrendDisplayMgr

@synthesize navigationController, timelineDisplayMgr, searchDisplayMgr,
    navigationController;

- (void)dealloc
{
    self.navigationController;
    self.timelineDisplayMgr = nil;
    self.searchDisplayMgr = nil;

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

- (void)displayTrend:(Trend *)trend
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

    UIViewController * vc = timelineDisplayMgr.wrapperController;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)displayExplanationForTrend:(Trend *)trend
{
    NSString * html = [[self class] wrapHtml:trend.explanation];
    TrendExplanationViewController * controller =
        [[TrendExplanationViewController alloc] initWithHtmlExplanation:html];

    controller.linkTapTarget = self;
    controller.linkTapAction = @selector(displayUrl:);

    controller.navigationItem.title = trend.name;
    [self.navigationController pushViewController:controller animated:YES];

    [controller release];
}

#pragma mark Private implementation

- (void)displayUrl:(NSString *)url
{
    [[TwitchWebBrowserDisplayMgr instance] visitWebpage:url];
}

+ (NSString *)wrapHtml:(NSString *)html
{
    NSString * cssFile =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        @"dark-theme-trend-style.css" :
        @"trend-style.css";

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

@end
