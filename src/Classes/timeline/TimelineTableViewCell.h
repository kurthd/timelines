//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedImage.h";

@class TimelineTableViewCellView;

typedef enum {
    kTimelineTableViewCellTypeNormal,
    kTimelineTableViewCellTypeInverted,
    kTimelineTableViewCellTypeNoAvatar,
    kTimelineTableViewCellTypeNormalNoName
} TimelineTableViewCellType;

@interface TimelineTableViewCell : UITableViewCell
{
    TimelineTableViewCellView * timelineView;
    NSString * avatarImageUrl;
}

@property (nonatomic, copy) NSString * avatarImageUrl;

- (void)setAvatarImage:(UIImage *)image;
- (void)setName:(NSString *)name;
- (void)setDate:(NSDate *)date;
- (void)setTweetText:(NSString *)tweetText;
- (void)setDisplayType:(TimelineTableViewCellType)displayType;
- (void)setHighlightForMention:(BOOL)highlight;
- (void)setDarkenForOld:(BOOL)darken;

+ (NSString *)reuseIdentifier;
+ (CGFloat)heightForContent:(NSString *)tweetText
    displayType:(TimelineTableViewCellType)displayType;

@end
