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

@property (nonatomic, retain) TwitterService * service;
@property (nonatomic, retain) NSMutableArray * allTrends;

@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, copy) NSString * accountName;

- (void)fetchTrendsFromTwitterOfType:(TrendType)trendType;

- (void)processFetchedTrends:(NSArray *)trends ofType:(TrendType)trendType;
- (void)processFailureToFetchTrendsOfType:(TrendType)trendType
                                    error:(NSError *)error;

@end

@implementation SearchBookmarksDisplayMgr

@synthesize delegate;
@synthesize rootViewController, searchBookmarksViewController;
@synthesize recentSearchMgr, savedSearchMgr;
@synthesize service, allTrends;
@synthesize context, accountName;

- (void)dealloc
{
    self.delegate = nil;

    self.rootViewController = nil;
    self.searchBookmarksViewController = nil;

    self.recentSearchMgr = nil;
    self.savedSearchMgr = nil;

    self.service = nil;
    self.allTrends = nil;

    self.context = nil;
    self.accountName = nil;

    [super dealloc];
}

- (id)initWithAccountName:(NSString *)anAccountName
                  service:(TwitterService *)aService
                  context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.context = aContext;
        self.service = aService;
        self.service.delegate = self;
        self.accountName = anAccountName;

        self.allTrends = [NSMutableArray arrayWithObjects:
            [NSNull null], [NSNull null], [NSNull null], nil];
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

- (NSArray *)trendsOfType:(TrendType)trendType refresh:(BOOL)refresh
{
    NSArray * cachedTrends = [self.allTrends objectAtIndex:trendType];
    if (refresh || [cachedTrends isEqual:[NSNull null]]) {
        [self fetchTrendsFromTwitterOfType:trendType];
        return nil;
    } else
        return cachedTrends;
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

#pragma mark Fetch trends

- (void)fetchTrendsFromTwitterOfType:(TrendType)trendType
{
    switch (trendType) {
        case kCurrentTrends:
            NSLog(@"Fetching current trends.");
            [self.service fetchCurrentTrends];
            break;
        case kDailyTrends:
            NSLog(@"Fetching daily trends.");
            [self.service fetchDailyTrends];
            break;
        case kWeeklyTrends:
            NSLog(@"Fetching weekly trends.");
            [self.service fetchWeeklyTrends];
            break;
    }
}

#pragma mark TwitterServiceDelegate implementation

- (void)fetchedCurrentTrends:(NSArray *)trends
{
    [self processFetchedTrends:trends ofType:kCurrentTrends];
}

- (void)failedToFetchCurrentTrends:(NSError *)error
{
    [self processFailureToFetchTrendsOfType:kCurrentTrends error:error];
}

- (void)fetchedDailyTrends:(NSArray *)trends
{
    [self processFetchedTrends:trends ofType:kDailyTrends];
}

- (void)failedToFetchDailyTrends:(NSError *)error
{
    [self processFailureToFetchTrendsOfType:kDailyTrends error:error];
}

- (void)fetchedWeeklyTrends:(NSArray *)trends
{
    [self processFetchedTrends:trends ofType:kWeeklyTrends];
}

- (void)failedToFetchWeeklyTrends:(NSError *)error
{
    [self processFailureToFetchTrendsOfType:kWeeklyTrends error:error];
}

#pragma mark Private implementation

- (void)processFetchedTrends:(NSArray *)trends ofType:(TrendType)trendType
{
    [self.allTrends replaceObjectAtIndex:trendType withObject:trends];
    [self.searchBookmarksViewController trends:trends fetchedForType:trendType];
}

- (void)processFailureToFetchTrendsOfType:(TrendType)trendType
                                    error:(NSError *)error
{
    [self.searchBookmarksViewController failedToFetchTrendsForType:trendType
                                                             error:error];
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

@end
