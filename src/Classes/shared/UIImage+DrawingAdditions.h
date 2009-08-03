//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage (DrawingAdditions)

- (void)drawWithRoundedCornersAtPoint:(CGPoint)point withRadius:(CGFloat)radius;
- (void)drawWithRoundedCornersAtPoint:(CGPoint)point
                           withRadius:(CGFloat)radius
                         usingContext:(CGContextRef)context;

@end
