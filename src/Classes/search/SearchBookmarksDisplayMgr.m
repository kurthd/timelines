//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchBookmarksDisplayMgr.h"
#import "RecentSearchMgr.h"
#import "SavedSearchMgr.h"
#import "TrendType.h"

@interface SearchBookmarksDisplayMgr ()

@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) SearchBookmarksViewController *
    searchBookmarksViewController;

@property (nonatomic, retain) RecentSearchMgr * recentSearchMgr;
@property (nonatomic, retain) SavedSearchMgr * savedSearchMgr;

@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, copy) NSString * accountName;

@end

@implementation SearchBookmarksDisplayMgr

@synthesize delegate;
@synthesize rootViewController, searchBookmarksViewController;
@synthesize recentSearchMgr, savedSearchMgr;
@synthesize context, accountName;

- (void)dealloc
{
    self.delegate = nil;

    self.rootViewController = nil;
    self.searchBookmarksViewController = nil;

    self.recentSearchMgr = nil;
    self.savedSearchMgr = nil;

    self.context = nil;
    self.accountName = nil;

    [super dealloc];
}

- (id)initWithAccountName:(NSString *)anAccountName
                  context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.context = aContext;
        self.accountName = anAccountName;
    }

    return self;
}

- (void)displayBookmarksInRootView:(UIViewController *)aRootViewController
{
    self.rootViewController = aRootViewController;
    [self.rootViewController
        presentModalViewController:self.searchBookmarksViewController
                          animated:YES];
}

- (void)addRecentSearch:(NSString *)query
{
    [self.recentSearchMgr addRecentSearch:query];
}

- (void)addSavedSearch:(NSString *)query
{
    [self.savedSearchMgr addSavedSearch:query];
}

- (void)removeSavedSearch:(NSString *)query
{
    [self.savedSearchMgr removeSavedSearchForQuery:query];
}

- (BOOL)isSearchSaved:(NSString *)query
{
    return [self.savedSearchMgr isSearchSaved:query];
}

#pragma mark SearchBookmarksViewControllerDelegate implementation

- (NSArray *)savedSearches
{
    return [self.savedSearchMgr savedSearches];
}

- (BOOL)removeSavedSearchWithQuery:(NSString *)query
{
    [self.savedSearchMgr removeSavedSearchForQuery:query];
    [self.delegate savedSearchRemoved:query];
    return YES;
}

- (void)setSavedSearchOrder:(NSArray *)savedSearches
{
    [self.savedSearchMgr setSavedSearchOrder:savedSearches];
}

- (NSArray *)recentSearches
{
    return [self.recentSearchMgr recentSearches];
}

- (void)clearRecentSearches
{
    [self.recentSearchMgr clear];
}

- (void)userDidSelectSearchQuery:(NSString *)query
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];
    self.rootViewController = nil;

    [self.delegate searchFor:query];
}

- (void)userDidCancel
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];
    self.rootViewController = nil;
}

#pragma mark Accessors

- (SearchBookmarksViewController *)searchBookmarksViewController
{
    if (!searchBookmarksViewController) {
        searchBookmarksViewController =
            [[SearchBookmarksViewController alloc]
            initWithNibName:@"SearchBookmarksView" bundle:nil];
        searchBookmarksViewController.delegate = self;
    }

    return searchBookmarksViewController;
}

- (RecentSearchMgr *)recentSearchMgr
{
    if (!recentSearchMgr)
        recentSearchMgr =
            [[RecentSearchMgr alloc] initWithAccountName:self.accountName
                                                 context:self.context];

    return recentSearchMgr;
}

- (SavedSearchMgr *)savedSearchMgr
{
    if (!savedSearchMgr)
        savedSearchMgr =
            [[SavedSearchMgr alloc] initWithAccountName:self.accountName
                                                     context:self.context];

    return savedSearchMgr;
}

- (NSInteger)selectedSegment
{
    return [self.searchBookmarksViewController selectedSegment];
}

- (void)setSelectedSegment:(NSInteger)segment
{
    [self.searchBookmarksViewController setSelectedSegment:segment];
}

@end
