//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "NearbySearchResponseProcessor.h"
#import "TwitterServiceDelegate.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "NSString+HtmlEncodingAdditions.h"
#import "User+UIAdditions.h"

@interface NSDictionary (SafeAdditions)
- (id)safeObjectForKey:(id)key;
@end

@implementation NSDictionary (SafeAdditions)
- (id)safeObjectForKey:(id)key
{
    id obj = [self objectForKey:key];
    return [obj isEqual:[NSNull null]] ? nil : obj;
}
@end

@interface NearbySearchResponseProcessor ()

@property (nonatomic, copy) NSString * query;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, copy) NSNumber * latitude;
@property (nonatomic, copy) NSNumber * longitude;
@property (nonatomic, copy) NSNumber * radius;
@property (nonatomic, copy) NSNumber * radiusIsInMiles;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation NearbySearchResponseProcessor

@synthesize query, page;
@synthesize latitude, longitude, radius, radiusIsInMiles;
@synthesize delegate, context;

+ (id)processorWithQuery:(NSString *)aQuery
                    page:(NSNumber *)aPage
                latitude:(NSNumber *)aLatitude
               longitude:(NSNumber *)aLongitude
                  radius:(NSNumber *)aRadius
         radiusIsInMiles:(NSNumber *)isRadiusInMiles
                 context:(NSManagedObjectContext *)aContext
                delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithQuery:aQuery
                                            page:aPage
                                        latitude:aLatitude
                                       longitude:aLongitude
                                          radius:aRadius
                                 radiusIsInMiles:isRadiusInMiles
                                         context:aContext
                                        delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.query = nil;
    self.page = nil;
    self.latitude = nil;
    self.longitude = nil;
    self.radius = nil;
    self.radiusIsInMiles = nil;
    self.delegate = nil;
    self.context = nil;
    [super dealloc];
}

- (id)initWithQuery:(NSString *)aQuery
               page:(NSNumber *)aPage
           latitude:(NSNumber *)aLatitude
          longitude:(NSNumber *)aLongitude
             radius:(NSNumber *)aRadius
    radiusIsInMiles:(NSNumber *)isRadiusInMiles
            context:(NSManagedObjectContext *)aContext
           delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.query = aQuery;
        self.page = aPage;
        self.latitude = aLatitude;
        self.longitude = aLongitude;
        self.radius = aRadius;
        self.radiusIsInMiles = isRadiusInMiles;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

#pragma mark Processing responses

- (BOOL)processResponse:(NSArray *)rawSearchResults
{
    if (!rawSearchResults)
        return NO;

    NSDictionary * searchResults = [rawSearchResults objectAtIndex:0];
    NSArray * results = [searchResults objectForKey:@"results"];

    NSMutableArray * tweets = [NSMutableArray arrayWithCapacity:results.count];
    for (NSDictionary * result in results) {
        if ([result objectForKey:@"refresh_url"])
            continue;  // metadata, not a search result

        NSDictionary * userData = result;

        // the user ids in the search result are wrong per twitter:
        //   http://code.google.com/p/twitter-api/issues/detail?id=214
        NSNumber * userId = [userData objectForKey:@"from_user_id"];
        if (!userId)
            continue;  // something is malformed - be defensive and just move on

        User * tweetAuthor = [User findOrCreateWithId:userId context:context];
        tweetAuthor.created = [NSDate date];
        tweetAuthor.username = [userData objectForKey:@"from_user"];
        tweetAuthor.identifier = userId;
        tweetAuthor.avatar.thumbnailImageUrl =
            [userData objectForKey:@"profile_image_url"];
        tweetAuthor.avatar.fullImageUrl =
            [User fullAvatarUrlForUrl:tweetAuthor.avatar.thumbnailImageUrl];

        // fill in the rest of the required user fields that are not
        // provided as part of the search results
        tweetAuthor.followersCount = [NSNumber numberWithInteger:0];
        tweetAuthor.friendsCount = [NSNumber numberWithInteger:0];
        tweetAuthor.name = @"";

        NSDictionary * tweetData = result;

        NSNumber * tweetId = [tweetData objectForKey:@"id"];
        Tweet * tweet = [Tweet tweetWithId:tweetId context:context];
        if (!tweet)
            tweet = [Tweet createInstance:context];

        tweet.identifier = tweetId;
        tweet.text = [tweetData safeObjectForKey:@"text"];
        tweet.source = [tweetData safeObjectForKey:@"source"];
        tweet.timestamp =
            [[tweetData objectForKey:@"created_at"] twitterDateValue];

        // fill in the rest of the required tweet fields that are not
        // provided as part of the search results
        tweet.truncated = [NSNumber numberWithBool:NO];
        tweet.favorited = [NSNumber numberWithInteger:0];

        tweet.user = tweetAuthor;

        [tweets addObject:tweet];
    }

    SEL sel =
        @selector(nearbySearchResultsReceived:forQuery:page:latitude:\
        longitude:radius:radiusIsInMiles:);

    // HACK: cast to the correct type to suppress compiler warnings
    id<TwitterServiceDelegate> theDelegate =
        (id<TwitterServiceDelegate>) delegate;
    if ([theDelegate respondsToSelector:sel])
        [theDelegate nearbySearchResultsReceived:tweets
                                        forQuery:query
                                            page:page
                                        latitude:latitude
                                       longitude:longitude
                                          radius:radius
                                 radiusIsInMiles:radiusIsInMiles.boolValue];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    BOOL inMiles = radiusIsInMiles.boolValue;

    SEL sel =
        @selector(failedToFetchNearbySearchResultsForQuery:page:latitude:\
        longitude:radius:radiusIsInMiles:error:);

    // HACK: cast to the correct type to suppress compiler warnings
    id<TwitterServiceDelegate> theDelegate =
        (id<TwitterServiceDelegate>) delegate;
    if ([theDelegate respondsToSelector:sel])
        [theDelegate failedToFetchNearbySearchResultsForQuery:query
                                                         page:page
                                                     latitude:latitude
                                                    longitude:longitude
                                                       radius:radius
                                              radiusIsInMiles:inMiles
                                                        error:error];

    return YES;
}

@end
