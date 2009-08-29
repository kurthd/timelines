//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "DeleteTweetResponseProcessor.h"

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

    NSLog(@"Deleted tweet %@: %@.", tweetId, statuses);

    SEL sel = @selector(deletedTweetWithId:);
    [self invokeSelector:sel withTarget:delegate args:tweetId, nil];

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
