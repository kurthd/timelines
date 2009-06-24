//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "MarkFavoriteResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface MarkFavoriteResponseProcessor ()

@property (nonatomic, copy) NSString * tweetId;
@property (nonatomic, assign) BOOL favorite;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation MarkFavoriteResponseProcessor

@synthesize tweetId, favorite, delegate, context;

+ (id)processorWithTweetId:(NSString *)aTweetId
                  favorite:(BOOL)isFavorite
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithTweetId:aTweetId
                                          favorite:isFavorite
                                           context:aContext
                                          delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.tweetId = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithTweetId:(NSString *)aTweetId
             favorite:(BOOL)isFavorite
              context:(NSManagedObjectContext *)aContext
             delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.tweetId = aTweetId;
        self.favorite = isFavorite;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSAssert1(statuses.count == 1, @"Expected 1 status in response; received "
        "%d.", statuses.count);

    NSDictionary * status = [statuses lastObject];

    NSDictionary * userData = [status objectForKey:@"user"];
    NSString * userId = [[userData objectForKey:@"id"] description];
    User * user = [User userWithId:userId context:context];

    if (!user)
        user = [User createInstance:context];

    [self populateUser:user fromData:userData];

    NSDictionary * tweetData = status;

    NSString * aTweetId = [[tweetData objectForKey:@"id"] description];
    NSAssert2([aTweetId isEqualToString:tweetId], @"Expected to receive "
        "status for tweet '%@', but got '%@' instead.", tweetId, aTweetId);

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

    // favorited status can change for a given tweet
    [tweet setValue:[tweetData objectForKey:@"favorited"]
             forKey:@"favoritedCount"];

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);    

    SEL sel = @selector(tweet:markedAsFavorite:);
    [self invokeSelector:sel withTarget:delegate args:tweet, favorite, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToMarkTweetAsFavorite:favorite:error:);
    [self invokeSelector:sel withTarget:delegate args:tweetId, favorite, error,
        nil];

    return YES;
}

@end
