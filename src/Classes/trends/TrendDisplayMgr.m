//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TrendDisplayMgr.h"
#import "TimelineDisplayMgr.h"
#import "SearchDisplayMgr.h"

@interface TrendDisplayMgr ()
@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain) SearchDisplayMgr * searchDisplayMgr;
@end

@implementation TrendDisplayMgr

@synthesize navigationController, timelineDisplayMgr, searchDisplayMgr;

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

@end
