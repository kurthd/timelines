//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ResponseProcessor+ParsingHelpers.h"
#import "NSDate+TwitterStringHelpers.h"
#import "Avatar.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "UserTweet.h"
#import "UserTweet+CoreDataAdditions.h"
#import "User+UIAdditions.h"
#import "NSDictionary+GeneralHelpers.h"
#import "TweetLocation.h"
#import "TwitbitShared.h"

@interface NSDictionary (ParsingHelpers)
- (id)safeObjectForKey:(id)key;
@end

@implementation NSDictionary (ParsingHelpers)
- (id)safeObjectForKey:(id)key
{
    id obj = [self objectForKey:key];
    return [obj isEqual:[NSNull null]] ? nil : obj;
}
@end

@implementation NSString (ParsingHelpers)

- (NSDate *)twitterDateValue
{
    struct tm theTime;
    strptime([self UTF8String], "%a %b %d %H:%M:%S +0000 %Y", &theTime);
    time_t epochTime = timegm(&theTime);

    // jad: HACK: Search results are returned with a different format
    // than tweets, so if parsing the string failed, try the search
    // results format.
    //
    // This code should be changed to just return the string value and
    // the date can be parsed at a higher level.
    if (epochTime == -1) {
        strptime([self UTF8String], "%a, %d %b %Y %H:%M:%S +0000", &theTime);
        epochTime = timegm(&theTime);
    }

    return [NSDate dateWithTimeIntervalSince1970:epochTime];
}

@end


@interface ResponseProcessor (PrivateParsingHelpers)

- (BOOL)normalizeTweetDataIfNecessary:(NSMutableDictionary **)tweetDataPtr
                             userData:(NSMutableDictionary **)userDataPtr;

- (BOOL)isValidUserData:(NSDictionary *)userData;
- (BOOL)isValidTweetData:(NSDictionary *)tweetData;

- (NSDate *)dateValue:(NSString *)s;

@end

@implementation ResponseProcessor (ParsingHelpers)

- (Tweet *)createTweetFromStatus:(NSDictionary *)status
                     isUserTweet:(BOOL)isUserTweet
                  isSearchResult:(BOOL)isSearchResult
                     credentials:(TwitterCredentials *)credentials
                         context:(NSManagedObjectContext *)context
{
    // If the user has an empty timeline, there will be one element and none
    // of the required data will be available.
    if (![status objectForKey:@"user"])
        return nil;

    NSMutableDictionary * userData =
        [[[status objectForKey:@"user"] mutableCopy] autorelease];
    NSMutableDictionary * tweetData = [[status mutableCopy] autorelease];

    [self normalizeTweetDataIfNecessary:&tweetData userData:&userData];

    BOOL isValidData =
        [self isValidUserData:userData] && [self isValidTweetData:tweetData];
    if (!isValidData) {
        NSLog(@"WARNING: Skipping parsing of invalid tweet: %@.", status);
        return nil;
    }

    NSNumber * userId = [[userData objectForKey:@"id"] twitterIdentifierValue];
    User * tweetAuthor = [User findOrCreateWithId:userId context:context];
    [self populateUser:tweetAuthor fromData:userData];

    NSNumber * tweetId =
        [[tweetData objectForKey:@"id"] twitterIdentifierValue];
    Tweet * tweet = nil;
    if (isUserTweet)
        tweet = [UserTweet tweetWithId:tweetId
                           credentials:credentials
                               context:context];
    else
        tweet = [Tweet tweetWithId:tweetId context:context];

    if (!tweet) {
        if (isUserTweet) {
            UserTweet * userTweet = [UserTweet createInstance:context];
            userTweet.credentials = credentials;
            tweet = userTweet;
        } else
            tweet = [Tweet createInstance:context];
    }

    [self populateTweet:tweet fromData:tweetData
        isSearchResult:isSearchResult context:context];
    tweet.user = tweetAuthor;

    if (credentials && [credentials.username isEqual:tweetAuthor.username])
        credentials.user = tweetAuthor;

    NSAssert1(tweet.source, @"Failed to parse tweet: %@", status);
    NSAssert1(tweetAuthor.username, @"Failed to parse tweet: %@", status);

    return tweet;
}

