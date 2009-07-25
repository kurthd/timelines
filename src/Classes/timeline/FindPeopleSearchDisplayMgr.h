//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterService.h"
#import "TwitterServiceDelegate.h"
#import "NetworkAwareViewController.h"
#import "TimelineDisplayMgr.h"
#import "ArbUserTimelineDataSource.h"

@interface FindPeopleSearchDisplayMgr :
    NSObject <TwitterServiceDelegate, UISearchBarDelegate>
{
    NetworkAwareViewController * netAwareController;
    TimelineDisplayMgr * timelineDisplayMgr;
    ArbUserTimelineDataSource * dataSource;

    UISearchBar * searchBar;
    UIView * darkTransparentView;
}

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    timelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr
    dataSource:(ArbUserTimelineDataSource *)dataSource;

- (void)searchBarViewWillAppear:(BOOL)promptUser;

@end
