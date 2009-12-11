//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "RemotePhoto.h"

@class DirectMessageViewController;

@protocol DirectMessageViewControllerDelegate

- (void)showUserInfoForUser:(User *)aUser;
- (void)showUserInfoForUsername:(NSString *)aUsername;
- (void)showResultsForSearch:(NSString *)query;
- (void)showingTweetDetails:(DirectMessageViewController *)tweetController;
- (void)dismissingDetails:(DirectMessageViewController *)viewController;
- (void)deleteTweet:(NSNumber *)tweetId;
- (void)sendDirectMessageToUser:(NSString *)aUsername;

@optional

- (void)directMessageViewController:(DirectMessageViewController *)controller
    finishedLoadingMessage:(DirectMessage *)dm;

@end
