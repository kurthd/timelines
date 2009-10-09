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

@interface NSString (ParsingHelpers)
- (NSDate *)twitterDateValue;
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

    NSString * userId = [[userData objectForKey:@"id"] description];
    User * tweetAuthor = [User findOrCreateWithId:userId context:context];
    [self populateUser:tweetAuthor fromData:userData];

    NSString * tweetId = [[tweetData objectForKey:@"id"] description];
    Tweet * tweet = nil;
    if (isUserTweet)
        tweet = [UserTweet tweetWithId:tweetId
                           credentials:credentials
                               context:context];
    else
        [Tweet tweetWithId:tweetId context:context];

    if (!tweet) {
        if (isUserTweet) {
            UserTweet * userTweet = [UserTweet createInstance:context];
            userTweet.credentials = credentials;
            tweet = userTweet;
        } else
            tweet = [Tweet createInstance:context];
    }

    [self populateTweet:tweet fromData:tweetData context:context];
    tweet.user = tweetAuthor;

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

    NSString * userId = [[userData objectForKey:@"id"] description];
    User * tweetAuthor = [User findOrCreateWithId:userId context:context];
    [self populateUser:tweetAuthor fromData:userData];

    NSString * tweetId = [[tweetData objectForKey:@"id"] description];
    Mention * tweet = [Mention tweetWithId:tweetId context:context];
    if (!tweet)
        tweet = [Mention createInstance:context];
    [self populateTweet:tweet fromData:tweetData context:context];
    tweet.user = tweetAuthor;
    tweet.credentials = credentials;

    return tweet;
}

- (void)populateUser:(User *)user fromData:(NSDictionary *)data
{
    user.identifier = [[data safeObjectForKey:@"id"] description];
    user.username = [data safeObjectForKey:@"screen_name"];

    user.name = [data safeObjectForKey:@"name"];
    user.bio = [data safeObjectForKey:@"description"];
    user.location = [data safeObjectForKey:@"location"];

    NSNumber * friendsCount =
        [NSNumber numberWithLongLong:
        [[data safeObjectForKey:@"friends_count"] longLongValue]];
    user.friendsCount = friendsCount;

    NSNumber * followersCount =
        [NSNumber numberWithLongLong:
        [[data safeObjectForKey:@"followers_count"] longLongValue]];
    user.followersCount = followersCount;

    user.created = [[data safeObjectForKey:@"created_at"] twitterDateValue];
    user.webpage = [data safeObjectForKey:@"url"];

    user.avatar.thumbnailImageUrl =
        [data safeObjectForKey:@"profile_image_url"];
    user.avatar.fullImageUrl =
        [User fullAvatarUrlForUrl:user.avatar.thumbnailImageUrl];

    [user setValue:[data objectForKey:@"statuses_count"]
            forKey:@"statusesCount"];

    NSNumber * geoEnabled = [data objectForKey:@"geo_enabled"];
    user.geoEnabled = [NSNumber numberWithBool:[geoEnabled integerValue] == 1];
}

- (void)populateTweet:(Tweet *)tweet
             fromData:(NSDictionary *)data
              context:(NSManagedObjectContext *)context
{
    tweet.identifier = [[data safeObjectForKey:@"id"] description];
    tweet.text = [data safeObjectForKey:@"text"];
    tweet.source = [data safeObjectForKey:@"source"];

    tweet.timestamp = [[data safeObjectForKey:@"created_at"] twitterDateValue];

    [tweet setValue:[data safeObjectForKey:@"truncated"]
             forKey:@"truncated"];

    NSNumber * favorited = nil;
    NSString * rawfavorited = [data safeObjectForKey:@"favorited"];
    if (!rawfavorited)
        favorited = [NSNumber numberWithInteger:0];
    else
        favorited = [NSNumber numberWithInteger:[rawfavorited integerValue]];
    tweet.favorited = favorited;

    tweet.inReplyToTwitterUsername =
       [data safeObjectForKey:@"in_reply_to_screen_name"];
    tweet.inReplyToTwitterTweetId =
        [[data safeObjectForKey:@"in_reply_to_status_id"] description];
    tweet.inReplyToTwitterUserId =
        [[data safeObjectForKey:@"in_reply_to_user_id"] description];

    if ([tweet.text isEqual:@"i finally (blanked) the (blank). whew"])
        NSLog(@"here's the tweet: %@", data);

    NSDictionary * geodata = [data objectForKey:@"geo"];
    if (geodata && ![geodata isEqual:[NSNull null]]) {
        NSLog(@"Have geo data");
        NSArray * coordinates = [geodata objectForKey:@"coordinates"];
        NSNumber * latitude = [coordinates objectAtIndex:0];
        NSNumber * longitude = [coordinates objectAtIndex:1];

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
    dm.identifier = [[data objectForKey:@"id"] description];
    dm.text = [data objectForKey:@"text"];
    dm.sourceApiRequestType =
        [[data objectForKey:@"source_api_request_type"] description];

    dm.created = [[data objectForKey:@"created_at"] twitterDateValue];
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

            NSNumber * userId = [tweetData objectForKey:@"id"];
            NSNumber * tweetId = [userData objectForKey:@"id"];
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
