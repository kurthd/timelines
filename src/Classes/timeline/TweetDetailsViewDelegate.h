//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "RemotePhoto.h"

@protocol TweetDetailsViewDelegate

- (void)showUserInfoForUser:(User *)aUser withAvatar:(UIImage *)avatar;
- (void)showTweetsForUser:(NSString *)username;
- (void)showResultsForSearch:(NSString *)query;
- (void)setFavorite:(BOOL)favorite;
- (void)showLocationOnMap:(NSString *)location;
- (void)visitWebpage:(NSString *)webpageUrl;
- (void)showingTweetDetails;
- (void)loadNewTweetWithId:(NSString *)tweetId username:(NSString *)username;
- (void)setCurrentTweetDetailsUser:(NSString *)username;
- (void)reTweetSelected;
- (void)replyToTweet;
- (void)sendDirectMessageToUser:(NSString *)username;
- (void)showPhotoInBrowser:(RemotePhoto *)remotePhoto;

@end
