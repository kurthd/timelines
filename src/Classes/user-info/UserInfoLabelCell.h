//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserInfoLabelCellView.h"

@interface UserInfoLabelCell : UITableViewCell
{
    UserInfoLabelCellView * cellView;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
    backgroundColor:(UIColor *)backgroundColor;

- (void)setKeyText:(NSString *)keyText valueText:(NSString *)valueText;
- (void)redisplay;

@end
