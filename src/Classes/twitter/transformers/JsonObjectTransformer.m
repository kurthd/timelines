//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "JsonObjectTransformer.h"
#import "TwitbitShared.h"

@interface SimpleJsonObjectTransformer ()
- (NSMutableDictionary *)transformTweet:(NSDictionary *)tweet;
- (NSMutableDictionary *)transformUser:(NSDictionary *)user;
@end

@implementation SimpleJsonObjectTransformer

+ (id)instance
{
    id userTransformer = [UserJsonObjectTransformer instance];
    return [[[self alloc] initWithUserTransformer:userTransformer] autorelease];
}

- (void)dealloc
{
    [userTransformer release];
    [super dealloc];
}

- (id)initWithUserTransformer:(id<JsonObjectTransformer>)aUserTransformer
{
    if (self = [super init])
        userTransformer = [aUserTransformer retain];

    return self;
}

#pragma mark JsonObjectTransformer implementation

- (id)transformObject:(NSDictionary *)object
{
    NSDictionary * transformedTweet = [self transformTweet:object];
    return transformedTweet;
}

- (NSMutableDictionary *)transformTweet:(NSDictionary *)tweet
{
    NSMutableDictionary * transformed = [[tweet mutableCopy] autorelease];

    NSNumber * tweetId =
        [[tweet safeObjectForKey:@"id"] twitterIdentifierValue];
    [transformed setObject:tweetId forKey:@"id"];

    NSString * decodedText =
        [[tweet safeObjectForKey:@"text"] stringByDecodingHtmlEntities];
    [transformed setObject:decodedText forKey:@"twitbit_decoded_text"];

    NSDate * timestamp =
        [[tweet safeObjectForKey:@"created_at"] twitterDateValue];
    [transformed setObject:timestamp forKey:@"created_at"];

    NSNumber * favoriteValue = [tweet safeObjectForKey:@"favorited"];
    BOOL isFavorite = favoriteValue && [favoriteValue boolValue];
    NSNumber * favorited = [NSNumber numberWithBool:isFavorite];
    [transformed setObject:favorited forKey:@"favorited"];

    NSNumber * inReplyToId =
        [[tweet safeObjectForKey:@"in_reply_to_status_id"]
        twitterIdentifierValue];
    if (inReplyToId)
        [transformed setObject:inReplyToId forKey:@"in_reply_to_status_id"];

    NSString * inReplyToUserId =
        [[tweet safeObjectForKey:@"in_reply_to_user_id"] description];
    if (inReplyToUserId)
        [transformed setObject:inReplyToUserId forKey:@"in_reply_to_user_id"];

    NSDictionary * geodata = [tweet safeObjectForKey:@"geo"];
    if (geodata) {
        NSMutableDictionary * transformedGeodata =
            [[geodata mutableCopy] autorelease];

        NSArray * coordinates = [geodata objectForKey:@"coordinates"];

        double lat = [[coordinates objectAtIndex:0] doubleValue];
        double lon = [[coordinates objectAtIndex:1] doubleValue];
        NSNumber * latitude = [NSNumber numberWithDouble:lat];
        NSNumber * longitude = [NSNumber numberWithDouble:lon];

        NSArray * transformedCoordinates =
            [NSArray arrayWithObjects:latitude, longitude, nil];

        [transformedGeodata setObject:transformedCoordinates
                               forKey:@"coordinates"];

        [transformed setObject:transformedGeodata forKey:@"geo"];
    }

    NSDictionary * user = [tweet objectForKey:@"user"];
    NSDictionary * transformedUser = [self transformUser:user];
    [transformed setObject:transformedUser forKey:@"user"];

    NSDictionary * retweet = [tweet objectForKey:@"retweeted_status"];
    if (retweet) {
        NSDictionary * transformedRetweet = [self transformTweet:retweet];
        [transformed setObject:transformedRetweet forKey:@"retweeted_status"];
    }

    return transformed;
}

- (NSMutableDictionary *)transformUser:(NSDictionary *)user
{
    return [userTransformer transformObject:user];
}

@end



@implementation UserJsonObjectTransformer

+ (id)instance
{
    return [[[self alloc] init] autorelease];
}

- (id)transformObject:(NSDictionary *)user
{
    NSMutableDictionary * transformed = [[user mutableCopy] autorelease];

    NSNumber * userId = [[user safeObjectForKey:@"id"] twitterIdentifierValue];
    [transformed setObject:userId forKey:@"id"];

    NSNumber * friendsCount =
        [NSNumber numberWithInteger:
        [[user safeObjectForKey:@"friends_count"] integerValue]];
    [transformed setObject:friendsCount forKey:@"friends_count"];

    NSNumber * followersCount =
        [NSNumber numberWithInteger:
        [[user safeObjectForKey:@"followers_count"] integerValue]];
    [transformed setObject:followersCount forKey:@"followers_count"];

    NSDate * created =
        [[user safeObjectForKey:@"created_at"] twitterDateValue];
    [transformed setObject:created forKey:@"created_at"];

    NSString * thumbnailUrl = [user objectForKey:@"profile_image_url"];
    NSString * fullUrl = [User fullAvatarUrlForUrl:thumbnailUrl];
    [transformed setObject:fullUrl forKey:@"twitbit_user_full_url"];

    NSDecimalNumber * originalCount = [user objectForKey:@"statuses_count"];
    NSString * countAsString = [originalCount description];
    NSNumber * count =
        [NSNumber numberWithInteger:[countAsString integerValue]];
    [transformed setObject:count forKey:@"statuses_count"];

    return transformed;
}

@end



@implementation DirectMessageJsonObjectTransformer

+ (id)instance
{
    id userTransformer = [UserJsonObjectTransformer instance];
    return [[[self alloc] initWithUserTransformer:userTransformer] autorelease];
}

- (void)dealloc
{
    [userTransformer release];
    [super dealloc];
}

- (id)initWithUserTransformer:(id<JsonObjectTransformer>)aUserTransformer
{
    if (self = [super init])
        userTransformer = [aUserTransformer retain];

    return self;
}

#pragma mark JsonObjectTransformer implementation

- (id)transformObject:(NSDictionary *)jsonObject
{
    NSMutableDictionary * transformed = [[jsonObject mutableCopy] autorelease];

    NSNumber * identifier =
        [[jsonObject objectForKey:@"id"] twitterIdentifierValue];
    [transformed setObject:identifier forKey:@"id"];

    NSString * sourceType =
        [[jsonObject objectForKey:@"source_api_request_type"] description];
    [transformed setObject:sourceType forKey:@"source_api_request_type"];

    NSDate * created =
        [[jsonObject objectForKey:@"created_at"] twitterDateValue];
    [transformed setObject:created forKey:@"created_at"];

    NSDictionary * sender = [jsonObject objectForKey:@"sender"];
    NSDictionary * transformedSender = [userTransformer transformObject:sender];
    [transformed setObject:transformedSender forKey:@"sender"];

    NSDictionary * recipient = [jsonObject objectForKey:@"recipient"];
    NSDictionary * transformedRecipient =
        [userTransformer transformObject:recipient];
    [transformed setObject:transformedRecipient forKey:@"recipient"];

    return transformed;
}

@end
