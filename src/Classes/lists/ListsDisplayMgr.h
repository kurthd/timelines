//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "ListsViewController.h"
#import "TwitterService.h"

enum {
    kListRequestTypeInitial,
    kListRequestTypeRefresh,
    kListRequestTypeLoadMore
} ListRequestType;

@interface ListsDisplayMgr :
    NSObject <TwitterServiceDelegate, NetworkAwareViewControllerDelegate>
{
    NetworkAwareViewController * wrapperController;
    UINavigationController * navigationController;
    ListsViewController * listsViewController;
    TwitterService * service;

    BOOL fetchedInitialLists;
    NSUInteger outstandingListRequests;
    NSUInteger outstandingListSubscriptionRequests;
    NSUInteger listRequestType;
    NSString * listsCursor;
    NSString * subscriptionsCursor;
    NSMutableDictionary * lists;
    NSMutableDictionary * subscriptions;
    NSUInteger pagesShown;
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    navigationController:(UINavigationController *)aNavigationController
    listsViewController:(ListsViewController *)listsViewController
    service:(TwitterService *)aService;

- (void)resetState;
- (void)refreshLists;
- (void)loadMoreLists;

@property (nonatomic, assign) BOOL fetchedInitialLists;

@end
