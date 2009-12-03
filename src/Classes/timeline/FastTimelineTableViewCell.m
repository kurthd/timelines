//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FastTimelineTableViewCell.h"
#import "FastTimelineTableViewCellView.h"
#import "NSString+ConvenienceMethods.h"

@implementation FastTimelineTableViewCell

@synthesize userData;

- (void)dealloc 
{
    [timelineView release];
    self.userData = nil;
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        CGRect frame =
            CGRectMake(0.0,
                       0.0,
                       self.contentView.bounds.size.width,
                       self.contentView.bounds.size.height);
        timelineView =
            [[FastTimelineTableViewCellView alloc] initWithFrame:frame];
        timelineView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleHeight;
        timelineView.contentMode = UIViewContentModeTopLeft;

        [self.contentView addSubview:timelineView];
    }

    return self;
}

#pragma mark Accessors

- (void)setLandscape:(BOOL)landscape
{
    timelineView.landscape = landscape;
}

- (void)setDisplayType:(FastTimelineTableViewCellDisplayType)type
{
    timelineView.displayType = type;
}

- (void)setTweetText:(NSString *)tweetText
{
    timelineView.text = tweetText;
}

- (void)setAuthor:(NSString *)author
{
    timelineView.author = author;
}

- (void)setRetweetAuthor:(NSString *)retweetAuthor
{
    timelineView.retweetAuthorName = retweetAuthor;
}

- (void)setTimestamp:(NSString *)timestamp
{
    timelineView.timestamp = timestamp;
}

- (void)setAvatar:(UIImage *)avatar
{
    timelineView.avatar = avatar;
}

- (void)setFavorite:(BOOL)favorite
{
    timelineView.favorite = favorite;
}

- (void)displayAsMention:(BOOL)displayAsMention
{
    timelineView.displayAsMention = displayAsMention;
}

- (void)displayAsOld:(BOOL)displayAsOld
{
    timelineView.displayAsOld = displayAsOld;
}

#pragma mark Public class implementation

+ (CGFloat)heightForContent:(NSString *)tweetText
                    retweet:(BOOL)retweet
                displayType:(FastTimelineTableViewCellDisplayType)displayType
                  landscape:(BOOL)landscape
{
    return [FastTimelineTableViewCellView heightForContent:tweetText
                                                   retweet:retweet
                                               displayType:displayType
                                                 landscape:landscape];
}

@end
