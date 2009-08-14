//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "RemotePhoto.h"

@protocol TweetViewControllerDelegate

- (void)showUserInfoForUser:(User *)aUser;
- (void)showUserInfoForUsername:(NSString *)aUsername;
- (void)showTweetsForUser:(NSString *)username;
- (void)showResultsForSearch:(NSString *)query;
- (void)setFavorite:(BOOL)favorite;
- (void)showLocationOnMap:(NSString *)location;
- (void)showingTweetDetails;
- (void)loadNewTweetWithId:(NSString *)tweetId username:(NSString *)username;
- (void)reTweetSelected;
- (void)replyToTweet;
- (void)sendDirectMessageToUser:(NSString *)username;

@end
