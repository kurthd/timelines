//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetInfo+UIAdditions.h"
#import "User+UIAdditions.h"
#import "NSString+HtmlEncodingAdditions.h"

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

- (TimelineTableViewCell *)cellWithAvatar
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
    [timelineCell setTweetText:[self.text stringByDecodingHtmlEntities]];
    timelineCell.avatarImageUrl = self.user.avatar.thumbnailImageUrl;

    [[[self class] cellCache]
        setObject:timelineCell forKey:self.identifier];
    
    return [timelineCell autorelease];
}

+ (NSMutableDictionary *)cellCache
{
    if (!cells)
        cells = [[NSMutableDictionary dictionary] retain];

    return cells;
}

@end
