//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserInfoLabelCellView : UIView
{
    NSString * keyText;
    NSString * valueText;

	BOOL highlighted;
}

@property (nonatomic, getter=isHighlighted) BOOL highlighted;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)aBackgroundColor;

- (void)setKeyText:(NSString *)keyText valueText:(NSString *)valueText;

@end
