//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ActionButtonCell.h"

@implementation ActionButtonCell

@synthesize cellView;

- (void)dealloc
{
    [cellView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
    backgroundColor:(UIColor *)aBackgroundColor
{
	if (self = [super initWithStyle:UITableViewCellStyleDefault
	    reuseIdentifier:reuseIdentifier]) {

		CGRect cellViewFrame =
		    CGRectMake(4.0, 4.0, self.contentView.bounds.size.width - 8,
		    self.contentView.bounds.size.height - 8);
		cellView =
		    [[ActionButtonCellView alloc] initWithFrame:cellViewFrame
		    backgroundColor:aBackgroundColor];
		cellView.autoresizingMask =
		    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	    cellView.contentMode = UIViewContentModeTopLeft;
		[self.contentView addSubview:cellView];

        self.backgroundColor = aBackgroundColor;
	}

	return self;
}

- (void)setActionText:(NSString *)actionText
{
    [cellView setActionText:actionText];
}

- (void)setLandscape:(BOOL)landscape
{
    cellView.landscape = landscape;
}

- (void)setActionImage:(UIImage *)actionImage
{
    cellView.actionImage = actionImage;
}

- (void)redisplay
{
    [cellView setNeedsDisplay];
}

@end
