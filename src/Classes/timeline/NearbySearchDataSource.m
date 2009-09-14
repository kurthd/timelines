//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "NearbySearchDataSource.h"
#import "Tweet.h"
#import "TweetInfo.h"

@implementation NearbySearchDataSource

@synthesize delegate, latitude, longitude, radiusInKm;

- (void)dealloc
{
    [service release];
    [latitude release];
    [longitude release];
    [radiusInKm release];
    [super dealloc];
}

- (id)initWithTwitterService:(TwitterService *)aService
    latitude:(NSNumber *)lat longitude:(NSNumber *)lon
    radiusInKm:(NSNumber *)radius
{
    if (self = [super init]) {
        service = [aService retain];
        latitude = [lat copy];
        longitude = [lon copy];
        radiusInKm = [radius copy];
    }

    return self;
}

#pragma mark TimelineDataSource implementation

- (void)fetchTimelineSince:(NSNumber *)updateId page:(NSNumber *)page
{
    NSLog(@"Nearby search data source: fetching timeline");
    [service searchFor:@"" page:page latitude:latitude longitude:longitude
        radius:radiusInKm radiusIsInMiles:NO];
}

- (BOOL)readyForQuery
{
    return YES;
}

#pragma mark TwitterServiceDelegate implementation

- (void)nearbySearchResultsReceived:(NSArray *)searchResults
                           forQuery:(NSString *)query
                               page:(NSNumber *)page
                           latitude:(NSNumber *)latitude
                          longitude:(NSNumber *)longitude
                             radius:(NSNumber *)radius
                    radiusIsInMiles:(BOOL)radiusIsInMiles
{
    NSMutableArray * tweetInfoTimeline = [NSMutableArray array];
    for (Tweet * tweet in searchResults) {
        TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];
        [tweetInfoTimeline addObject:tweetInfo];
    }
    [delegate timeline:tweetInfoTimeline
        fetchedSinceUpdateId:[NSNumber numberWithInt:0] page:page];
}

- (void)failedToFetchNearbySearchResultsForQuery:(NSString *)searchResults
                                            page:(NSNumber *)page
                                        latitude:(NSNumber *)latitude
                                       longitude:(NSNumber *)longitude
                                          radius:(NSNumber *)radius
                                 radiusIsInMiles:(BOOL)radiusIsInMiles
                                           error:(NSError *)error
{
    NSLog(@"Nearby search data source: search failed");
    [delegate failedToFetchTimelineSinceUpdateId:[NSNumber numberWithInt:0]
        page:page error:error];
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
