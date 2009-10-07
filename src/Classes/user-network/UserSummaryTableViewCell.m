//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserSummaryTableViewCell.h"

@implementation UserSummaryTableViewCell

@synthesize userSummaryView, avatarImageUrl;

- (void)dealloc
{
    [userSummaryView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
    backgroundColor:(UIColor *)aBackgroundColor
{

	if (self = [super initWithStyle:UITableViewCellStyleDefault
	    reuseIdentifier:reuseIdentifier]) {

		CGRect cellViewFrame =
		    CGRectMake(0.0, 0.0, self.contentView.bounds.size.width,
		    self.contentView.bounds.size.height);
		userSummaryView =
		    [[UserSummaryView alloc] initWithFrame:cellViewFrame
		    backgroundColor:aBackgroundColor];
		userSummaryView.autoresizingMask =
		    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	    userSummaryView.contentMode = UIViewContentModeTopLeft;
		[self.contentView addSubview:userSummaryView];

		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor = aBackgroundColor;
        self.backgroundColor = [UIColor clearColor];
	}

	return self;
}

- (void)setUser:(User *)user
{
    self.avatarImageUrl = user.avatar.thumbnailImageUrl;
    [userSummaryView setUser:user];
}

- (void)setLandscape:(BOOL)landscape
{
    userSummaryView.landscape = landscape;
}

- (void)setAvatarImage:(UIImage *)avatarImage
{
    userSummaryView.avatar = avatarImage;
}

- (void)redisplay
{
    [userSummaryView setNeedsDisplay];
}

@end
