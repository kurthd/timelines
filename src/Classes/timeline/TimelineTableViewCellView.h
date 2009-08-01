//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimelineTableViewCellView : UIView
{
    NSString * text;
    NSString * author;
    NSString * timestamp;
    UIImage * avatar;

    BOOL highlighted;
}

@property (nonatomic, copy) NSString * text;
@property (nonatomic, copy) NSString * author;
@property (nonatomic, copy) NSString * timestamp;
@property (nonatomic, retain) UIImage * avatar;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;

//- (void)setAvatarView:(RoundedImage *)avatarView;
//- (void)setDisplayType:(TimelineTableViewCellType)displayType;

@end
