//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RemotePhoto.h"

@protocol UserInfoViewControllerDelegate

- (void)showLocationOnMap:(NSString *)location;
- (void)displayFollowingForUser:(NSString *)username;
- (void)displayFollowersForUser:(NSString *)username;
- (void)displayFavoritesForUser:(NSString *)username;
- (void)showTweetsForUser:(NSString *)username;
- (void)startFollowingUser:(NSString *)username;
- (void)stopFollowingUser:(NSString *)username;
- (void)blockUser:(NSString *)username;
- (void)unblockUser:(NSString *)username;
- (void)showingUserInfoView;
- (void)sendDirectMessageToUser:(NSString *)username;
- (void)sendPublicMessageToUser:(NSString *)username;
- (void)showResultsForSearch:(NSString *)query;

@end
