//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineTableViewCell.h"
#import "NSDate+StringHelpers.h"
#import "UILabel+DrawingAdditions.h"

@interface TimelineTableViewCell ()

+ (UIImage *)staticBackgroundImage;

@end

@implementation TimelineTableViewCell

static UIImage * backgroundImage;

- (void)dealloc
{
    [avatar release];
    [nameLabel release];
    [dateLabel release];
    [tweetTextLabel release];
    [super dealloc];
}

- (void)awakeFromNib
{
    self.backgroundView =
        [[[UIImageView alloc]
        initWithImage:[[self class] staticBackgroundImage]] autorelease];
    self.backgroundView.contentMode =  UIViewContentModeBottom;

    avatar.radius = 4;
    
    needsLayout = YES;
}

- (void)layoutSubviews
{
    if (needsLayout) {
        [super layoutSubviews];

        CGFloat tweetTextHeight =
            [tweetTextLabel heightForString:tweetTextLabel.text];
        CGRect tweetTextLabelFrame = tweetTextLabel.frame;
        tweetTextLabelFrame.size.height = tweetTextHeight;
        tweetTextLabel.frame = tweetTextLabelFrame;
        
        needsLayout = NO;
    }
}

- (void)setAvatarImage:(UIImage *)image
{
    [avatar setImage:image];
}

- (void)setName:(NSString *)name
{
    nameLabel.text = name;
}

- (void)setDate:(NSDate *)date
{
    dateLabel.text = [date shortDescription];
}

- (void)setTweetText:(NSString *)tweetText
{
    tweetTextLabel.text = tweetText;
}

- (void)setDisplayType:(TimelineTableViewCellType)aDisplayType
{
    if (displayType != aDisplayType) {
        needsLayout = YES;

        displayType = aDisplayType;

        CGRect avatarFrame = avatar.frame;
        CGRect nameLabelFrame = nameLabel.frame;
        CGRect dateLabelFrame = dateLabel.frame;
        CGRect tweetTextLabelFrame = tweetTextLabel.frame;

        switch (displayType) {
            case kTimelineTableViewCellTypeInverted:
                avatar.hidden = NO;
                avatarFrame.origin.x = 245;
                nameLabel.hidden = YES;
                dateLabelFrame.origin.x = 7;
                dateLabel.textAlignment = UITextAlignmentLeft;
                tweetTextLabelFrame.origin.x = 7;
                tweetTextLabelFrame.size.width = 234;
                break;
            case kTimelineTableViewCellTypeNormal:
                avatar.hidden = NO;
                avatarFrame.origin.x = 7;
                nameLabel.hidden = NO;
                nameLabelFrame.origin.x = 64;
                dateLabelFrame.origin.x = 212;
                dateLabel.textAlignment = UITextAlignmentRight;
                tweetTextLabelFrame.origin.x = 64;
                tweetTextLabelFrame.size.width = 234;
                break;
            case kTimelineTableViewCellTypeNoAvatar:
                nameLabel.hidden = YES;
                dateLabelFrame.origin.x = 7;
                dateLabel.textAlignment = UITextAlignmentLeft;
                tweetTextLabelFrame.origin.x = 7;
                avatar.hidden = YES;
                tweetTextLabelFrame.size.width = 291;
                break;
        }

        avatar.frame = avatarFrame;
        nameLabel.frame = nameLabelFrame;
        dateLabel.frame = dateLabelFrame;
        tweetTextLabel.frame = tweetTextLabelFrame;
    }
}

+ (CGFloat)heightForContent:(NSString *)tweetText
    displayType:(TimelineTableViewCellType)displayType
{
    NSInteger tweetTextLabelWidth =
        displayType == kTimelineTableViewCellTypeNoAvatar ?
        291 : 234;
    CGSize maxSize = CGSizeMake(tweetTextLabelWidth, 999999.0);
    UIFont * font = [UIFont systemFontOfSize:14.0];
    UILineBreakMode mode = UILineBreakModeWordWrap;

    CGSize size =
        [tweetText sizeWithFont:font constrainedToSize:maxSize
        lineBreakMode:mode];

    NSInteger minHeight =
        displayType == kTimelineTableViewCellTypeNoAvatar ?
        0 : 64;
    NSUInteger height = 34.0 + size.height;
    height = height > minHeight ? height : minHeight;

    return height;
}

+ (UIImage *)staticBackgroundImage
{
    if (!backgroundImage)
        backgroundImage =
            [[UIImage imageNamed:@"TableViewCellGradient.png"] retain];

    return backgroundImage;
}

@end
