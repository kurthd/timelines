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
    BOOL highlightForMention;

    BOOL highlighted;
}

@property (nonatomic, copy) NSString * text;
@property (nonatomic, copy) NSString * author;
@property (nonatomic, copy) NSString * timestamp;
@property (nonatomic, retain) UIImage * avatar;
@property (nonatomic, assign) TimelineTableViewCellType cellType;
@property (nonatomic, assign) BOOL highlightForMention;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;

+ (CGFloat)heightForContent:(NSString *)tweetText
                   cellType:(TimelineTableViewCellType)cellType;

+ (UIColor *)defaultTimelineCellColor;
+ (UIColor *)mentionCellColor;
               
@end
