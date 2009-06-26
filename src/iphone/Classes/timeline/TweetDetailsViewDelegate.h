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

@end
