//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "MessagesTimelineDataSource.h"
#import "DirectMessage.h"
#import "TweetInfo.h"

@interface MessagesTimelineDataSource ()

- (void)sendFetchTimelineResponseWithUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page;

@end
    
@implementation MessagesTimelineDataSource

@synthesize delegate, incomingMessages, outgoingMessages;

- (void)dealloc
{
    [service release];
    [incomingMessages release];
    [outgoingMessages release];
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
    NSLog(@"'Direct messages' data source: fetching timeline");
    outstandingIncomingMessages++;
    outstandingOutgoingMessages++;

    NSNumber * count = [NSNumber numberWithInteger:200];
    [service fetchDirectMessagesSinceId:updateId page:page count:count];
    [service fetchSentDirectMessagesSinceId:updateId page:page count:count];
}

- (void)fetchUserInfoForUsername:(NSString *)username
{
    NSLog(@"'Direct messages' data source: fetching user info");
    [service fetchUserInfoForUsername:username];
}

- (void)fetchFriendsForUser:(NSString *)user page:(NSNumber *)page
{
    NSLog(@"'Direct messages' data source: fetching friends");
    [service fetchFriendsForUser:user page:page];
}

- (void)fetchFollowersForUser:(NSString *)user page:(NSNumber *)page
{
    NSLog(@"'Direct messages' data source: fetching followers");
    [service fetchFollowersForUser:user page:page];
}

- (void)markTweet:(NSString *)tweetId asFavorite:(BOOL)favorite
{
    NSLog(@"'Direct messages' data source: setting tweet favorite state");
    [service markTweet:tweetId asFavorite:favorite];
}

- (void)isUser:(NSString *)user following:(NSString *)followee
{
    NSLog(@"'Direct messages' data source: querying for 'following' state");
    [service isUser:user following:followee];
}

- (void)followUser:(NSString *)aUsername
{
    NSLog(@"'Direct messages' data source: sending 'follow user' request");
    [service followUser:aUsername];
}

- (void)stopFollowingUser:(NSString *)aUsername
{
    NSLog(@"'Direct messages' data source: sending 'stop following' request");
    [service stopFollowingUser:aUsername];
}

- (void)fetchTweet:(NSString *)tweetId
{
    [service fetchTweet:tweetId];
}

#pragma mark TwitterServiceDelegate implementation

- (void)directMessages:(NSArray *)directMessages
    fetchedSinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
{
    NSLog(@"'Messages' data source: received timeline of size %d",
        [directMessages count]);
    NSMutableArray * tweetInfos = [NSMutableArray array];
    for (DirectMessage * directMessage in directMessages) {
        TweetInfo * tweetInfo =
            [TweetInfo createFromDirectMessage:directMessage];
        [tweetInfos addObject:tweetInfo];
    }

    outstandingIncomingMessages--;
    self.incomingMessages = tweetInfos;
    if (outstandingOutgoingMessages == 0 && outstandingIncomingMessages == 0)
        [self sendFetchTimelineResponseWithUpdateId:updateId page:page];
}

- (void)sentDirectMessages:(NSArray *)directMessages
    fetchedSinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
{
    NSLog(@"'Messages' data source: received timeline of size %d",
        [directMessages count]);
    NSMutableArray * tweetInfos = [NSMutableArray array];
    for (DirectMessage * directMessage in directMessages) {
        TweetInfo * tweetInfo =
            [TweetInfo createFromDirectMessage:directMessage];
        [tweetInfos addObject:tweetInfo];
    }

    outstandingOutgoingMessages--;
    self.outgoingMessages = tweetInfos;
    if (outstandingOutgoingMessages == 0 && outstandingIncomingMessages == 0)
        [self sendFetchTimelineResponseWithUpdateId:updateId page:page];
}

- (void)sendFetchTimelineResponseWithUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page
{
    NSMutableArray * messages = [NSMutableArray array];
    [messages addObjectsFromArray:self.incomingMessages];
    [messages addObjectsFromArray:self.outgoingMessages];
    NSLog(@"'Messages' data source: forwarding batched timeline of size %d",
        [messages count]);
    [delegate timeline:messages fetchedSinceUpdateId:updateId page:page];
}
             
- (void)failedToFetchDirectMessagesSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page error:(NSError *)error
{
    NSLog(@"'Messages' data source: failed to retrieve incoming messages");
    [delegate failedToFetchTimelineSinceUpdateId:updateId page:page
        error:error];
}

- (void)failedToFetchSentDirectMessagesSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page error:(NSError *)error
{
    NSLog(@"'Messages' data source: failed to retrieve sent messages");
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

- (void)setCredentials:(TwitterCredentials *)credentials
{
    [service setCredentials:credentials];
}

@end
