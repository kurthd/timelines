//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DeleteTweetResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "ResponseProcessor+ParsingHelpers.h"

@interface DeleteTweetResponseProcessor ()

@property (nonatomic, copy) NSString * tweetId;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation DeleteTweetResponseProcessor

@synthesize tweetId, context, delegate;

+ (id)processorWithTweetId:(NSString *)aTweetId
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id)aDelegate
{
    id obj = [[[self class] alloc] initWithTweetId:aTweetId
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
              context:(NSManagedObjectContext *)aContext
             delegate:(id)aDelegate
{
    if (self = [super init]) {
        self.tweetId = aTweetId;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}

- (BOOL)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSLog(@"Statuses: %@.", statuses);
    return YES;

    /*
    NSAssert1(statuses.count == 1, @"Expected 1 status in response; received "
        "%d.", statuses.count);

    NSDictionary * status = [statuses objectAtIndex:0];

    NSDictionary * userData = [status objectForKey:@"user"];
    NSString * userId = [[userData objectForKey:@"id"] description];
    User * user = [User findOrCreateWithId:userId context:context];

    [self populateUser:user fromData:userData];

    NSDictionary * tweetData = status;

    NSString * receivedTweetId = [[tweetData objectForKey:@"id"] description];
    NSAssert2([tweetId isEqual:receivedTweetId], @"Expected to receive tweet "
        "with id '%@' but received '%@' instead.", tweetId, receivedTweetId);
    Tweet * tweet = [Tweet tweetWithId:receivedTweetId context:context];
    if (!tweet)
        tweet = [Tweet createInstance:context];

    [self populateTweet:tweet fromData:tweetData];
    tweet.user = user;

    SEL sel = @selector(fetchedTweet:withId:);
    [self invokeSelector:sel withTarget:delegate args:tweet, tweetId, nil];

    return YES;
    */
}

- (BOOL)processErrorResponse:(NSError *)error
{
    //SEL sel = @selector(failedToFetchTweetWithId:error:);
    //[self invokeSelector:sel withTarget:delegate args:tweetId, error, nil];

    return YES;
}

@end
