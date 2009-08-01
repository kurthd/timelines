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

    BOOL highlighted;
}

@property (nonatomic, copy) NSString * text;
@property (nonatomic, copy) NSString * author;
@property (nonatomic, copy) NSString * timestamp;
@property (nonatomic, retain) UIImage * avatar;
@property (nonatomic, assign) TimelineTableViewCellType cellType;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;

//- (void)setAvatarView:(RoundedImage *)avatarView;
//- (void)setDisplayType:(TimelineTableViewCellType)displayType;

@end
