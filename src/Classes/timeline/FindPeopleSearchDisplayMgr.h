//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterService.h"
#import "TwitterServiceDelegate.h"
#import "NetworkAwareViewController.h"
#import "TimelineDisplayMgr.h"
#import "ArbUserTimelineDataSource.h"
#import "FindPeopleBookmarkViewController.h"
#import "RecentSearchMgr.h"
#import "SavedSearchMgr.h"

@interface FindPeopleSearchDisplayMgr :
    NSObject
    <TwitterServiceDelegate, UISearchBarDelegate,
    FindPeopleBookmarkViewControllerDelegate>
{
    NetworkAwareViewController * netAwareController;
    TimelineDisplayMgr * timelineDisplayMgr;
    ArbUserTimelineDataSource * dataSource;

    UISearchBar * searchBar;
    UIView * darkTransparentView;

    RecentSearchMgr * recentSearchMgr;
    SavedSearchMgr * savedSearchMgr;

    FindPeopleBookmarkViewController * bookmarkController;
    NSManagedObjectContext * context;
}

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    timelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr
    dataSource:(ArbUserTimelineDataSource *)dataSource
    context:(NSManagedObjectContext *)aContext
    savedSearchMgr:(SavedSearchMgr *)aSavedSearchMgr;

@end
