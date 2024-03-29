//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TwitterListCell.h"

@implementation TwitterListCell

- (void)dealloc
{
    [cellView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		CGRect cellViewFrame =
		    CGRectMake(0.0, 0.0, self.contentView.bounds.size.width,
		    self.contentView.bounds.size.height);
		cellView =
		    [[TwitterListCellView alloc] initWithFrame:cellViewFrame];
		cellView.autoresizingMask =
		    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	    cellView.contentMode = UIViewContentModeTopLeft;
		[self.contentView addSubview:cellView];

		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return self;
}

- (void)setList:(TwitterList *)list
{
    cellView.list = list;
}

- (void)setLandscape:(BOOL)landscape
{
    cellView.landscape = landscape;
}

- (void)redisplay
{
    [cellView setNeedsDisplay];
}

@end
