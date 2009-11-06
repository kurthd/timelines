//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DeleteTweetResponseProcessor.h"
#import "Tweet.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface DeleteTweetResponseProcessor ()

@property (nonatomic, copy) NSNumber * tweetId;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id delegate;

@end

@implementation DeleteTweetResponseProcessor

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

    NSLog(@"Deleted tweet %@: %@.", tweetId, statuses);

    // Notify the delegate first so it can do whatever it needs to do with the
    // tweet.
    SEL sel = @selector(deletedTweetWithId:);
    [self invokeSelector:sel withTarget:delegate args:tweetId, nil];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"identifier == %@", tweetId];
    Tweet * tweet = [Tweet findFirst:predicate context:context];
    NSAssert1(tweet, @"Failed to find deleted tweet with ID: '%@'", tweetId);
    [context deleteObject:tweet];
    [context save:NULL];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    NSLog(@"Failed to delete tweet: %@.", error);

    SEL sel = @selector(failedToDeleteTweetWithId:error:);
    [self invokeSelector:sel withTarget:delegate args:tweetId, error, nil];

    return YES;
}

@end
