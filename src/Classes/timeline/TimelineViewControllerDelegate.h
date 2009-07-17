//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TweetInfo.h"
#import "RemotePhoto.h"

@protocol TimelineViewControllerDelegate

- (void)selectedTweet:(TweetInfo *)tweet avatarImage:(UIImage *)avatarImage;
- (void)loadMoreTweets;
- (void)showUserInfoWithAvatar:(UIImage *)avatar;
- (void)showPhotoInBrowser:(RemotePhoto *)remotePhoto;

@end
