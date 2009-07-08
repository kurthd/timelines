//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterService.h"
#import "TrendsViewController.h"
#import "NetworkAwareViewController.h"
#import "SearchDisplayMgr.h"
#import "TimelineDisplayMgr.h"

@interface TrendsDisplayMgr : NSObject
    <TwitterServiceDelegate, NetworkAwareViewControllerDelegate,
    TrendsViewControllerDelegate>
{
    TwitterService * service;

    NetworkAwareViewController * networkAwareViewController;
    TrendsViewController * trendsViewController;
    UISegmentedControl * segmentedControl;

    TimelineDisplayMgr * timelineDisplayMgr;
    SearchDisplayMgr * searchDisplayMgr;

    NSMutableArray * allTrends;
}

- (id)initWithTwitterService:(TwitterService *)aService
          netAwareController:(NetworkAwareViewController *)navc
          timelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
