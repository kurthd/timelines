//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "UIButton+StandardButtonAdditions.h"

@implementation UIButton (StandardButtonAdditions)

+ (id)deleteButtonWithTitle:(NSString *)title
{
    CGRect standardFrame = CGRectMake(10, 0, 300, 44);
    return [self deleteButtonWithTitle:title frame:standardFrame];
}

+ (id)deleteButtonWithTitle:(NSString *)title frame:(CGRect)frame
{
    UIButton * button = [[UIButton alloc] initWithFrame:frame];

    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    button.contentHorizontalAlignment =
        UIControlContentHorizontalAlignmentCenter;
    [button setTitle:title forState:UIControlStateNormal];

    // make the font bold while preserving the default point size
    UIFont * currentFont = button.titleLabel.font;
    UIFont * buttonFont = [UIFont boldSystemFontOfSize:currentFont.pointSize];
    button.titleLabel.font = buttonFont;

    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    UIImage * normalImage =
        [[UIImage imageNamed:@"DeleteButtonNormal.png"]
        stretchableImageWithLeftCapWidth:6.0 topCapHeight:0.0];
    [button setBackgroundImage:normalImage forState:UIControlStateNormal];

    UIImage * pressedImage =
        [[UIImage imageNamed:@"DeleteButtonPressed.png"]
        stretchableImageWithLeftCapWidth:6.0 topCapHeight:0.0];
    [button setBackgroundImage:pressedImage forState:UIControlStateHighlighted];

    button.backgroundColor = [UIColor clearColor];

    return button;
}

@end
