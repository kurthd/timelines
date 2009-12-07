//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "RemotePhoto.h"

@class TweetViewController;

@protocol TweetViewControllerDelegate <NSObject>

- (void)showUserInfoForUser:(User *)aUser;
- (void)showUserInfoForUsername:(NSString *)aUsername;
- (void)showResultsForSearch:(NSString *)query;
- (void)setFavorite:(BOOL)favorite;
- (void)showLocationOnMap:(NSString *)location;
- (void)showingTweetDetails:(TweetViewController *)tweetController;
- (void)loadNewTweetWithId:(NSNumber *)tweetId username:(NSString *)username
    animated:(BOOL)animated;
- (void)reTweetSelected;
- (void)retweetNativelyWithTwitter;
- (void)replyToTweet;
- (void)loadConversationFromTweetId:(NSNumber *)tweetId;
- (void)deleteTweet:(NSNumber *)tweetId;
- (void)showLocationOnMap:(NSString *)location;

@optional

- (void)tweetViewController:(TweetViewController *)controller
       finishedLoadingTweet:(Tweet *)tweet;

@end
