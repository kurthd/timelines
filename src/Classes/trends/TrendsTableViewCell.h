//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TrendsTableViewCellView;

@interface TrendsTableViewCell : UITableViewCell
{
    TrendsTableViewCellView * trendsView;
}

- (void)setTitle:(NSString *)title;
- (void)setExplanation:(NSString *)explanation;
- (void)setLandscape:(BOOL)landscape;

+ (CGFloat)heightForTitle:(NSString *)title explanation:(NSString *)explanation;

@end
