//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "Tweet.h"
#import "SettingsReader.h"

@interface SearchDisplayMgr ()

@property (nonatomic, retain) NetworkAwareViewController *
    networkAwareViewController;

@property (nonatomic, retain) TwitterService * service;

@property (nonatomic, copy) NSArray * searchResults;
@property (nonatomic, copy) NSString * queryString;
@property (nonatomic, copy) NSString * queryTitle;
@property (nonatomic, copy) NSNumber * updateId;

@end

@implementation SearchDisplayMgr

@synthesize networkAwareViewController;
@synthesize service;
@synthesize searchResults, queryString, queryTitle, nearbySearchLocation,
    updateId;
@synthesize dataSourceDelegate;

#pragma mark Initialization

- (id)initWithTwitterService:(TwitterService *)aService
{
    if (self = [super init]) {
        self.service = aService;
        self.service.delegate = self;
    }

    return self;
}

- (void)dealloc
{
    self.networkAwareViewController = nil;
    self.service = nil;
    self.searchResults = nil;
    self.queryString = nil;
    self.queryTitle = nil;
    self.updateId = nil;
    self.nearbySearchLocation = nil;
    [super dealloc];
}

#pragma mark Display search results

- (void)displaySearchResults:(NSString *)aQueryString
                   withTitle:(NSString *)aTitle
{
    self.searchResults = nil;
    self.queryString = aQueryString;
    self.queryTitle = aTitle;
}

- (void)clearDisplay
{
    self.searchResults = nil;
    self.queryString = nil;
    self.queryTitle = nil;
}

#pragma mark TimelineDataSource implementation

- (void)fetchTimelineSince:(NSNumber *)anUpdateId page:(NSNumber *)page
{
    NSLog(@"Search display manager: fetching timeline");

    // HACK: Force the query string to be non-nil here. If the query string
    // is nil, and the search is submitted, the results will not be
    // displayed when passed to the delegate method in this class because
    // a nil query string will be sent to Twitter as '(null)' through the
    // stringWithFormat: formatter, causing the query string comparison
    // (comparing what was searched for to what was received) to fail.
    if (!self.queryString)
        self.queryString = @"";

    self.updateId = anUpdateId;
    if (self.nearbySearchLocation) {
        NSNumber * radius =
            [NSNumber numberWithInt:[SettingsReader nearbySearchRadius]];
        NSNumber * latitude =
            [NSNumber numberWithDouble:
            self.nearbySearchLocation.coordinate.latitude];
        NSNumber * longitude =
            [NSNumber numberWithDouble:
            self.nearbySearchLocation.coordinate.longitude];

        NSLog(@"Searching for '%@' in a radius of %@km.", self.queryString,
            radius);
        [service searchFor:self.queryString page:page latitude:latitude
            longitude:longitude radius:radius radiusIsInMiles:NO];
    } else
        [service searchFor:self.queryString page:page];
}

- (TwitterCredentials *)credentials
{
    return service.credentials;
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    [service setCredentials:someCredentials];
}

- (BOOL)readyForQuery
{
    return !!self.queryString;
}

#pragma mark TwitterServiceDelegate

- (void)searchResultsReceived:(NSArray *)newSearchResults
                     forQuery:(NSString *)query
                         page:(NSNumber *)page
{
    if ([query isEqualToString:self.queryString] &&
        !self.nearbySearchLocation) {
        self.searchResults = newSearchResults;
        [self.dataSourceDelegate timeline:self.searchResults
                     fetchedSinceUpdateId:self.updateId
                                     page:page];
    }
}

- (void)failedToFetchSearchResultsForQuery:(NSString *)query
                                      page:(NSNumber *)page
                                     error:(NSError *)error
{
    if ([query isEqualToString:self.queryString] && !self.nearbySearchLocation)
        [self.dataSourceDelegate failedToFetchTimelineSinceUpdateId:updateId
                                                               page:page
                                                              error:error];
}

- (void)nearbySearchResultsReceived:(NSArray *)newSearchResults
                           forQuery:(NSString *)query
                               page:(NSNumber *)page
                           latitude:(NSNumber *)latitude
                          longitude:(NSNumber *)longitude
                             radius:(NSNumber *)radius
                    radiusIsInMiles:(BOOL)radiusIsInMiles
{
    if ([query isEqualToString:self.queryString] && self.nearbySearchLocation) {
        self.searchResults = newSearchResults;
        [self.dataSourceDelegate timeline:self.searchResults
                     fetchedSinceUpdateId:self.updateId
                                     page:page];
    }
}

- (void)failedToFetchNearbySearchResultsForQuery:(NSString *)query
                                            page:(NSNumber *)page
                                        latitude:(NSNumber *)latitude
                                       longitude:(NSNumber *)longitude
                                          radius:(NSNumber *)radius
                                 radiusIsInMiles:(BOOL)radiusIsInMiles
                                           error:(NSError *)error
{
    if ([query isEqualToString:self.queryString] && self.nearbySearchLocation)
        [self.dataSourceDelegate failedToFetchTimelineSinceUpdateId:updateId
                                                               page:page
                                                              error:error];
}
 
@end
