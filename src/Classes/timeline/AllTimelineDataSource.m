//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "AllTimelineDataSource.h"
#import "Tweet.h"
#import "SettingsReader.h"

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
    NSLog(@"'All' data source: fetching timeline (updateId: %@, page: %@)",
        updateId, page);
    [service fetchTimelineSinceUpdateId:updateId page:page
        count:[NSNumber numberWithInt:[SettingsReader fetchQuantity]]];
}

- (BOOL)readyForQuery
{
    return YES;
}

#pragma mark TwitterServiceDelegate implementation

- (void)timeline:(NSArray *)timeline fetchedSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count
{
    NSLog(@"'All' data source: received timeline of size %d", [timeline count]);
    [delegate timeline:timeline fetchedSinceUpdateId:updateId page:page];
}

- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)updateId
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
