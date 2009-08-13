//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "ConversationDisplayMgr.h"
#import "Tweet.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface ConversationDisplayMgr ()

@property (nonatomic, retain) TwitterService * service;
@property (nonatomic, retain) NSManagedObjectContext * context;

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) ConversationViewController *
    conversationViewController;

@property (nonatomic, copy) NSString * firstTweetId;

@end

@implementation ConversationDisplayMgr

@synthesize delegate;
@synthesize service, context;
@synthesize navigationController, conversationViewController;

- (void)dealloc
{
    self.delegate = nil;

    self.service = nil;
    self.context = nil;

    self.navigationController = nil;
    self.conversationViewController = nil;

    [super dealloc];
}

- (id)initWithTwitterService:(TwitterService *)aService
                     context:(NSManagedObjectContext *)aContext
{
     if (self = [super init]) {
         self.service = aService;
         self.service.delegate = self;

         self.context = aContext;
     }

     return self;
}

- (void)displayConversationFrom:(NSString *)firstTweetId
           navigationController:(UINavigationController *)navController
{
    self.navigationController = navController;

    //
    // Load as much of the conversation as we currently have.
    //

    NSMutableArray * cachedConversation = [NSMutableArray array];

    NSString * nextId = firstTweetId;
    Tweet * tweet = nil;
    while (nextId || tweet) {
        NSPredicate * predicate =
            [NSPredicate predicateWithFormat:@"identifier == %@", nextId];
        Tweet * tweet = [Tweet findFirst:predicate context:context];
        if (tweet) {
            TweetInfo * info = [TweetInfo createFromTweet:tweet];
            [cachedConversation addObject:info];
            nextId = tweet.inReplyToTwitterTweetId;
        } else
            nextId = nil;
    }

    [self.conversationViewController
        loadConversationStartingWithTweets:cachedConversation];
    [self.navigationController
        pushViewController:self.conversationViewController animated:YES];
}

#pragma mark ConversationViewControllerDelegate implementation

- (void)fetchTweetWithId:(NSString *)tweetId
{
    [self.service fetchTweet:tweetId];
}

- (void)displayTweetWithId:(NSString *)tweetId
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"identifier == %@", tweetId];
    Tweet * tweet = [Tweet findFirst:predicate context:context];
    TweetInfo * info = [TweetInfo createFromTweet:tweet];

    [self.delegate displayTweetFromConversation:info];
}

#pragma mark TwitterServiceDelegate implementation

- (void)fetchedTweet:(Tweet *)tweet withId:(NSString *)tweetId
{
    TweetInfo * info = [TweetInfo createFromTweet:tweet];
    NSArray * tweets = [NSArray arrayWithObject:info];

    [self.conversationViewController addTweetsToConversation:tweets];
}

- (void)failedToFetchTweetWithId:(NSString *)tweetId error:(NSError *)error
{
    [self.conversationViewController
        failedToFetchTweetWithId:tweetId error:error];
}

#pragma mark Accessors

- (ConversationViewController *)conversationViewController
{
    if (!conversationViewController) {
        conversationViewController =
            [[ConversationViewController alloc]
            initWithNibName:@"ConversationView" bundle:nil];
        conversationViewController.delegate = self;
        conversationViewController.batchSize = [NSNumber numberWithInteger:4];
    }

    return conversationViewController;
}

@end
