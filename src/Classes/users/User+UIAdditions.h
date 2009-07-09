//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"
#import "AsynchronousNetworkFetcherDelegate.h"
#import "RoundedImage.h"

@interface User (UIAdditions) <AsynchronousNetworkFetcherDelegate>

- (RoundedImage *)avatar;
- (UIImage *)avatarImage;

@end
