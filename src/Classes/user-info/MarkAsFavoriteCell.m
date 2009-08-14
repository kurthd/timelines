//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "MarkAsFavoriteCell.h"

@implementation MarkAsFavoriteCell

- (void)dealloc
{
    [mainLabel release];
    [iconView release];
    [activityIndicator release];
    [super dealloc];
}

- (void)setMarkedState:(BOOL)favorite
{
    if (favorite) {
        mainLabel.text =
            NSLocalizedString(@"tweetdetailsview.unfavorite.label", @"");
        iconView.image = [UIImage imageNamed:@"Favorite.png"];
    } else {
        mainLabel.text =
            NSLocalizedString(@"tweetdetailsview.favorite.label", @"");
        iconView.image = [UIImage imageNamed:@"NotFavorite.png"];
    }
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
        [activityIndicator stopAnimating];
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
}

@end
