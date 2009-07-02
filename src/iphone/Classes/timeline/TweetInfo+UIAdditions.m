//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TweetInfo+UIAdditions.h"

@interface TweetInfo (Private)

+ (NSMutableDictionary *)cellCache;

@end

@implementation TweetInfo (UIAdditions)

static NSMutableDictionary * cells;

- (TimelineTableViewCell *)cell
{
    TimelineTableViewCell * timelineCell =
        [[[self class] cellCache] objectForKey:self.identifier];

    if (!timelineCell) {
        NSArray * nib =
            [[NSBundle mainBundle] loadNibNamed:@"TimelineTableViewCell"
            owner:self options:nil];

        timelineCell = [nib objectAtIndex:0];

        NSString * displayName =
            self.user.name ? self.user.name : self.user.username;
        [timelineCell setName:displayName];
        [timelineCell setDate:self.timestamp];
        [timelineCell setTweetText:self.text];
        
        [[[self class] cellCache]
            setObject:timelineCell forKey:self.identifier];
    }

    return timelineCell;
}

+ (NSMutableDictionary *)cellCache
{
    if (!cells)
        cells = [[NSMutableDictionary dictionary] retain];

    return cells;
}

@end
