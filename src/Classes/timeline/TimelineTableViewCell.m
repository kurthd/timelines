//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineTableViewCell.h"
#import "NSDate+StringHelpers.h"
#import "TimelineTableViewCellView.h"

@implementation TimelineTableViewCell

- (void)dealloc
{
    [timelineView release];
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
    }

    return self;
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

+ (CGFloat)heightForContent:(NSString *)tweetText
    displayType:(TimelineTableViewCellType)displayType
{
    return [TimelineTableViewCellView heightForContent:tweetText
                                              cellType:displayType];
}

@end