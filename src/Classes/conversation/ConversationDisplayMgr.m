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

- (void)displayConversationFrom:(NSNumber *)firstTweetId
           navigationController:(UINavigationController *)navController
{
    self.navigationController = navController;

    //
    // Load as much of the conversation as we currently have.
    //

    NSMutableArray * cachedConversation = [NSMutableArray array];

    NSNumber * nextId = firstTweetId;
    Tweet * tweet = nil;
    while (nextId || tweet) {
        NSPredicate * predicate =
            [NSPredicate predicateWithFormat:@"identifier == %@", nextId];
        Tweet * tweet = [Tweet findFirst:predicate context:context];
        if (tweet) {
            [cachedConversation addObject:tweet];
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

- (void)fetchTweetWithId:(NSNumber *)tweetId
{
    [self.service performSelector:@selector(fetchTweet:)
                       withObject:tweetId
                       afterDelay:1.0];
}

- (void)displayTweetWithId:(NSNumber *)tweetId
{
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"identifier == %@", tweetId];
    Tweet * tweet = [Tweet findFirst:predicate context:context];

    [self.delegate displayTweetFromConversation:tweet];
}

- (BOOL)isCurrentUser:(NSString *)username
{
    return [username isEqualToString:self.service.credentials.username];
}

#pragma mark TwitterServiceDelegate implementation

- (void)fetchedTweet:(Tweet *)tweet withId:(NSNumber *)tweetId
{
    NSArray * tweets = [NSArray arrayWithObject:tweet];
    [self.conversationViewController addTweetsToConversation:tweets];
}

- (void)failedToFetchTweetWithId:(NSNumber *)tweetId error:(NSError *)error
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
        conversationViewController.batchSize = [NSNumber numberWithInteger:3];
    }

    return conversationViewController;
}

@end
