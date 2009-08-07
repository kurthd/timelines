//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineTableViewCell.h"
#import "NSDate+StringHelpers.h"
#import "TimelineTableViewCellView.h"

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
    }

    return self;
}

- (void)drawRect:(CGRect)rect
{
    //
    // Draw the cell's background here, as well as in the contentView's
    // drawRect, so we can draw over the accessory view's space, too.
    //
    CGRect backgroundImageRect =
        CGRectMake(0, self.bounds.size.height - backgroundImage.size.height,
        320.0, backgroundImage.size.height);
    [backgroundImage drawInRect:backgroundImageRect];

    CGRect topGradientImageRect =
        CGRectMake(0, 0, 320.0, topGradientImage.size.height);
    [topGradientImage drawInRect:topGradientImageRect];
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
