//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TweetInfo.h"
#import "TimelineTableViewCell.h"

@interface TweetInfo (UIAdditions)

- (TimelineTableViewCell *)cell;
- (TimelineTableViewCell *)cellWithAvatar;

@end
