//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SendTweetResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface SendTweetResponseProcessor ()

@property (nonatomic, copy) NSString * text;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation SendTweetResponseProcessor

@synthesize text, context, delegate;

+ (id)processorWithTweet:(NSString *)someText
                 context:(NSManagedObjectContext *)aContext
                delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithTweet:someText
                                         context:aContext
                                        delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.text = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithTweet:(NSString *)someText
            context:(NSManagedObjectContext *)aContext
           delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.text = someText;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (void)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return;

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

    NSError * error;
    if (![context save:&error])
        NSLog(@"Failed to save tweets and users: '%@'", error);

    SEL sel = @selector(tweetSentSuccessfully:);
    [self invokeSelector:sel withTarget:delegate args:tweet, nil];
}

- (void)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToSendTweet:error:);
    [self invokeSelector:sel withTarget:delegate args:text, error, nil];
}

@end
