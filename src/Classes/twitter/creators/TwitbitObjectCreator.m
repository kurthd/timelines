//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitbitObjectCreator.h"
#import "TwitbitShared.h"

@interface UserTwitbitObjectCreator ()
- (void)populateUser:(User *)user fromJson:(NSDictionary *)json;
@end

@implementation UserTwitbitObjectCreator

- (void)dealloc
{
    [context release];
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext
{
    if (self = [super init])
        context = [aContext retain];

    return self;
}

#pragma mark TwitbitObjectCreator implementation

- (id)createObjectFromJson:(NSDictionary *)json
{
    NSNumber * userId = [[json objectForKey:@"id"] twitterIdentifierValue];
    User * user = [User userWithId:userId context:context];
    if (!user) {
        user = [User createInstance:context];
        [self populateUser:user fromJson:json];
    }

    return user;
}

#pragma mark Protected implementation

- (void)populateUser:(User *)user fromJson:(NSDictionary *)json
{
    user.identifier = [[json safeObjectForKey:@"id"] twitterIdentifierValue];
    user.username = [json safeObjectForKey:@"screen_name"];

    user.name = [json safeObjectForKey:@"name"];
    user.bio = [json safeObjectForKey:@"description"];
    user.location = [json safeObjectForKey:@"location"];

    NSNumber * friendsCount =
        [NSNumber numberWithInteger:
        [[json safeObjectForKey:@"friends_count"] integerValue]];
    user.friendsCount = friendsCount;

    NSNumber * followersCount =
        [NSNumber numberWithInteger:
        [[json safeObjectForKey:@"followers_count"] integerValue]];
    user.followersCount = followersCount;

    user.created = [json safeObjectForKey:@"created_at"];
    user.webpage = [json safeObjectForKey:@"url"];

    user.avatar.thumbnailImageUrl =
        [json safeObjectForKey:@"profile_image_url"];
    user.avatar.fullImageUrl =
        [User fullAvatarUrlForUrl:user.avatar.thumbnailImageUrl];

    NSDecimalNumber * count = [json objectForKey:@"statuses_count"];
    NSString * scount = [count description];
    [user setValue:[NSNumber numberWithInteger:[scount integerValue]]
            forKey:@"statusesCount"];

    user.geoEnabled = [json objectForKey:@"geo_enabled"];
}

@end



@implementation TweetTwitbitObjectCreator

- (void)dealloc
{
    [context release];
    [userCreator release];
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext
                       userCreator:(id<TwitbitObjectCreator>)aUserCreator
{
    if (self = [super init]) {
        context = [aContext retain];
        userCreator = [aUserCreator retain];
    }

    return self;
}

#pragma mark TwitbitObjectCreator implementation

- (id)createObjectFromJson:(NSDictionary *)json
{
    Tweet * tweet = [self createInstance:json];
    if (tweet) {
        [self populateTweet:tweet fromJson:json];

        NSDictionary * userJson = [json objectForKey:@"user"];
        User * user = [userCreator createObjectFromJson:userJson];

        tweet.user = user;
    }

    return tweet;
}

#pragma mark Protected implementation

- (Tweet *)findTweetWithId:(NSNumber *)tweetId
{
    return [Tweet tweetWithId:tweetId context:context];
}

- (Tweet *)createInstance:(NSDictionary *)json
{
    Tweet * tweet = [Tweet createInstance:context];
    tweet.searchResult = [NSNumber numberWithBool:NO];

    return tweet;
}

- (void)populateTweet:(Tweet *)tweet fromJson:(NSDictionary *)json
{
    tweet.identifier = [json safeObjectForKey:@"id"];
    tweet.text = [json safeObjectForKey:@"text"];
    tweet.decodedText = [json objectForKey:@"twitbit_decoded_text"];
    tweet.source = [json safeObjectForKey:@"source"];

    tweet.timestamp = [json safeObjectForKey:@"created_at"];

    [tweet setValue:[json safeObjectForKey:@"truncated"]
             forKey:@"truncated"];

    NSNumber * favoriteValue = [json safeObjectForKey:@"favorited"];
    BOOL isFavorite = favoriteValue && [favoriteValue boolValue];
    tweet.favorited = [NSNumber numberWithInteger:isFavorite ? 1 : 0];

    tweet.inReplyToTwitterUsername =
       [json safeObjectForKey:@"in_reply_to_screen_name"];
    tweet.inReplyToTwitterTweetId =
        [json safeObjectForKey:@"in_reply_to_status_id"];
    tweet.inReplyToTwitterUserId =
        [json safeObjectForKey:@"in_reply_to_user_id"];

    NSDictionary * geojson = [json safeObjectForKey:@"geo"];
    if (geojson) {
        NSArray * coordinates = [geojson objectForKey:@"coordinates"];

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

    NSDictionary * retweetJson = [json safeObjectForKey:@"retweeted_status"];
    if (retweetJson) {
        Tweet * retweet = [self createObjectFromJson:retweetJson];
        tweet.retweet = retweet;
    }
}

@end




@implementation UserEntityTwitbitObjectCreator

- (void)dealloc
{
    [entityName release];
    [credentials release];
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)ctxt
                       userCreator:(id<TwitbitObjectCreator>)uc
                       credentials:(TwitterCredentials *)cdtls
                        entityName:(NSString *)aName
{
    if (self = [super initWithManagedObjectContext:ctxt userCreator:uc]) {
        credentials = [cdtls retain];
        entityName = [aName copy];
    }

    return self;
}

#pragma mark Protected implementation

- (id)createInstance:(NSDictionary *)json
{
    id object =
        [NSEntityDescription insertNewObjectForEntityForName:entityName
                                      inManagedObjectContext:context];
    [object setValue:credentials forKey:@"credentials"];

    return object;
}

@end



@interface DirectMessageTwitbitObjectCreator ()
- (void)populateDirectMessage:(DirectMessage *)dm fromJson:(NSDictionary *)json;
@end

@implementation DirectMessageTwitbitObjectCreator

- (void)dealloc
{
    [context release];
    [userCreator release];
    [credentials release];
    [super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)ctxt
                       userCreator:(id<TwitbitObjectCreator>)uc
                       credentials:(TwitterCredentials *)cdtls
{
    if (self = [super init]) {
        context = [ctxt retain];
        userCreator = [uc retain];
        credentials = [cdtls retain];
    }

    return self;
}

#pragma mark TwitbitObjectCreator implementation

- (id)createObjectFromJson:(NSDictionary *)json
{
    DirectMessage * dm = [DirectMessage createInstance:context];
    if (dm) {
        [self populateDirectMessage:dm fromJson:json];

        NSDictionary * senderJson = [json objectForKey:@"sender"];
        User * sender = [userCreator createObjectFromJson:senderJson];
        dm.sender = sender;

        NSDictionary * recipientJson = [json objectForKey:@"recipient"];
        User * recipient = [userCreator createObjectFromJson:recipientJson];
        dm.recipient = recipient;
    }

    return dm;
}

#pragma mark Private implementation

- (void)populateDirectMessage:(DirectMessage *)dm fromJson:(NSDictionary *)json
{
    dm.identifier = [json objectForKey:@"id"];
    dm.text = [json objectForKey:@"text"];
    dm.sourceApiRequestType = [json objectForKey:@"source_api_request_type"];
    dm.created = [json objectForKey:@"created_at"];
}


@end

