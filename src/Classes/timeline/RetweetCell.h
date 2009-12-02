//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RetweetCell : UITableViewCell
{
    IBOutlet UILabel * mainLabel;
    IBOutlet UIImageView * iconView;
    IBOutlet UIActivityIndicatorView * activityIndicator;
}

- (void)setUpdatingState:(BOOL)updating;

@end
