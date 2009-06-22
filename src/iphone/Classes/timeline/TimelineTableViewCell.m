//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineTableViewCell.h"
#import "NSDate+StringHelpers.h"
#import "UILabel+DrawingAdditions.h"

@implementation TimelineTableViewCell

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
    UIImage * backgroundImage =
        [UIImage imageNamed:@"TableViewCellGradient.png"];
    self.backgroundView =
        [[[UIImageView alloc] initWithImage:backgroundImage] autorelease];
    self.backgroundView.contentMode =  UIViewContentModeBottom;

    avatar.radius = 4;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat tweetTextHeight =
        [tweetTextLabel heightForString:tweetTextLabel.text];
    CGRect tweetTextLabelFrame = tweetTextLabel.frame;
    tweetTextLabelFrame.size.height = tweetTextHeight;
    tweetTextLabel.frame = tweetTextLabelFrame;
}

- (void)setAvatarImage:(UIImage *)image
{
    avatar.imageView.image = image;
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

+ (CGFloat)heightForContent:(NSString *)tweetText
{
    CGSize maxSize = CGSizeMake(234, 999999.0);
    UIFont * font = [UIFont systemFontOfSize:14.0];
    UILineBreakMode mode = UILineBreakModeWordWrap;

    CGSize size =
        [tweetText sizeWithFont:font constrainedToSize:maxSize
        lineBreakMode:mode];

    static const NSUInteger MIN_HEIGHT = 64;
    NSUInteger height = 34.0 + size.height;
    height = height > MIN_HEIGHT ? height : MIN_HEIGHT;

    return height;
}

@end
