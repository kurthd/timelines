//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActionButtonCellView.h"

@interface ActionButtonCell : UITableViewCell
{
    ActionButtonCellView * cellView;
}

@property (nonatomic, retain) ActionButtonCellView * cellView;

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
    backgroundColor:(UIColor *)aBackgroundColor;

- (void)setActionText:(NSString *)actionText;
- (void)setActionImage:(UIImage *)actionImage;
- (void)setLandscape:(BOOL)landscape;

- (void)redisplay;

@end
