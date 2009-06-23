//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TweetInfo.h"

@protocol TimelineViewControllerDelegate

- (void)selectedTweet:(TweetInfo *)tweet;
- (void)loadMoreTweets;

@end
