//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ArbUserTimelineDataSource.h"
#import "Tweet.h"
#import "TweetInfo.h"

@implementation ArbUserTimelineDataSource

@synthesize delegate, username;

- (void)dealloc
{
    [service release];
    [username release];
    [super dealloc];
}

- (id)initWithTwitterService:(TwitterService *)aService
    username:(NSString *)aUsername
{
    if (self = [super init]) {
        NSLog(@"Arbitrary user data source: initializing with %@", aUsername);
        service = [aService retain];
        username = [aUsername copy];
    }

    return self;
}

#pragma mark TimelineDataSource implementation

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)page
{
    if ([self readyForQuery]) {
        NSLog(@"Arbitraty user data source: fetching timeline for user %@",
            username);
        [service fetchTimelineForUser:username sinceUpdateId:updateId page:page
            count:[NSNumber numberWithInt:200]];
    }
}

- (BOOL)readyForQuery
{
    return username && ![username isEqual:@""];
}

#pragma mark TwitterServiceDelegate implementation

- (void)timeline:(NSArray *)timeline fetchedForUser:(NSString *)user
    sinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
    count:(NSNumber *)count
{
    NSMutableArray * tweetInfoTimeline = [NSMutableArray array];
    for (Tweet * tweet in timeline) {
        TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];
        [tweetInfoTimeline addObject:tweetInfo];
    }
    [delegate timeline:tweetInfoTimeline fetchedSinceUpdateId:updateId
        page:page];
}

- (void)failedToFetchTimelineForUser:(NSString *)user
    sinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
    count:(NSNumber *)count error:(NSError *)error
{
    [delegate failedToFetchTimelineSinceUpdateId:updateId page:page
        error:error];
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
