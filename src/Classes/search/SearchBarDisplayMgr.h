//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterService.h"
#import "NetworkAwareViewController.h"
#import "SearchDisplayMgr.h"
#import "TimelineDisplayMgr.h"
#import "CredentialsActivatedPublisher.h"
#import "SearchBookmarksDisplayMgr.h";

@interface SearchBarDisplayMgr : NSObject
    <TwitterServiceDelegate, UISearchBarDelegate,
    SearchBookmarksDisplayMgrDelegate, UITableViewDataSource,
    UITableViewDelegate, NetworkAwareViewControllerDelegate,
    CLLocationManagerDelegate>
{
    TwitterService * service;
    NSManagedObjectContext * context;

    NetworkAwareViewController * networkAwareViewController;
    UISearchBar * searchBar;

    TimelineDisplayMgr * timelineDisplayMgr;
    SearchDisplayMgr * searchDisplayMgr;
    SearchBookmarksDisplayMgr * searchBookmarksDisplayMgr;

    NSArray * searchResults;
    NSString * searchQuery;
    NSNumber * searchPage;

    id<TimelineDataSourceDelegate> dataSourceDelegate;

    CredentialsActivatedPublisher * credentialsActivatedPublisher;

    UIView * darkTransparentView;

    BOOL editingQuery;
    BOOL showingAutocompleteResults;
    NSArray * autocompleteArray;
    UIView * autocompleteView;
    UITableView * autoCompleteTableView;

    BOOL hasBeenDisplayed;
    BOOL nearbySearch;
    UIBarButtonItem * nearbySearchProgressView;
    CLLocationManager * locationMgr;
    UIBarButtonItem * locationButton;
}

@property (nonatomic, copy) NSString * searchQuery;
@property (nonatomic, assign) id<TimelineDataSourceDelegate> dataSourceDelegate;
@property (nonatomic, assign) BOOL nearbySearch;

- (id)initWithTwitterService:(TwitterService *)aService
          netAwareController:(NetworkAwareViewController *)navc
          timelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr
                     context:(NSManagedObjectContext *)aContext;

- (void)setCredentials:(TwitterCredentials *)credentials;

- (void)searchBarViewWillAppear:(BOOL)promptUser;

- (NSInteger)selectedBookmarkSegment;
- (void)setSelectedBookmarkSegment:(NSInteger)segment;

@end
