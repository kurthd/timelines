//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FetchTweetResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "Tweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface FetchTweetResponseProcessor ()

@property (nonatomic, copy) NSNumber * tweetId;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation FetchTweetResponseProcessor

@synthesize tweetId, context, delegate;

+ (id)processorWithTweetId:(NSNumber *)aTweetId
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

- (id)initWithTweetId:(NSNumber *)aTweetId
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

    NSAssert1(statuses.count == 1, @"Expected 1 status in response; received "
        "%d.", statuses.count);

    NSDictionary * status = [statuses objectAtIndex:0];
    Tweet * tweet = [self createTweetFromStatus:status
                                    isUserTweet:NO
                                    credentials:nil
                                        context:self.context];

    SEL sel = @selector(fetchedTweet:withId:);
    [self invokeSelector:sel withTarget:delegate args:tweet, tweetId, nil];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToFetchTweetWithId:error:);
    [self invokeSelector:sel withTarget:delegate args:tweetId, error, nil];

    return YES;
}

@end
