//
//  Copyright 2010 High Order Bit, Inc. All rights reserved.
//

#import "RetweetsDataSource.h"
#import "Tweet.h"
#import "SettingsReader.h"

@implementation RetweetsDataSource

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
    NSLog(@"'Retweets' data source: fetching timeline");
    [service fetchRetweetsSinceUpdateId:updateId page:page
        count:[NSNumber numberWithInt:[SettingsReader fetchQuantity]]];
}

- (void)fetchUserInfoForUsername:(NSString *)username
{
    NSLog(@"'Retweets' data source: fetching user info");
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
    NSLog(@"'Retweets' data source: received timeline of size %d",
        [mentions count]);
    [delegate timeline:mentions fetchedSinceUpdateId:updateId page:page];
}

- (void)failedToFetchMentionsSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
{
    NSLog(@"'Retweets' data source: failed to retrieve timeline");
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
