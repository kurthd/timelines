//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimelineTableViewCell.h"  // for display type enumeration

@interface TimelineTableViewCellView : UIView
{
    NSString * text;
    NSString * author;
    NSString * timestamp;
    UIImage * avatar;
    TimelineTableViewCellType cellType;
    BOOL favorite;
    BOOL highlightForMention;
    BOOL darkenForOld;

    BOOL highlighted;

    BOOL landscape;
}

@property (nonatomic, copy) NSString * text;
@property (nonatomic, copy) NSString * author;
@property (nonatomic, copy) NSString * timestamp;
@property (nonatomic, retain) UIImage * avatar;
@property (nonatomic, assign) TimelineTableViewCellType cellType;
@property (nonatomic, assign) BOOL favorite;
@property (nonatomic, assign) BOOL highlightForMention;
@property (nonatomic, assign) BOOL darkenForOld;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL landscape;

+ (CGFloat)heightForContent:(NSString *)tweetText
                   cellType:(TimelineTableViewCellType)cellType
                  landscape:(BOOL)landscape;
+ (UIColor *)defaultTimelineCellColor;
+ (UIColor *)defaultDarkThemeCellColor;
+ (UIColor *)mentionCellColor;
+ (UIColor *)darkenedCellColor;

@end
