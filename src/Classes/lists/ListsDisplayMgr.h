//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "ListsViewController.h"
#import "TwitterService.h"
#import "TimelineDisplayMgr.h"
#import "TimelineDisplayMgrFactory.h"
#import "TimelineSelectionViewController.h"

enum {
    kListRequestTypeInitial,
    kListRequestTypeRefresh,
    kListRequestTypeLoadMore
} ListRequestType;

@interface ListsDisplayMgr :
    NSObject <TwitterServiceDelegate, NetworkAwareViewControllerDelegate,
    ListsViewControllerDelegate>
{
    NetworkAwareViewController * wrapperController;
    UINavigationController * navigationController;
    TimelineSelectionViewController * listsViewController;
    TwitterService * service;
    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    ComposeTweetDisplayMgr * composeTweetDisplayMgr;
    NSManagedObjectContext * context;
    
    BOOL fetchedInitialLists;
    NSUInteger outstandingListRequests;
    NSUInteger outstandingListSubscriptionRequests;
    NSUInteger listRequestType;
    NSString * listsCursor;
    NSString * subscriptionsCursor;
    NSMutableDictionary * lists;
    NSMutableDictionary * subscriptions;
    NSUInteger pagesShown;
    
    NetworkAwareViewController * nextWrapperController;
    TimelineDisplayMgr * timelineDisplayMgr;
    CredentialsActivatedPublisher * credentialsPublisher;
    
    TwitterCredentials * credentials;
    
    UIBarButtonItem * updatingListsActivityView;
    UIBarButtonItem * refreshButton;
}

@property (nonatomic, assign) BOOL fetchedInitialLists;
@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) UIBarButtonItem * refreshButton;

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    navigationController:(UINavigationController *)aNavigationController
    listsViewController:(TimelineSelectionViewController *)listsViewController
    service:(TwitterService *)aService
    factory:(TimelineDisplayMgrFactory *)timelineDisplayMgrFactory
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    context:(NSManagedObjectContext *)context;

- (void)resetState;
- (void)refreshLists;
- (void)loadMoreLists;

- (void)displayLists:(NSArray *)lists;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
