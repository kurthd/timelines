//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ResponseProcessor+ParsingHelpers.h"
#import "NSDate+TwitterStringHelpers.h"

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

- (void)populateUser:(User *)user fromData:(NSDictionary *)data
{
    user.username = [data safeObjectForKey:@"screen_name"];
    user.name = [data safeObjectForKey:@"name"];
    user.bio = [data safeObjectForKey:@"description"];
    user.location = [data safeObjectForKey:@"location"];

    // use key-value coding to convert strings to nsnumbers
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
    user.profileImageUrl = [data safeObjectForKey:@"profile_image_url"];
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
