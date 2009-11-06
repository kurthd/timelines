//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FastTimelineTableViewCellDisplayType.h"

@class FastTimelineTableViewCellView;

@interface FastTimelineTableViewCell : UITableViewCell
{
    FastTimelineTableViewCellView * timelineView;
    id userData;
}

- (void)setLandscape:(BOOL)landscape;
- (void)setDisplayType:(FastTimelineTableViewCellDisplayType)type;
- (void)setTweetText:(NSString *)tweetText;
- (void)setAuthor:(NSString *)author;
- (void)setTimestamp:(NSString *)timestamp;
- (void)setAvatar:(UIImage *)avatar;
- (void)setFavorite:(BOOL)favorite;

- (void)displayAsMention:(BOOL)displayAsMention;
- (void)displayAsOld:(BOOL)displayAsOld;

@property (nonatomic, retain) id userData;

+ (CGFloat)heightForContent:(NSString *)tweetText
                displayType:(FastTimelineTableViewCellDisplayType)displayType
                  landscape:(BOOL)landscape;

@end
