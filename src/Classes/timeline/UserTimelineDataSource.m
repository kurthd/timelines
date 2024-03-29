//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserTimelineDataSource.h"
#import "Tweet.h"
#import "SettingsReader.h"

@implementation UserTimelineDataSource

@synthesize delegate;

- (void)dealloc
{
    [service release];
    [credentials release];
    [super dealloc];
}

- (id)initWithTwitterService:(TwitterService *)aService
{
    if (self = [super init])
        service = [aService retain];

    return self;
}

#pragma mark TimelineDataSource implementation

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)page
{
    [service fetchTimelineForUser:credentials.username
        sinceUpdateId:updateId page:page
        count:[NSNumber numberWithInt:[SettingsReader fetchQuantity]]];
}

- (BOOL)readyForQuery
{
    return YES;
}

#pragma mark TwitterServiceDelegate implementation

- (void)timeline:(NSArray *)timeline fetchedForUser:(NSString *)user
    sinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
    count:(NSNumber *)count
{
    [delegate timeline:timeline fetchedSinceUpdateId:updateId page:page];
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
    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:credentials];
}

@end
