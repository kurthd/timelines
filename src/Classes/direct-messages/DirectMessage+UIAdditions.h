//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectMessage.h"
#import "TimelineTableViewCell.h"

@interface DirectMessage (UIAdditions)

- (TimelineTableViewCell *)cell;
- (TimelineTableViewCell *)cellWithAvatar;

@end
