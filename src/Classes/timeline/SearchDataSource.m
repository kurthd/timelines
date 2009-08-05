//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "SearchDataSource.h"
#import "Tweet.h"
#import "TweetInfo.h"

@implementation SearchDataSource

@synthesize delegate, query;

- (void)dealloc
{
    [service release];
    [query release];
    [super dealloc];
}

- (id)initWithTwitterService:(TwitterService *)aService
    query:(NSString *)aQuery
{
    if (self = [super init]) {
        service = [aService retain];
        query = [aQuery copy];
    }

    return self;
}

#pragma mark TimelineDataSource implementation

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)page
{
    if ([self readyForQuery]) {
        NSLog(@"Search data source: fetching timeline for user %@",
            query);
        [service searchFor:query page:page];
    }
}

- (BOOL)readyForQuery
{
    return query && ![query isEqual:@""];
}

#pragma mark TwitterServiceDelegate implementation

- (void)searchResultsReceived:(NSArray *)newSearchResults
    forQuery:(NSString *)query page:(NSNumber *)page
{
    NSMutableArray * tweetInfoTimeline = [NSMutableArray array];
    for (Tweet * tweet in newSearchResults) {
        TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];
        [tweetInfoTimeline addObject:tweetInfo];
    }
    [delegate timeline:tweetInfoTimeline
        fetchedSinceUpdateId:[NSNumber numberWithInt:0] page:page];
}

- (void)failedToFetchSearchResultsForQuery:(NSString *)query
    page:(NSNumber *)page error:(NSError *)error
{
    [delegate failedToFetchTimelineSinceUpdateId:[NSNumber numberWithInt:0]
        page:page error:error];
}

- (TwitterCredentials *)credentials
{
    return service.credentials;
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    [service setCredentials:someCredentials];
}

@end
