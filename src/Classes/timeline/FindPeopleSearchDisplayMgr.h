//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterService.h"
#import "TwitterServiceDelegate.h"
#import "NetworkAwareViewController.h"
#import "FindPeopleBookmarkViewController.h"
#import "RecentSearchMgr.h"
#import "SavedSearchMgr.h"
#import "UserListTableViewController.h"
#import "TimelineDisplayMgrFactory.h"
#import "UserListDisplayMgrFactory.h"
#import "DisplayMgrHelper.h"
#import "ContactCache.h"
#import "ContactMgr.h"

@interface FindPeopleSearchDisplayMgr :
    NSObject
    <TwitterServiceDelegate, UISearchBarDelegate,
    FindPeopleBookmarkViewControllerDelegate,
    NetworkAwareViewControllerDelegate, UserListTableViewControllerDelegate,
    UITableViewDataSource, UITableViewDelegate>
{
    NetworkAwareViewController * netAwareController;
    UserListTableViewController * userListController;
    TwitterService * service;
    UserListDisplayMgr * userListDisplayMgr;
    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    UserListDisplayMgrFactory * userListDisplayMgrFactory;
    ComposeTweetDisplayMgr * composeTweetDisplayMgr;

    DisplayMgrHelper * displayMgrHelper;

    UISearchBar * searchBar;
    UIView * darkTransparentView;

    RecentSearchMgr * recentSearchMgr;
    SavedSearchMgr * savedSearchMgr;

    FindPeopleBookmarkViewController * bookmarkController;
    NSManagedObjectContext * context;

    TimelineDisplayMgr * timelineDisplayMgr;
    UserListDisplayMgr * nextUserListDisplayMgr;
    CredentialsActivatedPublisher * credentialsPublisher;
    NetworkAwareViewController * nextWrapperController;
    TwitterCredentials * credentials;
    BOOL failedState;
    NSMutableDictionary * cache;

    NSString * currentSearchUsername; // main user search value
    NSString * currentSearch; // mention search value
    SavedSearchMgr * generalSavedSearchMgr;

    BOOL editingQuery;
    BOOL showingAutocompleteResults;
    NSArray * autocompleteArray;
    UIView * autocompleteView;
    UITableView * autoCompleteTableView;
    BOOL currentPage;
    BOOL loadingMore;

    BOOL hasBeenDisplayed;
}

@property (nonatomic, retain) NSString * currentSearchUsername;

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    navigationController:(UINavigationController *)aNavigationController
    userListController:(UserListTableViewController *)userListController
    service:(TwitterService *)service context:(NSManagedObjectContext *)aContext
    savedSearchMgr:(SavedSearchMgr *)aSavedSearchMgr
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    userListFactory:(UserListDisplayMgrFactory *)aUserListFactory
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr
    contactCache:(ContactCache *)aContactCache
    contactMgr:(ContactMgr *)aContactMgr;

- (void)setCredentials:(TwitterCredentials *)credentials;

- (void)setNavigationController:(UINavigationController *)nc;
- (UINavigationController *)navigationController;

- (NSInteger)selectedBookmarkSegment;
- (void)setSelectedBookmarkSegment:(NSInteger)segment;

@end
