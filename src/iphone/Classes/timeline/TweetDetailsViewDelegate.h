//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@protocol TweetDetailsViewDelegate

- (void)selectedUser:(User *)user;
- (void)setFavorite:(BOOL)favorite;

@end
