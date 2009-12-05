//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "SearchDataSource.h"
#import "Tweet.h"

@interface SearchDataSource ()
@property (nonatomic, copy) NSString * cursor;
@property (nonatomic, copy) NSNumber * page;
@end

@implementation SearchDataSource

@synthesize delegate, query, cursor, page;

- (void)dealloc
{
    [service release];
    [query release];
    [cursor release];
    [page release];
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

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)aPage
{
    if ([self readyForQuery]) {
        NSLog(@"Search data source: fetching timeline for user %@",
            query);
        [service searchFor:query cursor:self.cursor];
        self.page = aPage;
    }
}

- (BOOL)readyForQuery
{
    return query && ![query isEqual:@""];
}

#pragma mark TwitterServiceDelegate implementation

- (void)searchResultsReceived:(NSArray *)newSearchResults
                   nextCursor:(NSString *)nextCursor
                     forQuery:(NSString *)query
                       cursor:(NSString *)cursor
{
    self.cursor = nextCursor;
    [delegate timeline:newSearchResults
        fetchedSinceUpdateId:[NSNumber numberWithInt:0] page:self.page];
}

- (void)failedToFetchSearchResultsForQuery:(NSString *)query
    cursor:(NSString *)cursor error:(NSError *)error
{
    [delegate failedToFetchTimelineSinceUpdateId:[NSNumber numberWithInt:0]
        page:self.page error:error];
}

- (TwitterCredentials *)credentials
{
    return service.credentials;
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    [service setCredentials:someCredentials];
}

#pragma mark Accessors

- (void)setQuery:(NSString *)aQuery
{
    NSString * tmp = [aQuery copy];
    [query release];
    query = tmp;

    self.cursor = nil;  // reset search pagination
    self.page = nil;
}

@end
