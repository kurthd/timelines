//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "NSString+HtmlEncodingAdditions.h"
#import "User+UIAdditions.h"
#import "TwitbitShared.h"

@interface NSDictionary (CopyAndPastedParsingHelpers)
- (id)safeObjectForKey:(id)key;
@end

@implementation NSDictionary (CopyAndPastedParsingHelpers)
- (id)safeObjectForKey:(id)key
{
    id obj = [self objectForKey:key];
    return [obj isEqual:[NSNull null]] ? nil : obj;
}
@end

@interface SearchResponseProcessor ()

@property (nonatomic, copy) NSString * query;
@property (nonatomic, copy) NSString * cursor;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;
@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation SearchResponseProcessor

@synthesize query, cursor, delegate, context;

+ (id)processorWithQuery:(NSString *)aQuery
                  cursor:(NSString *)aCursor
                 context:(NSManagedObjectContext *)aContext
                delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[[self class] alloc] initWithQuery:aQuery
                                          cursor:aCursor
                                         context:aContext
                                        delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.query = nil;
    self.cursor = nil;
    self.delegate = nil;
    self.context = nil;
    [super dealloc];
}

- (id)initWithQuery:(NSString *)aQuery
             cursor:(NSString *)aCursor
            context:(NSManagedObjectContext *)aContext
           delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.query = aQuery;
        self.cursor = aCursor;
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

        NSNumber * tweetId =
            [[tweetData objectForKey:@"id"] twitterIdentifierValue];
        Tweet * tweet = [Tweet tweetWithId:tweetId context:context];
        if (!tweet)
            tweet = [Tweet createInstance:context];

        tweet.identifier = tweetId;
        tweet.text = [tweetData safeObjectForKey:@"text"];
        tweet.decodedText = [tweet.text stringByDecodingHtmlEntities];
        tweet.source = [tweetData safeObjectForKey:@"source"];
        tweet.timestamp =
            [[tweetData objectForKey:@"created_at"] twitterDateValue];

        // fill in the rest of the required tweet fields that are not
        // provided as part of the search results
        tweet.truncated = [NSNumber numberWithBool:NO];
        tweet.favorited = [NSNumber numberWithInteger:0];

        tweet.searchResult = [NSNumber numberWithBool:YES];

        tweet.user = tweetAuthor;

        NSDictionary * geodata = [tweetData objectForKey:@"geo"];
        if (geodata && ![geodata isEqual:[NSNull null]]) {
            NSArray * coordinates = [geodata objectForKey:@"coordinates"];

            double lat = [[coordinates objectAtIndex:0] doubleValue];
            double lon = [[coordinates objectAtIndex:1] doubleValue];
            NSNumber * latitude = [NSNumber numberWithDouble:lat];
            NSNumber * longitude = [NSNumber numberWithDouble:lon];

            TweetLocation * loc = tweet.location;
            if (!loc) {
                loc = [TweetLocation createInstance:context];
                tweet.location = loc;
            }
            loc.latitude = latitude;
            loc.longitude = longitude;
        }

        [tweets addObject:tweet];
    }

    NSString * nextCursor = nil;
    if (tweets.count) {
        Tweet * tweet = [tweets objectAtIndex:tweets.count - 1];
        long long val = [tweet.identifier longLongValue] - 1;
        nextCursor = [[NSNumber numberWithLongLong:val] description];
    }

    SEL sel = @selector(searchResultsReceived:nextCursor:forQuery:cursor:);
    if ([delegate respondsToSelector:sel])
        [delegate searchResultsReceived:tweets
                             nextCursor:nextCursor
                               forQuery:query
                                 cursor:cursor];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchSearchResultsForQuery:cursor:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToFetchSearchResultsForQuery:query
                                              cursor:cursor
                                               error:error];

    return YES;
}

@end
