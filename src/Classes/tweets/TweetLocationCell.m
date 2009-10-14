//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetLocationCell.h"

@implementation TweetLocationCell

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
            [[TweetLocationCellView alloc] initWithFrame:cellViewFrame];
        locationCellView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        locationCellView.contentMode = UIViewContentModeTopLeft;
        locationCellView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:locationCellView];

        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	return self;
}

- (void)setLocation:(CLLocation *)location
{
    [locationCellView setLocation:location];
}

- (void)setLandscape:(BOOL)landscape
{
    locationCellView.landscape = landscape;
}

- (void)redisplay {
	[locationCellView setNeedsDisplay];
}

- (void)setLabelTextColor:(UIColor *)color
{
    locationCellView.textColor = color;
}

@end
