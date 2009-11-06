//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageInboxCell.h"
#import "SettingsReader.h"
#import "TimelineTableViewCellView.h"
#import "TwitbitShared.h"

@implementation DirectMessageInboxCell

@synthesize cellView;

- (void)dealloc
{
    [cellView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:UITableViewCellStyleDefault
	    reuseIdentifier:reuseIdentifier]) {

		CGRect cellViewFrame =
		    CGRectMake(0.0, 0.0, self.contentView.bounds.size.width,
		    self.contentView.bounds.size.height);
		cellView =
		    [[DirectMessageInboxCellView alloc] initWithFrame:cellViewFrame];
		cellView.autoresizingMask =
		    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        cellView.contentMode = UIViewContentModeTopLeft;
		[self.contentView addSubview:cellView];
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
        self.backgroundView = [[[UIView alloc] init] autorelease];
        self.backgroundView.backgroundColor =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            [UIColor defaultDarkThemeCellColor] :
            [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];
	}

	return self;
}

- (void)redisplay
{
	[cellView setNeedsDisplay];
}

- (void)setLandscape:(BOOL)landscape
{
    cellView.landscape = landscape;
}

- (void)setConversationPreview:(ConversationPreview *)preview
{
    [cellView setConversationPreview:preview];
}

@end
