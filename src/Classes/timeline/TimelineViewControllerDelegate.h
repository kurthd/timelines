//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TweetInfo.h"
#import "RemotePhoto.h"

@protocol TimelineViewControllerDelegate

- (void)selectedTweet:(TweetInfo *)tweet;
- (void)loadMoreTweets;
- (void)showUserInfo;
- (void)showPhotoInBrowser:(RemotePhoto *)remotePhoto;

@end
