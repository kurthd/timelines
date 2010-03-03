//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "MarkFavoriteResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "TwitbitShared.h"

@interface MarkFavoriteResponseProcessor ()

@property (nonatomic, copy) NSNumber * tweetId;
@property (nonatomic, assign) BOOL favorite;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation MarkFavoriteResponseProcessor

@synthesize tweetId, favorite, delegate, context;

+ (id)processorWithTweetId:(NSNumber *)aTweetId
                  favorite:(BOOL)isFavorite
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id<TwitterServiceDelegate>)aDelegate
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

- (id)initWithTweetId:(NSNumber *)aTweetId
             favorite:(BOOL)isFavorite
              context:(NSManagedObjectContext *)aContext
             delegate:(id<TwitterServiceDelegate>)aDelegate
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
    NSNumber * userId =
        [[userData objectForKey:@"id"] twitterIdentifierValue];
    User * user = [User findOrCreateWithId:userId context:context];
    [self populateUser:user fromData:userData context:context];

    NSDictionary * tweetData = status;

    NSAssert2(
        [[[tweetData objectForKey:@"id"] description]
        isEqualToString:[tweetId description]],
        @"Expected to receive status for tweet '%@', but got '%@' instead.",
        tweetId, [[tweetData objectForKey:@"id"] description]);

    Tweet * tweet = [Tweet tweetWithId:tweetId context:context];
    if (!tweet)
        tweet = [Tweet createInstance:context];

    [self populateTweet:tweet fromData:tweetData
        isSearchResult:NO context:context];

    // mark the tweet as a favorite or not manually; twitter caches this
    // information, so the received data will be stale
    tweet.favorited = [NSNumber numberWithInteger:favorite ? 1 : 0];
    tweet.user = user;

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);    

    SEL sel = @selector(tweet:markedAsFavorite:);
    if ([delegate respondsToSelector:sel])
        [delegate tweet:tweet markedAsFavorite:favorite];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToMarkTweet:asFavorite:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToMarkTweet:tweetId asFavorite:favorite error:error];

    return YES;
}

@end
