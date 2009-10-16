//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "RoundedImage.h"

@interface User (UIAdditions) <AsynchronousNetworkFetcherDelegate>

- (RoundedImage *)roundedAvatarImage;
- (UIImage *)avatarImage;
- (NSString *)followersDescription;

- (UIImage *)thumbnailAvatar;
- (UIImage *)fullAvatar;

- (BOOL)isComplete;

+ (void)setAvatar:(UIImage *)avatar forUrl:(NSString *)url;

+ (NSString *)fullAvatarUrlForUrl:(NSString *)url;

@end


@interface User (SortingAdditions)

- (NSComparisonResult)caseInsensitiveUsernameCompare:(User *)otherUser;

@end