//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@protocol TweetDetailsViewDelegate

- (void)showTweetsForUser:(NSString *)username;
- (void)setFavorite:(BOOL)favorite;
- (void)showLocationOnMap:(NSString *)location;
- (void)visitWebpage:(NSString *)webpageUrl;
- (void)showingTweetDetails;
- (void)loadNewTweetWithId:(NSString *)tweetId username:(NSString *)username;
- (void)setCurrentTweetDetailsUser:(NSString *)username;
- (void)reTweetSelected;
- (void)sendDirectMessageToUser:(NSString *)username;

@end
