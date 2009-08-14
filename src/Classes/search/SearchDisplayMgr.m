//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "Tweet.h"
#import "TweetInfo.h"

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
@synthesize searchResults, queryString, queryTitle, updateId;
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
    self.updateId = anUpdateId;
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
    self.searchResults = newSearchResults;
    if ([query isEqualToString:self.queryString]) {
        NSMutableArray * tweetInfoTimeline = [NSMutableArray array];
        for (Tweet * tweet in searchResults) {
            TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];
            [tweetInfoTimeline addObject:tweetInfo];
        }
        [self.dataSourceDelegate timeline:tweetInfoTimeline
                     fetchedSinceUpdateId:self.updateId
                                     page:page];
    }
}

- (void)failedToFetchSearchResultsForQuery:(NSString *)query
                                      page:(NSNumber *)page
                                     error:(NSError *)error
{
    if ([query isEqualToString:self.queryString])
        [self.dataSourceDelegate failedToFetchTimelineSinceUpdateId:updateId
                                                               page:page
                                                              error:error];
}
 
@end
