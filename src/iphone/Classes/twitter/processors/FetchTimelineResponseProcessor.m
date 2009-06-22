//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchTimelineResponseProcessor.h"
#import "User.h"
#import "Tweet.h"
#import "NSDate+TwitterStringHelpers.h"
#import "NSObject+RuntimeAdditions.h"  // REMOVE ME

@interface FetchTimelineResponseProcessor ()

@property (nonatomic, copy) NSNumber * updateId;
@property (nonatomic, copy) NSNumber * page;
@property (nonatomic, copy) NSNumber * count;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchTimelineResponseProcessor

@synthesize updateId, page, count, delegate, context;

+ (id)processorWithUpdateId:(NSNumber *)anUpdateId
                       page:(NSNumber *)aPage
                      count:(NSNumber *)aCount
                    context:(NSManagedObjectContext *)aContext
                   delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithUpdateId:anUpdateId
                                               page:aPage
                                              count:aCount
                                            context:aContext
                                           delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.updateId = nil;
    self.page = nil;
    self.count = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithUpdateId:(NSNumber *)anUpdateId
                  page:(NSNumber *)aPage
                 count:(NSNumber *)aCount
               context:(NSManagedObjectContext *)aContext
              delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.updateId = anUpdateId;
        self.page = aPage;
        self.count = aCount;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (void)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return;

    NSMutableArray * tweets = [NSMutableArray arrayWithCapacity:statuses.count];
    NSMutableSet * uniqueUsers = [NSMutableSet set];
    for (id status in statuses) {
        NSDictionary * userData = [status objectForKey:@"user"];

        NSString * userId = [[userData objectForKey:@"id"] description];

        User * user = [User userWithId:userId context:context];
        if (!user)
            user = [User createInstance:context];

        // only set user data the first time we see it, so we are saving
        // the freshest data
        if (![uniqueUsers containsObject:userId]) {
            user.username = [userData objectForKey:@"screen_name"];
            user.name = [userData objectForKey:@"name"];
            user.bio = [userData objectForKey:@"description"];
            user.location = [userData objectForKey:@"location"];

            // use key-value coding to convert strings to nsnumbers
            [user setValue:[userData objectForKey:@"friends_count"]
                    forKey:@"following"];
            [user setValue:[userData objectForKey:@"followers_count"]
                    forKey:@"followers"];

            NSDate * createdAt =
                [NSDate dateWithTwitterUserString:
                [userData objectForKey:@"created_at"]];
            user.created = createdAt;

            user.webpage = [userData objectForKey:@"url"];
            user.identifier = userId;
            user.profileImageUrl = [userData objectForKey:@"profile_image_url"];

            [uniqueUsers addObject:userId];
        }

        NSDictionary * tweetData = status;

        NSString * tweetId = [[tweetData objectForKey:@"id"] description];
        Tweet * tweet = [Tweet tweetWithId:tweetId context:context];

        // everything but the favorited count for tweets doesn't change
        if (!tweet) {
            tweet = [Tweet createInstance:context];

            tweet.identifier = tweetId;
            tweet.text = [tweetData objectForKey:@"text"];
            tweet.source = [tweetData objectForKey:@"source"];

            // already an NSDate instance
            tweet.timestamp = [tweetData objectForKey:@"created_at"];

            [tweet setValue:[tweetData objectForKey:@"truncated"]
                     forKey:@"truncated"];
            tweet.user = user;
        }

        // favorited count can change for a given tweet
        [tweet setValue:[tweetData objectForKey:@"favorited"]
                 forKey:@"favoritedCount"];

        [tweets addObject:tweet];
    }

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);

    SEL sel = @selector(timeline:fetchedSinceUpdateId:page:count:);
    [self invokeSelector:sel withTarget:delegate args:tweets, updateId, page,
        count, nil];
}

- (void)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchTimelineSinceUpdateId:page:count:error:);
    [self invokeSelector:sel withTarget:delegate args:updateId, page, count,
        error, nil];
}

@end
