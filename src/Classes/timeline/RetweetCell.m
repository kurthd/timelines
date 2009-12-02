//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "RetweetCell.h"

@implementation RetweetCell

- (void)dealloc
{
    [mainLabel release];
    [iconView release];
    [activityIndicator release];
    [super dealloc];
}

- (void)setUpdatingState:(BOOL)updating
{
    if (updating) {
        iconView.hidden = YES;
        mainLabel.enabled = NO;
        [activityIndicator startAnimating];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        iconView.hidden = NO;
        mainLabel.enabled = YES;
        mainLabel.textColor = self.textLabel.textColor;
        [activityIndicator stopAnimating];
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
}

@end
