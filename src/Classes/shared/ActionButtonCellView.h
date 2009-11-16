//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActionButtonCellView : UIView
{
    NSString * actionText;

    UIImage * actionImage;
	BOOL highlighted;
    BOOL landscape;
}

@property (nonatomic, retain) UIImage * actionImage;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL landscape;

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor *)aBackgroundColor;
- (void)setActionText:(NSString *)actionText;

@end
