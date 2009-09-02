//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineTableViewCell.h"
#import "NSDate+StringHelpers.h"
#import "TimelineTableViewCellView.h"
#import "UIColor+TwitchColors.h"
#import "TimelineTableViewCellBackground.h"

static UIImage * backgroundImage;
static UIImage * topGradientImage;

@implementation TimelineTableViewCell

@synthesize avatarImageUrl;

+ (void)initialize
{
    NSAssert(!backgroundImage, @"backgroundImage should be nil.");
    backgroundImage =
        [[UIImage imageNamed:@"TableViewCellGradient.png"] retain];
    topGradientImage =
        [[UIImage imageNamed:@"TableViewCellTopGradient.png"] retain];
}

- (void)dealloc
{
    [timelineView release];
    [avatarImageUrl release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CGRect frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width,
            self.contentView.bounds.size.height);
        timelineView = [[TimelineTableViewCellView alloc] initWithFrame:frame];
        timelineView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleHeight;

        [self.contentView addSubview:timelineView];

        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        self.backgroundView =
            [[[TimelineTableViewCellBackground alloc] init] autorelease];
        self.backgroundColor = [UIColor clearColor];
        [self setHighlightForMention:NO];
    }

    return self;
}

- (UIImage *)avatarImage
{
    return timelineView.avatar;
}

- (void)setAvatarImage:(UIImage *)image
{
    timelineView.avatar = image;
}

- (void)setName:(NSString *)name
{
    timelineView.author = name;
}

- (void)setDate:(NSDate *)date
{
    timelineView.timestamp = [date shortDescription];
}

- (void)setTweetText:(NSString *)tweetText
{
    timelineView.text = tweetText;
}

- (void)setDisplayType:(TimelineTableViewCellType)displayType
{
    timelineView.cellType = displayType;
}

- (void)setHighlightForMention:(BOOL)hfm
{
    timelineView.highlightForMention = hfm;
    ((TimelineTableViewCellBackground *)self.backgroundView).
        highlightForMention =
        hfm;
    UIColor * nonMentionCellColor =
        timelineView.darkenForOld ?
        [TimelineTableViewCellView darkenedCellColor] :
        [TimelineTableViewCellView defaultTimelineCellColor];
    self.backgroundView.backgroundColor =
        hfm ?
        [TimelineTableViewCellView mentionCellColor] :
        nonMentionCellColor;
}

- (void)setDarkenForOld:(BOOL)darken
{
    timelineView.darkenForOld = darken;
    ((TimelineTableViewCellBackground *)self.backgroundView).
        darkenForOld = darken;
    self.backgroundView.backgroundColor =
        darken ?
        [TimelineTableViewCellView darkenedCellColor] :
        [TimelineTableViewCellView defaultTimelineCellColor];
}

+ (NSString *)reuseIdentifier
{
    return @"TimelineTableViewCell";
}

+ (CGFloat)heightForContent:(NSString *)tweetText
    displayType:(TimelineTableViewCellType)displayType
{
    return [TimelineTableViewCellView heightForContent:tweetText
                                              cellType:displayType];
}

@end
