//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DeleteTweetResponseProcessor.h"
#import "UserTweet.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "MGTwitterEngine.h"  // for twitterApiErrorDomain

@interface DeleteTweetResponseProcessor ()

@property (nonatomic, copy) NSNumber * tweetId;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation DeleteTweetResponseProcessor

@synthesize tweetId, context, delegate;

+ (id)processorWithTweetId:(NSNumber *)aTweetId
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id<TwitterServiceDelegate>)aDelegate
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
             delegate:(id<TwitterServiceDelegate>)aDelegate
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
    if ([delegate respondsToSelector:sel])
        [delegate deletedTweetWithId:tweetId];

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"identifier == %@", tweetId];
    UserTweet * tweet = [UserTweet findFirst:predicate context:context];
    NSAssert1(tweet, @"Failed to find deleted tweet with ID: '%@'", tweetId);
    [context deleteObject:tweet];
    [context save:NULL];

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    NSLog(@"Failed to delete tweet: %@.", error);

    NSString * notFoundErrorDomain = [NSError twitterApiErrorDomain];
    NSString * notFoundMessage = @"No status found with that ID.";
    BOOL wasNotFound =
        [[error domain] isEqualToString:notFoundErrorDomain] &&
        [[error localizedDescription] isEqualToString:notFoundMessage];

    if (wasNotFound)  // don't treat as an error
        [self processResponse:[NSArray arrayWithObject:[NSNull null]]];
    else {
        SEL sel = @selector(failedToDeleteTweetWithId:error:);
        if ([delegate respondsToSelector:sel])
            [delegate failedToDeleteTweetWithId:tweetId error:error];
    }

    return YES;
}

@end
