//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "LocationCell.h"

@implementation LocationCell

- (void)dealloc
{
    [locationCellView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {

	if (self = [super initWithStyle:UITableViewCellStyleDefault
	    reuseIdentifier:reuseIdentifier]) {

        CGRect cellViewFrame =
            CGRectMake(5.0, 5.0, self.contentView.bounds.size.width - 10.0,
            self.contentView.bounds.size.height - 10.0);
        locationCellView =
            [[LocationCellView alloc] initWithFrame:cellViewFrame];
        locationCellView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        locationCellView.contentMode = UIViewContentModeTopLeft;
        [self.contentView addSubview:locationCellView];

        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	return self;
}

- (void)setLocationText:(NSString *)locationText
{
    [locationCellView setLocationText:locationText];
}

- (void)setLandscape:(BOOL)landscape
{
    locationCellView.landscape = landscape;
}

- (void)redisplay {
	[locationCellView setNeedsDisplay];
}

@end
