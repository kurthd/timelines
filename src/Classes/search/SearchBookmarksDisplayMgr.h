//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SearchBookmarksViewController.h"

@class RecentSearchMgr, SavedSearchMgr;

@protocol SearchBookmarksDisplayMgrDelegate

- (void)searchFor:(NSString *)query;

@end

@interface SearchBookmarksDisplayMgr :
    NSObject <SearchBookmarksViewControllerDelegate>
{
    id<SearchBookmarksDisplayMgrDelegate> delegate;

    UIViewController * rootViewController;
    SearchBookmarksViewController * searchBookmarksViewController;

    RecentSearchMgr * recentSearchMgr;
    SavedSearchMgr * savedSearchMgr;

    NSManagedObjectContext * context;
    NSString * accountName;
}

@property (nonatomic, assign) id<SearchBookmarksDisplayMgrDelegate> delegate;
@property (nonatomic, copy, readonly) NSString * accountName;

- (id)initWithAccountName:(NSString *)anAccountName
                  context:(NSManagedObjectContext *)aContext;

- (void)displayBookmarksInRootView:(UIViewController *)aRootViewController;

- (void)addRecentSearch:(NSString *)query;

- (void)addSavedSearch:(NSString *)query;
- (void)removeSavedSearch:(NSString *)query;
- (BOOL)isSearchSaved:(NSString *)query;

@end
