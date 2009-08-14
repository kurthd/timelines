//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MarkAsFavoriteCell : UITableViewCell
{
    IBOutlet UILabel * mainLabel;
    IBOutlet UIImageView * iconView;
    IBOutlet UIActivityIndicatorView * activityIndicator;
}

- (void)setMarkedState:(BOOL)favorite;
- (void)setUpdatingState:(BOOL)updating;

@end
