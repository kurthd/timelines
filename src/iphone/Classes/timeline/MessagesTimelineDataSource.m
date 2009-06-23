//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "MessagesTimelineDataSource.h"
#import "DirectMessage.h"
#import "TweetInfo.h"

@implementation MessagesTimelineDataSource

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
    NSLog(@"Fetching direct messages...");
    [service fetchDirectMessagesSinceId:updateId page:page];
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
    [delegate timeline:tweetInfos fetchedSinceUpdateId:updateId page:page];
}

- (void)failedToFetchDirectMessagesSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page error:(NSError *)error
{
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
