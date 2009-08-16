//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageInboxCell.h"

@implementation DirectMessageInboxCell

@synthesize cellView;

- (void)dealloc
{
    [cellView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {

	if (self = [super initWithStyle:UITableViewCellStyleDefault
	    reuseIdentifier:reuseIdentifier]) {

		CGRect cellViewFrame =
		    CGRectMake(0.0, 0.0, self.contentView.bounds.size.width,
		    self.contentView.bounds.size.height);
		cellView =
		    [[DirectMessageInboxCellView alloc] initWithFrame:cellViewFrame];
		cellView.autoresizingMask =
		    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.contentView addSubview:cellView];
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	return self;
}

- (void)redisplay {
	[cellView setNeedsDisplay];
}

- (void)setConversationPreview:(ConversationPreview *)preview
{
    [cellView setConversationPreview:preview];
}

@end
