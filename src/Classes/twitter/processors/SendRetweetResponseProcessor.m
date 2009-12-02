//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SendRetweetResponseProcessor.h"
#import "User.h"
#import "User+CoreDataAdditions.h"
#import "UserTweet.h"
#import "Tweet+CoreDataAdditions.h"
#import "ResponseProcessor+ParsingHelpers.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "TwitbitShared.h"

@interface SendRetweetResponseProcessor ()

@property (nonatomic, copy) NSNumber * tweetId;
@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, assign) id<TwitterServiceDelegate> delegate;

@end

@implementation SendRetweetResponseProcessor

@synthesize tweetId, credentials, context, delegate;

+ (id)processorWithTweetId:(NSNumber *)aTweetId
               credentials:(TwitterCredentials *)someCredentials
                   context:(NSManagedObjectContext *)aContext
                  delegate:(id<TwitterServiceDelegate>)aDelegate
{
    id obj = [[self alloc] initWithTweetId:aTweetId
                               credentials:someCredentials
                                   context:aContext
                                  delegate:aDelegate];
    return [obj autorelease];
}

- (void)dealloc
{
    self.tweetId = nil;
    self.credentials = nil;
    self.context = nil;
    self.delegate = nil;
    [super dealloc];
}

- (id)initWithTweetId:(NSNumber *)aTweetId
          credentials:(TwitterCredentials *)someCredentials
              context:(NSManagedObjectContext *)aContext
             delegate:(id<TwitterServiceDelegate>)aDelegate
{
    if (self = [super init]) {
        self.tweetId = aTweetId;
        self.credentials = someCredentials;
        self.context = aContext;
        self.delegate = aDelegate;
    }

    return self;
}


- (BOOL)processResponse:(NSArray *)statuses
{
    if (!statuses)
        return NO;

    NSLog(@"Statuses: %@", statuses);

    NSAssert1(statuses.count == 1, @"Expected 1 status in response; received "
        "%d.", statuses.count);

    NSDictionary * tweetData = [statuses lastObject];

    id identifier = [tweetData objectForKey:@"id"];
    if (!identifier || [identifier isEqual:[NSNull null]]) {
        /*
         * Twitter does not allow retweets of certain tweets, including your own
         * tweets and tweets that you have already retweeted. There may be other
         * cases, but when this happens, they provide an empty tweet. Check for
         * this case and respond appropriately.
         */
        NSString * retweetError = LS(@"twitter.retweet.failed.unknown");
        NSError * error = [NSError errorWithLocalizedDescription:retweetError];
        [self processErrorResponse:error];
    } else {
        Tweet * tweet = [self createTweetFromStatus:tweetData
                                        isUserTweet:YES
                                     isSearchResult:NO
                                        credentials:credentials
                                            context:context];

        NSDictionary * retweetData =
            [tweetData objectForKey:@"retweeted_status"];
        Tweet * retweet = [self createTweetFromStatus:retweetData
                                          isUserTweet:NO
                                       isSearchResult:NO
                                          credentials:credentials
                                              context:context];

        tweet.retweet = retweet;

        SEL sel = @selector(retweetSentSuccessfully:tweetId:);
        if ([delegate respondsToSelector:sel])
            [delegate retweetSentSuccessfully:tweet tweetId:tweetId];
    }

    return YES;
}

- (BOOL)processErrorResponse:(NSError *)error
{
    SEL sel = @selector(failedToSendRetweet:error:);
    if ([delegate respondsToSelector:sel])
        [delegate failedToSendRetweet:tweetId error:error];

    return YES;
}

@end
