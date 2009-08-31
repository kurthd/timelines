//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SearchBookmarksViewController.h"
#import "TwitterService.h"

@class RecentSearchMgr, SavedSearchMgr;

@protocol SearchBookmarksDisplayMgrDelegate

- (void)searchFor:(NSString *)query;
- (void)savedSearchRemoved:(NSString *)query;

@end

@interface SearchBookmarksDisplayMgr :
    NSObject <SearchBookmarksViewControllerDelegate, TwitterServiceDelegate>
{
    id<SearchBookmarksDisplayMgrDelegate> delegate;

    UIViewController * rootViewController;
    SearchBookmarksViewController * searchBookmarksViewController;

    RecentSearchMgr * recentSearchMgr;
    SavedSearchMgr * savedSearchMgr;

    // needed to fetch Twitter trends
    TwitterService * service;
    NSMutableArray * allTrends;  // indexed by trend type

    NSManagedObjectContext * context;
    NSString * accountName;
}

@property (nonatomic, assign) id<SearchBookmarksDisplayMgrDelegate> delegate;
@property (nonatomic, copy, readonly) NSString * accountName;

- (id)initWithAccountName:(NSString *)anAccountName
                  service:(TwitterService *)aService
                  context:(NSManagedObjectContext *)aContext;

- (void)displayBookmarksInRootView:(UIViewController *)aRootViewController;

- (void)addRecentSearch:(NSString *)query;

- (void)addSavedSearch:(NSString *)query;
- (void)removeSavedSearch:(NSString *)query;
- (BOOL)isSearchSaved:(NSString *)query;

- (NSInteger)selectedSegment;
- (void)setSelectedSegment:(NSInteger)segment;

@end
