//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetInfo+UIAdditions.h"
#import "User+UIAdditions.h"

@interface TweetInfo (Private)

- (TimelineTableViewCell *)createCell;
+ (NSMutableDictionary *)cellCache;
+ (BOOL)displayWithUsername;

@end

@implementation TweetInfo (UIAdditions)

static NSMutableDictionary * cells;
static BOOL displayWithUsername;
static BOOL alreadyReadDisplayWithUsernameValue;

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
        RoundedImage * avatarView = [self.user avatar];
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
        self.user.name && self.user.name.length > 0 &&
        ![[self class] displayWithUsername] ?
        self.user.name : self.user.username;
    [timelineCell setName:displayName];
    [timelineCell setDate:self.timestamp];
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

+ (BOOL)displayWithUsername
{
    if (!alreadyReadDisplayWithUsernameValue) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSInteger displayNameValAsNumber =
            [defaults integerForKey:@"display_name"];
        displayWithUsername = displayNameValAsNumber;
    }

    alreadyReadDisplayWithUsernameValue = YES;

    return displayWithUsername;
}

@end