- (Mention *)createMentionFromStatus:(NSDictionary *)status
                         credentials:(TwitterCredentials *)credentials
                             context:(NSManagedObjectContext *)context
{
    // If the user has an empty timeline, there will be one element and none
    // of the required data will be available.
    if (![status objectForKey:@"user"])
        return nil;

    NSMutableDictionary * userData =
        [[[status objectForKey:@"user"] mutableCopy] autorelease];
    NSMutableDictionary * tweetData = [[status mutableCopy] autorelease];

    [self normalizeTweetDataIfNecessary:&tweetData userData:&userData];

    BOOL isValidData =
        [self isValidUserData:userData] && [self isValidTweetData:tweetData];
    if (!isValidData) {
        NSLog(@"WARNING: Skipping parsing of invalid mention: %@.", status);
        return nil;
    }

    NSNumber * userId = [[userData objectForKey:@"id"] twitterIdentifierValue];
    User * tweetAuthor = [User findOrCreateWithId:userId context:context];
    [self populateUser:tweetAuthor fromData:userData];

    NSNumber * tweetId =
        [[tweetData objectForKey:@"id"] twitterIdentifierValue];
    Mention * tweet = [Mention tweetWithId:tweetId context:context];
    if (!tweet)
        tweet = [Mention createInstance:context];
    [self populateTweet:tweet fromData:tweetData
        isSearchResult:NO context:context];
    tweet.user = tweetAuthor;
    tweet.credentials = credentials;

    if ([credentials.username isEqualToString:tweetAuthor.username])
        credentials.user = tweetAuthor;

    return tweet;
}

- (void)populateUser:(User *)user fromData:(NSDictionary *)data
{
    /*
     * Any numeric value created by the JSON parser is an NSDecimalNumber
     * instance. Convert them all to NSNumbers as appropriate.
     */

    user.identifier = [[data safeObjectForKey:@"id"] twitterIdentifierValue];
    user.username = [data safeObjectForKey:@"screen_name"];

    user.name = [data safeObjectForKey:@"name"];
    user.bio = [data safeObjectForKey:@"description"];
    user.location = [data safeObjectForKey:@"location"];

    NSNumber * friendsCount =
        [NSNumber numberWithInteger:
        [[data safeObjectForKey:@"friends_count"] integerValue]];
    user.friendsCount = friendsCount;

    NSNumber * followersCount =
        [NSNumber numberWithInteger:
        [[data safeObjectForKey:@"followers_count"] integerValue]];
    user.followersCount = followersCount;

    user.created = [[data safeObjectForKey:@"created_at"] twitterDateValue];
    user.webpage = [data safeObjectForKey:@"url"];

    user.avatar.thumbnailImageUrl =
        [data safeObjectForKey:@"profile_image_url"];
    user.avatar.fullImageUrl =
        [User fullAvatarUrlForUrl:user.avatar.thumbnailImageUrl];

    NSDecimalNumber * count = [data objectForKey:@"statuses_count"];
    NSString * scount = [count description];
    [user setValue:[NSNumber numberWithInteger:[scount integerValue]]
            forKey:@"statusesCount"];

    user.geoEnabled = [data objectForKey:@"geo_enabled"];
}

