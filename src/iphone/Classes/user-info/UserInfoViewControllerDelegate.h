//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UserInfoViewControllerDelegate

- (void)showLocationOnMap:(NSString *)location;
- (void)visitWebpage:(NSString *)webpageUrl;
- (void)displayFollowingForUser:(NSString *)username;
- (void)displayFollowersForUser:(NSString *)username;
- (void)startFollowingUser:(NSString *)username;
- (void)stopFollowingUser:(NSString *)username;

@end
