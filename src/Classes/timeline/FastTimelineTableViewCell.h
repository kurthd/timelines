//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FastTimelineTableViewCellDisplayType.h"
#import "DateDescription.h"

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
- (void)setRetweetAuthor:(NSString *)retweetAuthor;
- (void)setTimestamp:(DateDescription *)timestamp;
- (void)setAvatar:(UIImage *)avatar;
- (void)setFavorite:(BOOL)favorite;
- (void)setGeocoded:(BOOL)geocoded;

- (void)displayAsMention:(BOOL)displayAsMention;
- (void)displayAsOld:(BOOL)displayAsOld;

@property (nonatomic, retain) id userData;

+ (CGFloat)heightForContent:(NSString *)tweetText
                    retweet:(BOOL)retweet
                displayType:(FastTimelineTableViewCellDisplayType)displayType
                  landscape:(BOOL)landscape;

@end
