//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsynchronousNetworkFetcher.h"

@protocol ConversationViewControllerDelegate

- (void)fetchTweetWithId:(NSNumber *)tweetId;
- (void)displayTweetWithId:(NSNumber *)tweetId;

- (BOOL)isCurrentUser:(NSString *)username;

@end

@interface ConversationViewController :
    UITableViewController <AsynchronousNetworkFetcherDelegate>
{
    id<ConversationViewControllerDelegate> delegate;

    IBOutlet UIView * headerView;
    IBOutlet UIView * headerViewLine;
    IBOutlet UIView * footerView;
    IBOutlet UIView * plainFooterView;

    IBOutlet UIView * loadingView;
    IBOutlet UIButton * loadMoreButton;
    IBOutlet UILabel * loadingLabel;
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
- (void)failedToFetchTweetWithId:(NSNumber *)tweetId error:(NSError *)error;

- (IBAction)loadNextBatch:(id)sender;

@end
