//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ResponseProcessor+ParsingHelpers.h"
#import "NSDate+TwitterStringHelpers.h"

@implementation ResponseProcessor (ParsingHelpers)

- (void)populateUser:(User *)user fromData:(NSDictionary *)data
{
    user.username = [data objectForKey:@"screen_name"];
    user.name = [data objectForKey:@"name"];
    user.bio = [data objectForKey:@"description"];
    user.location = [data objectForKey:@"location"];

    // use key-value coding to convert strings to nsnumbers
    NSNumber * friendsCount =
        [NSNumber numberWithLongLong:
        [[data objectForKey:@"friends_count"] longLongValue]];
    user.friendsCount = friendsCount;

    NSNumber * followersCount =
        [NSNumber numberWithLongLong:
        [[data objectForKey:@"followers_count"] longLongValue]];
    user.followersCount = followersCount;

    NSDate * createdAt =
        [NSDate dateWithTwitterUserString:
        [data objectForKey:@"created_at"]];
    user.created = createdAt;

    user.webpage = [data objectForKey:@"url"];
    user.identifier = [[data objectForKey:@"id"] description];
    user.profileImageUrl = [data objectForKey:@"profile_image_url"];
}

- (void)populateTweet:(Tweet *)tweet fromData:(NSDictionary *)data
{
    tweet.identifier = [[data objectForKey:@"id"] description];
    tweet.text = [data objectForKey:@"text"];
    tweet.source = [data objectForKey:@"source"];

    tweet.timestamp =
        [NSDate dateWithTweetString:[data objectForKey:@"created_at"]];

    [tweet setValue:[data objectForKey:@"truncated"]
             forKey:@"truncated"];

    NSNumber * favorited = nil;
    NSString * rawfavorited = [data objectForKey:@"favorited"];
    if (!rawfavorited)
        favorited = [NSNumber numberWithInteger:0];
    else
        favorited = [NSNumber numberWithInteger:[rawfavorited integerValue]];
    tweet.favorited = favorited;

    tweet.inReplyToTwitterUsername =
       [data objectForKey:@"in_reply_to_screen_name"];
    tweet.inReplyToTwitterTweetId =
        [[data objectForKey:@"in_reply_to_status_id"] description];
    tweet.inReplyToTwitterUserId =
        [[data objectForKey:@"in_reply_to_user_id"] description];
}

- (void)populateDirectMessage:(DirectMessage *)dm fromData:(NSDictionary *)data
{
    dm.identifier = [[data objectForKey:@"id"] description];
    dm.text = [data objectForKey:@"text"];
    dm.sourceApiRequestType =
        [[data objectForKey:@"source_api_request_type"] description];

    dm.created =
        [NSDate dateWithTweetString:[data objectForKey:@"created_at"]];
}

@end
