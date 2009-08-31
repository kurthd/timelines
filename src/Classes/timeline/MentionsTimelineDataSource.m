//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "MentionsTimelineDataSource.h"
#import "Tweet.h"
#import "TweetInfo.h"

@implementation MentionsTimelineDataSource

@synthesize delegate;

- (void)dealloc
{
    [service release];
    [super dealloc];
}

- (id)initWithTwitterService:(TwitterService *)aService
{
    if (self = [super init])
        service = [aService retain];

    return self;
}

#pragma mark TimelineDataSource implementation

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)page;
{
    NSLog(@"'Mentions' data source: fetching timeline");
    [service fetchMentionsSinceUpdateId:updateId page:page
        count:[NSNumber numberWithInt:200]];
}

- (void)fetchUserInfoForUsername:(NSString *)username
{
    NSLog(@"'Mentions' data source: fetching user info");
    [service fetchUserInfoForUsername:username];
}

- (BOOL)readyForQuery
{
    return YES;
}

#pragma mark TwitterServiceDelegate implementation

- (void)mentions:(NSArray *)mentions fetchedSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count;
{
    NSLog(@"'Mentions' data source: received timeline of size %d",
        [mentions count]);
    NSMutableArray * tweetInfoTimeline = [NSMutableArray array];
    for (Tweet * tweet in mentions) {
        TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];
        [tweetInfoTimeline addObject:tweetInfo];
    }
    [delegate timeline:tweetInfoTimeline fetchedSinceUpdateId:updateId
        page:page];
}

- (void)failedToFetchMentionsSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
{
    NSLog(@"'All' data source: failed to retrieve timeline");
    [delegate failedToFetchTimelineSinceUpdateId:updateId page:page
        error:error];
}

- (TwitterCredentials *)credentials
{
    return service.credentials;
}

- (void)setCredentials:(TwitterCredentials *)credentials
{
    [service setCredentials:credentials];
}

@end
