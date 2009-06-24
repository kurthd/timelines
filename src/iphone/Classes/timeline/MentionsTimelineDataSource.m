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
    [service fetchMentionsSinceUpdateId:updateId page:page
        count:[NSNumber numberWithInt:0]];
}

- (void)fetchUserInfoForUsername:(NSString *)username
{
    [service fetchUserInfoForUsername:username];
}

#pragma mark TwitterServiceDelegate implementation

- (void)mentions:(NSArray *)mentions fetchedSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count;
{
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

- (TwitterCredentials *)credentials
{
    return service.credentials;
}

- (void)setCredentials:(TwitterCredentials *)credentials
{
    [service setCredentials:credentials];
}

@end
