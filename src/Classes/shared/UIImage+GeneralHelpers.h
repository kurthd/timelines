//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (GeneralHelpers)

- (UIImage *)imageByRotatingByOrientation:(UIImageOrientation)orientation;

- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;

@end
