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

+ (void)setAvatar:(UIImage *)avatar forUrl:(NSString *)url;
+ (UIImage *)avatarForUrl:(NSString *)url;

+ (NSString *)largeAvatarUrlForUrl:(NSString *)url;

@end
