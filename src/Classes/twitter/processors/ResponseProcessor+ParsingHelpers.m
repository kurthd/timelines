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
#import "User+UIAdditions.h"

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

@implementation ResponseProcessor (ParsingHelpers)

- (Tweet *)createTweetFromStatus:(NSDictionary *)status
                        username:(NSString *)username
                     credentials:(TwitterCredentials *)credentials
                         context:(NSManagedObjectContext *)context
{
    NSDictionary * userData = [status objectForKey:@"user"];
    NSDictionary * tweetData = status;

    // If the user has an empty timeline, there will be one element and none
    // of the required data will be available.
    if (!userData)
        return nil;

    if (![userData objectForKey:@"profile_image_url"]) {
        if ([userData objectForKey:@"text"]) {
            //
            // This is a retweet message. It comes down with fields in the
            // wrong places, so we're going to normalize the data so
            // parsing can proceed normally.
            //

            NSMutableDictionary * userDataMutable = [tweetData mutableCopy];
            NSMutableDictionary * tweetDataMutable = [userData mutableCopy];

            //
            // Swap the IDs and created dates of the user and tweet
            //

            NSNumber * userId = [tweetData objectForKey:@"id"];
            NSNumber * tweetId = [userData objectForKey:@"id"];
            [userDataMutable setObject:userId forKey:@"id"];
            [tweetDataMutable setObject:tweetId forKey:@"id"];

            //
            // Extract user fields that are in the tweet section of the
            // data and insert them into the user section.
            //

            NSString * username =
                [tweetDataMutable objectForKey:@"screen_name"];
            NSString * description =
                [tweetDataMutable objectForKey:@"description"];
            NSString * url = [tweetDataMutable objectForKey:@"url"];
            NSNumber * nfollowers =
                [tweetDataMutable objectForKey:@"followers_count"];

            [userDataMutable setObject:username forKey:@"screen_name"];
            [userDataMutable setObject:description forKey:@"description"];
            [userDataMutable setObject:url forKey:@"url"];
            [userDataMutable setObject:nfollowers forKey:@"followers_count"];

            userData = userDataMutable;
            tweetData = tweetDataMutable;
        } else
            return nil;
    }

    NSString * userId = [[userData objectForKey:@"id"] description];
    User * tweetAuthor = [User findOrCreateWithId:userId context:context];
    [self populateUser:tweetAuthor fromData:userData];

    NSString * tweetId = [[tweetData objectForKey:@"id"] description];
    Tweet * tweet = [Tweet tweetWithId:tweetId context:context];
    if (!tweet) {
        if (username)
            tweet = [Tweet createInstance:context];
        else {
            UserTweet * userTweet = [UserTweet createInstance:context];
            userTweet.credentials = credentials;
            tweet = userTweet;
        }
    }

    [self populateTweet:tweet fromData:tweetData];
    tweet.user = tweetAuthor;

    return tweet;
}

- (void)populateUser:(User *)user fromData:(NSDictionary *)data
{
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

    user.created = [data safeObjectForKey:@"created_at"];

    user.webpage = [data safeObjectForKey:@"url"];
    user.identifier = [[data safeObjectForKey:@"id"] description];
    user.avatar.thumbnailImageUrl =
        [data safeObjectForKey:@"profile_image_url"];
    user.avatar.fullImageUrl =
        [User fullAvatarUrlForUrl:user.avatar.thumbnailImageUrl];

    [user setValue:[data objectForKey:@"statuses_count"]
            forKey:@"statusesCount"];
}

- (void)populateTweet:(Tweet *)tweet fromData:(NSDictionary *)data
{
    tweet.identifier = [[data safeObjectForKey:@"id"] description];
    tweet.text = [data safeObjectForKey:@"text"];
    tweet.source = [data safeObjectForKey:@"source"];

    tweet.timestamp = [data safeObjectForKey:@"created_at"];

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
}

- (void)populateDirectMessage:(DirectMessage *)dm fromData:(NSDictionary *)data
{
    dm.identifier = [[data objectForKey:@"id"] description];
    dm.text = [data objectForKey:@"text"];
    dm.sourceApiRequestType =
        [[data objectForKey:@"source_api_request_type"] description];

    dm.created = [data objectForKey:@"created_at"];
}

@end
