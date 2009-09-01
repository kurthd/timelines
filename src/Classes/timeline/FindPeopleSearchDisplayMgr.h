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
#import "UserInfoViewController.h"
#import "UserInfoViewControllerDelegate.h"
#import "ComposeTweetDisplayMgr.h"
#import "TimelineDisplayMgrFactory.h"
#import "UserListDisplayMgrFactory.h"
#import "LocationMapViewController.h"
#import "LocationMapViewControllerDelegate.h"
#import "LocationInfoViewController.h"
#import "LocationInfoViewControllerDelegate.h"

@interface FindPeopleSearchDisplayMgr :
    NSObject
    <TwitterServiceDelegate, UISearchBarDelegate,
    FindPeopleBookmarkViewControllerDelegate, UserInfoViewControllerDelegate,
    TwitchBrowserViewControllerDelegate, UITableViewDataSource,
    UITableViewDelegate, LocationMapViewControllerDelegate,
    LocationInfoViewControllerDelegate, NetworkAwareViewControllerDelegate>
{
    NetworkAwareViewController * netAwareController;
    UserInfoViewController * userInfoController;
    TwitterService * service;
    UserListDisplayMgr * userListDisplayMgr;
    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    UserListDisplayMgrFactory * userListDisplayMgrFactory;

    UISearchBar * searchBar;
    UIView * darkTransparentView;

    RecentSearchMgr * recentSearchMgr;
    SavedSearchMgr * savedSearchMgr;

    FindPeopleBookmarkViewController * bookmarkController;
    NSManagedObjectContext * context;

    ComposeTweetDisplayMgr * composeTweetDisplayMgr;

    NetworkAwareViewController * nextWrapperController;
    TimelineDisplayMgr * timelineDisplayMgr;
    TwitterCredentials * credentials;
    CredentialsActivatedPublisher * credentialsPublisher;
    UserListDisplayMgr * nextUserListDisplayMgr;

    NSString * currentSearchUsername; // main user search value
    NSString * currentSearch; // mention search value
    SavedSearchMgr * generalSavedSearchMgr;

    BOOL editingQuery;
    BOOL showingAutocompleteResults;
    NSArray * autocompleteArray;
    UIView * autocompleteView;
    UITableView * autoCompleteTableView;

    LocationMapViewController * locationMapViewController;
    LocationInfoViewController * locationInfoViewController;

    BOOL hasBeenDisplayed;
}

@property (nonatomic, retain) NSString * currentSearchUsername;

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    userInfoController:(UserInfoViewController *)userInfoController
    service:(TwitterService *)service context:(NSManagedObjectContext *)aContext
    savedSearchMgr:(SavedSearchMgr *)aSavedSearchMgr
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    userListFactory:(UserListDisplayMgrFactory *)aUserListFactory;

- (void)setCredentials:(TwitterCredentials *)credentials;

- (NSInteger)selectedBookmarkSegment;
- (void)setSelectedBookmarkSegment:(NSInteger)segment;

@end
