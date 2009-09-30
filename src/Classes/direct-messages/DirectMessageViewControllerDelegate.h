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
- (void)showTweetsForUser:(NSString *)username;
- (void)showResultsForSearch:(NSString *)query;
- (void)showLocationOnMap:(NSString *)location;
- (void)showingTweetDetails:(DirectMessageViewController *)tweetController;
- (void)deleteTweet:(NSString *)tweetId;
- (void)sendDirectMessageToUser:(NSString *)aUsername;

@end
