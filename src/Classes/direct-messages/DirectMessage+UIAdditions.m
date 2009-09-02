//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessage+UIAdditions.h"
#import "User+UIAdditions.h"

@interface DirectMessage (Private)

- (TimelineTableViewCell *)createCell;
+ (NSMutableDictionary *)cellCache;
+ (BOOL)displayWithUsername;

@end

@implementation DirectMessage (UIAdditions)

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

- (TimelineTableViewCell *)createCell
{
    TimelineTableViewCell * timelineCell =
        [[TimelineTableViewCell alloc]
        initWithStyle:UITableViewCellStyleDefault 
        reuseIdentifier:@"TimelineTableViewCell"];
        
    NSString * displayName =
        self.sender.name && ![[self class] displayWithUsername] ?
        self.sender.name : self.sender.username;
    [timelineCell setName:displayName];
    [timelineCell setDate:self.created];
    [timelineCell setTweetText:self.text];
    UIImage * avatar = [self.sender thumbnailAvatar];
    if (avatar)
        [timelineCell setAvatarImage:avatar];

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
