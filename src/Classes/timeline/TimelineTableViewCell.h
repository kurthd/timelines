//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoundedImage.h";

typedef enum {
    kTimelineTableViewCellTypeNormal,
    kTimelineTableViewCellTypeInverted,
    kTimelineTableViewCellTypeNoAvatar,
    kTimelineTableViewCellTypeNormalNoName
} TimelineTableViewCellType;

@interface TimelineTableViewCell : UITableViewCell
{
    IBOutlet RoundedImage * avatar;
    IBOutlet UILabel * nameLabel;
    IBOutlet UILabel * dateLabel;
    IBOutlet UILabel * tweetTextLabel;
    
    TimelineTableViewCellType displayType;
    
    BOOL needsLayout;
}

- (void)setAvatarView:(RoundedImage *)avatarView;
- (void)setAvatarImage:(UIImage *)image;
- (void)setName:(NSString *)name;
- (void)setDate:(NSDate *)date;
- (void)setTweetText:(NSString *)tweetText;
- (void)setDisplayType:(TimelineTableViewCellType)displayType;

+ (CGFloat)heightForContent:(NSString *)tweetText
    displayType:(TimelineTableViewCellType)displayType;

@end
