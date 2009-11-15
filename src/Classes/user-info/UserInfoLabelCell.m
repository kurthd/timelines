//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserInfoLabelCell.h"

@implementation UserInfoLabelCell

- (void)dealloc
{
    [cellView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
    backgroundColor:(UIColor *)aBackgroundColor
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CGRect cellViewFrame =
		    CGRectMake(4.0, 4.0, self.contentView.bounds.size.width - 8,
		    self.contentView.bounds.size.height - 8);
		cellView =
		    [[UserInfoLabelCellView alloc] initWithFrame:cellViewFrame
		    backgroundColor:aBackgroundColor];
		cellView.autoresizingMask =
		    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	    cellView.contentMode = UIViewContentModeTopLeft;
		[self.contentView addSubview:cellView];

		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.backgroundColor = aBackgroundColor;
    }

    return self;
}

- (void)setKeyText:(NSString *)keyText valueText:(NSString *)valueText
{
    [cellView setKeyText:keyText valueText:valueText];
}

- (void)redisplay
{
    [cellView setNeedsDisplay];
}

@end
