//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ListTimelineDataSource.h"
#import "SettingsReader.h"

@implementation ListTimelineDataSource

@synthesize delegate;

- (void)dealloc
{
    [service release];
    [username release];
    [listId release];
    [super dealloc];
}

- (id)initWithTwitterService:(TwitterService *)aService
    username:(NSString *)aUsername listId:(NSNumber *)aListId
{
    if (self = [super init]) {
        service = [aService retain];
        username = [aUsername retain];
        listId = [aListId retain];
    }

    return self;
}

#pragma mark TimelineDataSource implementation

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)page
{
    NSLog(@"Fetching list timeline...");
    NSLog(@"List id: %@", listId);
    NSLog(@"Username: %@", username);
    NSNumber * count = [NSNumber numberWithInt:[SettingsReader fetchQuantity]];
    [service fetchStatusesForListWithId:listId ownedByUser:username
        sinceUpdateId:updateId page:page count:count];
}

- (BOOL)readyForQuery
{
    return YES;
}

#pragma mark TwitterServiceDelegate implementation

- (void)statuses:(NSArray *)statuses fetchedForListId:(NSNumber *)listId
    ownedByUser:(NSString *)username sinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count
{
    [delegate timeline:statuses fetchedSinceUpdateId:nil page:page];
}

- (void)failedToFetchStatusesForListId:(NSNumber *)listId
    ownedByUser:(NSString *)username sinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
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
