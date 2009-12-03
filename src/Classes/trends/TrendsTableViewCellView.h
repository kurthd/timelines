//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrendsTableViewCellView : UIView
{
    BOOL highlighted;

    NSString * title;
    NSString * explanation;
}

@property (nonatomic, getter=isHighlighted) BOOL highlighted;

@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * explanation;

+ (CGFloat)heightForTitle:(NSString *)title explanation:(NSString *)explanation;

@end
