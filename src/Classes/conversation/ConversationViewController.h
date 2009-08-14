//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsynchronousNetworkFetcher.h"

@protocol ConversationViewControllerDelegate

- (void)fetchTweetWithId:(NSString *)tweetId;
- (void)displayTweetWithId:(NSString *)tweetId;

- (BOOL)isCurrentUser:(NSString *)username;

@end

@interface ConversationViewController :
    UITableViewController <AsynchronousNetworkFetcherDelegate>
{
    id<ConversationViewControllerDelegate> delegate;

    IBOutlet UIView * footerView;

    IBOutlet UIView * loadingView;
    IBOutlet UIView * loadMoreView;

    NSMutableArray * conversation;
    NSNumber * batchSize;

    NSUInteger waitingFor;

    NSMutableDictionary * alreadySent;
}

@property (nonatomic, assign) id<ConversationViewControllerDelegate> delegate;
@property (nonatomic, copy) NSNumber * batchSize;

- (void)loadConversationStartingWithTweets:(NSArray *)tweets;
- (void)addTweetsToConversation:(NSArray *)tweets;
- (void)failedToFetchTweetWithId:(NSString *)tweetId error:(NSError *)error;

- (IBAction)loadNextBatch:(id)sender;

@end