- (void)populateTweet:(Tweet *)tweet
             fromData:(NSDictionary *)data
       isSearchResult:(BOOL)isSearchResult
              context:(NSManagedObjectContext *)context
{
    /*
     * Any numeric value created by the JSON parser is an NSDecimalNumber
     * instance. Convert them all to NSNumbers as appropriate.
     */

    tweet.identifier = [[data safeObjectForKey:@"id"] twitterIdentifierValue];
    tweet.text = [data safeObjectForKey:@"text"];
    tweet.decodedText = [tweet.text stringByDecodingHtmlEntities];
    tweet.source = [data safeObjectForKey:@"source"];

    tweet.timestamp = [[data safeObjectForKey:@"created_at"] twitterDateValue];

    [tweet setValue:[data safeObjectForKey:@"truncated"]
             forKey:@"truncated"];

    NSNumber * favoriteValue = [data safeObjectForKey:@"favorited"];
    BOOL isFavorite = favoriteValue && [favoriteValue boolValue];
    tweet.favorited = [NSNumber numberWithInteger:isFavorite ? 1 : 0];

    tweet.inReplyToTwitterUsername =
       [data safeObjectForKey:@"in_reply_to_screen_name"];
    tweet.inReplyToTwitterTweetId =
        [[data safeObjectForKey:@"in_reply_to_status_id"]
        twitterIdentifierValue];
    tweet.inReplyToTwitterUserId =
        [[data safeObjectForKey:@"in_reply_to_user_id"] description];

    tweet.searchResult = [NSNumber numberWithBool:isSearchResult];

    NSDictionary * geodata = [data objectForKey:@"geo"];
    if (geodata && ![geodata isEqual:[NSNull null]]) {
        NSLog(@"Have geo data: %@", geodata);
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
}

- (void)populateDirectMessage:(DirectMessage *)dm fromData:(NSDictionary *)data
{
    /*
     * Any numeric value created by the JSON parser is an NSDecimalNumber
     * instance. Convert them all to NSNumbers as appropriate.
     */

    dm.identifier = [[data objectForKey:@"id"] twitterIdentifierValue];
    dm.text = [data objectForKey:@"text"];
    dm.sourceApiRequestType =
        [[data objectForKey:@"source_api_request_type"] description];

    dm.created = [[data objectForKey:@"created_at"] twitterDateValue];
}

- (void)populateList:(TwitterList *)list fromData:(NSDictionary *)data
{
    /*
     * Any numeric value created by the JSON parser is an NSDecimalNumber
     * instance. Convert them all to NSNumbers as appropriate.
     */

    list.identifier = [[data objectForKey:@"id"] twitterIdentifierValue];
    list.fullName = [data objectForKey:@"full_name"];

    NSString * count = [[data objectForKey:@"member_count"] description];
    list.memberCount = [NSNumber numberWithInteger:[count integerValue]];

    list.mode = [data objectForKey:@"mode"];
    list.name = [data objectForKey:@"name"];
    list.slug = [data objectForKey:@"slug"];
    list.subscriberCount = [data objectForKey:@"subscriber_count"];
    list.uri = [data objectForKey:@"uri"];
}

#pragma mark Private implementation

- (BOOL)normalizeTweetDataIfNecessary:(NSMutableDictionary **)tweetDataPtr
                             userData:(NSMutableDictionary **)userDataPtr
{
    NSMutableDictionary * tweetData = *tweetDataPtr;
    NSMutableDictionary * userData = *userDataPtr;

    if (![userData objectForKey:@"profile_image_url"]) {
        if ([userData objectForKey:@"text"]) {
            //
            // This is a retweet message. It comes down with fields in the
            // wrong places, so we're going to normalize the data so
            // parsing can proceed normally.
            //

            NSMutableDictionary * actualUserData = tweetData;
            NSMutableDictionary * actualTweetData = userData;

            //
            // Swap the IDs and created dates of the user and tweet
            //

            NSNumber * userId =
                [[tweetData objectForKey:@"id"] twitterIdentifierValue];
            NSNumber * tweetId =
                [[userData objectForKey:@"id"] twitterIdentifierValue];
            [actualUserData setObject:userId forKey:@"id"];
            [actualTweetData setObject:tweetId forKey:@"id"];

            //
            // Extract user fields that are in the tweet section of the
            // data and insert them into the user section.
            //

            NSString * username =
                [actualTweetData objectForKey:@"screen_name"];
            NSString * description =
                [actualTweetData objectForKey:@"description"];
            NSString * url = [actualTweetData objectForKey:@"url"];
            NSNumber * nfollowers =
                [actualTweetData objectForKey:@"followers_count"];

            [actualUserData setObject:username forKey:@"screen_name"];
            [actualUserData setObject:description forKey:@"description"];
            [actualUserData setObject:url forKey:@"url"];
            [actualUserData setObject:nfollowers forKey:@"followers_count"];

            *tweetDataPtr = actualTweetData;
            *userDataPtr = actualUserData;

            return YES;
        }
    }

    return NO;
}

- (BOOL)isValidUserData:(NSDictionary *)userData
{
    static NSArray * requiredFields = nil;
    if (!requiredFields)
        requiredFields =
            [[NSArray alloc] initWithObjects:
            @"id", @"screen_name", @"name", @"friends_count",
            @"followers_count", @"created_at", @"profile_image_url", nil];

    return [userData containsKeys:requiredFields];
}

- (BOOL)isValidTweetData:(NSDictionary *)tweetData
{
    static NSArray * requiredFields = nil;
    if (!requiredFields)
        requiredFields =
            [[NSArray alloc] initWithObjects:
            @"id", @"text", @"source", @"created_at", @"truncated", @"favorited",
            nil];

    return [tweetData containsKeys:requiredFields];
}

@end

@implementation NSNumber (ParsingHelpers)

- (NSNumber *)twitterIdentifierValue
{
    NSString * desc = [self description];
    long long val = [desc longLongValue];
    return [NSNumber numberWithLongLong:val];
}

@end