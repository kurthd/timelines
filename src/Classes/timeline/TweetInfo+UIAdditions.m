//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "TweetInfo+UIAdditions.h"
#import "User+UIAdditions.h"
#import "NSString+HtmlEncodingAdditions.h"

/*
@interface TweetInfo (Private)

- (TimelineTableViewCell *)createCell;
+ (NSMutableDictionary *)cellCache;

@end

@implementation TweetInfo (UIAdditions)

static NSMutableDictionary * cells;

- (TimelineTableViewCell *)cell
{
    TimelineTableViewCell * timelineCell =
        [[[self class] cellCache] objectForKey:self.identifier];

    if (!timelineCell)
        timelineCell = [self createCell];

    return timelineCell;
}

- (TimelineTableViewCell *)createCell
{
    TimelineTableViewCell * timelineCell =
        [[TimelineTableViewCell alloc]
         initWithStyle:UITableViewCellStyleDefault 
         reuseIdentifier:@"TimelineTableViewCell"];

    [timelineCell setName:[self displayName]];
    [timelineCell setDate:self.timestamp];
    NSString * tweetText = [self.text stringByDecodingHtmlEntities];
    [timelineCell setTweetText:tweetText];
    timelineCell.avatarImageUrl = self.user.avatar.thumbnailImageUrl;
    UIImage * avatar = [self.user thumbnailAvatar];
    if (avatar)
        [timelineCell setAvatarImage:avatar];

    [[[self class] cellCache]
        setObject:timelineCell forKey:self.identifier];

    CGFloat cellHeight =
        [TimelineTableViewCell heightForContent:tweetText
        displayType:kTimelineTableViewCellTypeNormal landscape:NO];
    CGSize drawingSize = CGSizeMake(320, cellHeight + 1);
    
    CGRect cellFrame = timelineCell.frame;
    cellFrame.size = drawingSize;
    timelineCell.frame = cellFrame;

    UIGraphicsBeginImageContext(drawingSize);
    [timelineCell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIGraphicsEndImageContext();
    
    return [timelineCell autorelease];
}

+ (NSMutableDictionary *)cellCache
{
    if (!cells)
        cells = [[NSMutableDictionary dictionary] retain];

    return cells;
}

@end
 */
