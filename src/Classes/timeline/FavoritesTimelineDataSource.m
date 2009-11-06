//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "FavoritesTimelineDataSource.h"
#import "Tweet.h"

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

- (BOOL)readyForQuery
{
    return YES;
}

#pragma mark TwitterServiceDelegate implementation

- (void)favorites:(NSArray *)timeline fetchedForUser:(NSString *)aUsername
    page:(NSNumber *)page
{
    [delegate timeline:timeline fetchedSinceUpdateId:nil page:page];
}

- (void)failedToFetchFavoritesForUser:(NSString *)user page:(NSNumber *)page
    error:(NSError *)error
{
    [delegate failedToFetchTimelineSinceUpdateId:nil page:page error:error];
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
