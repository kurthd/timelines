//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "AllTimelineDataSource.h"
#import "Tweet.h"
#import "TweetInfo.h"

@implementation AllTimelineDataSource

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
    NSLog(@"'All' data source: fetching timeline");
    [service fetchTimelineSinceUpdateId:updateId page:page
        count:[NSNumber numberWithInt:0]];
}

- (void)fetchUserInfoForUsername:(NSString *)username
{
    NSLog(@"'All' data source: fetching user info");
    [service fetchUserInfoForUsername:username];
}

- (void)fetchFriendsForUser:(NSString *)user page:(NSNumber *)page
{
    NSLog(@"'All' data source: fetching friends");
    [service fetchFriendsForUser:user page:page];
}

- (void)fetchFollowersForUser:(NSString *)user page:(NSNumber *)page
{
    NSLog(@"'All' data source: fetching followers");
    [service fetchFollowersForUser:user page:page];
}

- (void)markTweet:(NSString *)tweetId asFavorite:(BOOL)favorite
{
    NSLog(@"'All' data source: marking tweet favorite state");
    [service markTweet:tweetId asFavorite:favorite];
}

- (void)isUser:(NSString *)user following:(NSString *)followee
{
    NSLog(@"'All' data source: querying following state");
    [service isUser:user following:followee];
}

- (void)followUser:(NSString *)aUsername
{
    NSLog(@"'All' data source: sending 'follow user' request");
    [service followUser:aUsername];
}

- (void)stopFollowingUser:(NSString *)aUsername
{
    NSLog(@"'All' data source: sending 'stop following user' request");
    [service stopFollowingUser:aUsername];
}

#pragma mark TwitterServiceDelegate implementation

- (void)timeline:(NSArray *)timeline fetchedSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count
{
    NSLog(@"'All' data source: received timeline of size %d", [timeline count]);
    NSMutableArray * tweetInfoTimeline = [NSMutableArray array];
    for (Tweet * tweet in timeline) {
        TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];
        [tweetInfoTimeline addObject:tweetInfo];
    }
    [delegate timeline:tweetInfoTimeline fetchedSinceUpdateId:updateId
        page:page];
}

- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
{
    NSLog(@"'All' data source: failed to retrieve timeline");
    [delegate failedToFetchTimelineSinceUpdateId:updateId page:page
        error:error];
}

- (void)userInfo:(User *)aUser fetchedForUsername:(NSString *)username
{
    [delegate userInfo:aUser fetchedForUsername:username];
}

- (void)failedToFetchUserInfoForUsername:(NSString *)username
    error:(NSError *)error
{
    [delegate failedToFetchUserInfoForUsername:username error:error];
}

- (void)friends:(NSArray *)friends fetchedForUsername:(NSString *)aUsername
    page:(NSNumber *)page
{
    [delegate friends:friends fetchedForUsername:aUsername page:page];
}

- (void)failedToFetchFriendsForUsername:(NSString *)aUsername
    page:(NSNumber *)page error:(NSError *)error
{
    [delegate failedToFetchFriendsForUsername:aUsername page:page error:error];
}

- (void)followers:(NSArray *)friends fetchedForUsername:(NSString *)aUsername
            page:(NSNumber *)page
{
    [delegate followers:friends fetchedForUsername:aUsername page:page];
}

- (void)failedToFetchFollowersForUsername:(NSString *)aUsername
    page:(NSNumber *)page error:(NSError *)error
{
    [delegate failedToFetchFollowersForUsername:aUsername page:page
        error:error];
}

- (void)startedFollowingUsername:(NSString *)aUsername
{
    [delegate startedFollowingUsername:aUsername];
}

- (void)failedToStartFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    [delegate failedToStartFollowingUsername:aUsername];
}

- (void)stoppedFollowingUsername:(NSString *)aUsername
{
    [delegate stoppedFollowingUsername:aUsername];
}

- (void)failedToStopFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    [delegate failedToStopFollowingUsername:aUsername];
}

- (void)user:(NSString *)aUsername isFollowing:(NSString *)followee
{
    [delegate user:aUsername isFollowing:followee];
}

- (void)user:(NSString *)aUsername isNotFollowing:(NSString *)followee
{
    [delegate user:aUsername isNotFollowing:followee];
}

- (void)failedToQueryIfUser:(NSString *)aUsername
    isFollowing:(NSString *)followee error:(NSError *)error
{
    [delegate failedToQueryIfUser:aUsername isFollowing:followee error:error];
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
