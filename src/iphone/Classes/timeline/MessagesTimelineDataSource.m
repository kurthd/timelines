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

@synthesize delegate;

- (void)dealloc
{
    [service release];
    [messages release];
    [super dealloc];
}

- (id)initWithTwitterService:(TwitterService *)aService
{
    if (self = [super init]) {
        service = [aService retain];
        messages = [[NSMutableArray array] retain];
    }

    return self;
}

#pragma mark TimelineDataSource implementation

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)page;
{
    NSLog(@"Fetching direct messages...");
    outstandingRequests = 2;
    [service fetchDirectMessagesSinceId:updateId page:page];
    [service fetchSentDirectMessagesSinceId:updateId page:page];
}

- (void)fetchUserInfoForUsername:(NSString *)username
{
    [service fetchUserInfoForUsername:username];
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

#pragma mark TwitterServiceDelegate implementation

- (void)directMessages:(NSArray *)directMessages
    fetchedSinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
{
    NSMutableArray * tweetInfos = [NSMutableArray array];
    for (DirectMessage * directMessage in directMessages) {
        TweetInfo * tweetInfo =
            [TweetInfo createFromDirectMessage:directMessage];
        [tweetInfos addObject:tweetInfo];
    }
    
    outstandingRequests--;
    [messages addObjectsFromArray:tweetInfos];
}

- (void)sentDirectMessages:(NSArray *)directMessages
    fetchedSinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
{
    NSMutableArray * tweetInfos = [NSMutableArray array];
    for (DirectMessage * directMessage in directMessages) {
        TweetInfo * tweetInfo =
            [TweetInfo createFromDirectMessage:directMessage];
        [tweetInfos addObject:tweetInfo];
    }
    
    outstandingRequests--;
    [messages addObjectsFromArray:tweetInfos];
    if (outstandingRequests == 0)
        [self sendFetchTimelineResponseWithUpdateId:updateId page:page];
}

- (void)sendFetchTimelineResponseWithUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page
{
    [delegate timeline:messages fetchedSinceUpdateId:updateId page:page];
    [messages removeAllObjects];
}
             
- (void)failedToFetchDirectMessagesSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page error:(NSError *)error
{
    [delegate failedToFetchTimelineSinceUpdateId:updateId page:page
        error:error];
}

- (void)failedToFetchSentDirectMessagesSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page error:(NSError *)error
{
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

- (TwitterCredentials *)credentials
{
    return service.credentials;
}

- (void)setCredentials:(TwitterCredentials *)credentials
{
    [service setCredentials:credentials];
}

@end
