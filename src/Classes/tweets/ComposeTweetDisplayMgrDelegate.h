//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tweet.h"
#import "DirectMessage.h"

@protocol ComposeTweetDisplayMgrDelegate

- (void)userDidCancelComposingTweet;

- (void)userIsSendingTweet:(NSString *)tweet;
- (void)userDidSendTweet:(Tweet *)tweet;
- (void)userFailedToSendTweet:(NSString *)tweet;

- (void)userIsReplyingToTweet:(NSString *)origTweetId
                     fromUser:(NSString *)origUsername
                     withText:(NSString *)text;
- (void)userDidReplyToTweet:(NSString *)origTweetId
                   fromUser:(NSString *)origUsername
                  withTweet:(Tweet *)reply;
- (void)userFailedToReplyToTweet:(NSString *)origTweetId
                        fromUser:(NSString *)origUsername
                        withText:(NSString *)text;

- (void)userIsSendingDirectMessage:(NSString *)dm to:(NSString *)username;
- (void)userDidSendDirectMessage:(DirectMessage *)dm;
- (void)userFailedToSendDirectMessage:(NSString *)dm to:(NSString *)username;

@end
