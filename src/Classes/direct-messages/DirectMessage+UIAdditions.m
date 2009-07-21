//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessage+UIAdditions.h"
#import "User+UIAdditions.h"

@interface DirectMessage (Private)

- (TimelineTableViewCell *)createCell;
+ (NSMutableDictionary *)cellCache;

@end

@implementation DirectMessage (UIAdditions)

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

    if (!timelineCell) {
        timelineCell = [self createCell];
        RoundedImage * avatarView = [self.sender avatar];
        [timelineCell setAvatarView:avatarView];
    }

    return timelineCell;
}

- (TimelineTableViewCell *)createCell
{
    NSArray * nib =
        [[NSBundle mainBundle] loadNibNamed:@"TimelineTableViewCell"
        owner:self options:nil];

    TimelineTableViewCell * timelineCell = [nib objectAtIndex:0];

    NSString * displayName =
        self.sender.name ? self.sender.name : self.sender.username;
    [timelineCell setName:displayName];
    [timelineCell setDate:self.created];
    [timelineCell setTweetText:self.text];

    [[[self class] cellCache]
        setObject:timelineCell forKey:self.identifier];
    
    return timelineCell;
}

+ (NSMutableDictionary *)cellCache
{
    if (!cells)
        cells = [[NSMutableDictionary dictionary] retain];

    return cells;
}

@end
