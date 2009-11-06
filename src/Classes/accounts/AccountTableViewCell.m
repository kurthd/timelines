//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "AccountTableViewCell.h"

@implementation AccountTableViewCell

@synthesize accountCellView;

- (void)dealloc
{
    [accountCellView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:UITableViewCellStyleDefault
	    reuseIdentifier:reuseIdentifier]) {

		CGRect cellViewFrame =
		    CGRectMake(4.0, 4.0, self.contentView.bounds.size.width - 8,
		    self.contentView.bounds.size.height - 8);
		accountCellView =
		    [[AccountCellView alloc] initWithFrame:cellViewFrame];
		accountCellView.autoresizingMask =
		    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	    accountCellView.contentMode = UIViewContentModeTopLeft;
		[self.contentView addSubview:accountCellView];

		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	return self;
}

- (void)setUsername:(NSString *)username
{
    [accountCellView setUsername:username];
}

- (void)setLandscape:(BOOL)landscape
{
    accountCellView.landscape = landscape;
}

- (void)setAvatarImage:(UIImage *)avatarImage
{
    accountCellView.avatar = avatarImage;
}

- (void)setSelectedAccount:(BOOL)selectedAccount
{
    accountCellView.selectedAccount = selectedAccount;
}

- (void)redisplay
{
    [accountCellView setNeedsDisplay];
}

@end
