//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "MessagesTimelineDataSource.h"

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
    [service fetchTimelineSinceUpdateId:updateId page:page
        count:[NSNumber numberWithInt:0]];
}

#pragma mark TwitterServiceDelegate implementation

- (void)timeline:(NSArray *)timeline fetchedSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count
{
    [delegate timeline:timeline fetchedSinceUpdateId:updateId page:page];
}

- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
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
