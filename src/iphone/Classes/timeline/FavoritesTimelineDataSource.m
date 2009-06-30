//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "FavoritesTimelineDataSource.h"
#import "Tweet.h"
#import "TweetInfo.h"

@implementation FavoritesTimelineDataSource

@synthesize delegate;

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
        service = [aService retain];
        username = [aUsername copy];
    }

    return self;
}

#pragma mark TimelineDataSource implementation

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)page
{
    [service fetchFavoritesForUser:username page:page];
}

- (void)fetchUserInfoForUsername:(NSString *)aUsername
{
    [service fetchUserInfoForUsername:aUsername];
}

- (void)fetchFriendsForUser:(NSString *)user page:(NSNumber *)page
{
    [service fetchFriendsForUser:user page:page];
}

- (void)fetchFollowersForUser:(NSString *)user page:(NSNumber *)page
{
    [service fetchFollowersForUser:user page:page];
}

- (void)markTweet:(NSString *)tweetId asFavorite:(BOOL)favorite
{
    [service markTweet:tweetId asFavorite:favorite];
}

- (void)isUser:(NSString *)user following:(NSString *)followee
{
    [service isUser:user following:followee];
}

- (void)followUser:(NSString *)aUsername
{
    [service followUser:aUsername];
}

- (void)stopFollowingUser:(NSString *)aUsername
{
    [service stopFollowingUser:aUsername];
}

- (void)fetchTweet:(NSString *)tweetId
{
    [service fetchTweet:tweetId];
}

#pragma mark TwitterServiceDelegate implementation

- (void)favorites:(NSArray *)timeline fetchedForUser:(NSString *)aUsername
    page:(NSNumber *)page
{
    NSMutableArray * tweetInfoTimeline = [NSMutableArray array];
    for (Tweet * tweet in timeline) {
        TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];
        [tweetInfoTimeline addObject:tweetInfo];
    }
    [delegate timeline:tweetInfoTimeline fetchedSinceUpdateId:nil page:page];
}

- (void)failedToFetchFavoritesForUser:(NSString *)user page:(NSNumber *)page
    error:(NSError *)error
{
    [delegate failedToFetchTimelineSinceUpdateId:nil page:page error:error];
}

- (void)userInfo:(User *)aUser fetchedForUsername:(NSString *)aUsername
{
    [delegate userInfo:aUser fetchedForUsername:aUsername];
}

- (void)failedToFetchUserInfoForUsername:(NSString *)aUsername
                                   error:(NSError *)error
{
    [delegate failedToFetchUserInfoForUsername:aUsername error:error];
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

- (void)fetchedTweet:(Tweet *)tweet withId:(NSString *)tweetId
{
    [delegate fetchedTweet:tweet withId:tweetId];
}

- (void)failedToFetchTweetWithId:(NSString *)tweetId error:(NSError *)error
{
    [delegate failedToFetchTweetWithId:tweetId error:error];
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