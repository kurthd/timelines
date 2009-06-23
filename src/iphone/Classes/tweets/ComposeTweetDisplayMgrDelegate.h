//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tweet.h"

@protocol ComposeTweetDisplayMgrDelegate

- (void)userDidCancelComposingTweet;

- (void)userIsSendingTweet:(NSString *)tweet;
- (void)userDidSendTweet:(Tweet *)tweet;
- (void)userFailedToSendTweet:(NSString *)tweet;

@end
