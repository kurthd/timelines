//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "UIImage+DrawingAdditions.h"

#define DEGREES_TO_RADIANS(degrees) ((degrees) / 57.2958)

@implementation UIImage (DrawingAdditions)

- (void)drawWithRoundedCornersAtPoint:(CGPoint)point withRadius:(CGFloat)radius
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawWithRoundedCornersAtPoint:point
                             withRadius:radius
                           usingContext:context];
}

- (void)drawWithRoundedCornersAtPoint:(CGPoint)point
                           withRadius:(CGFloat)radius
                         usingContext:(CGContextRef)context
{
    // round the corners
    CGMutablePathRef outlinePath = CGPathCreateMutable(); 

    CGRect imageRect =
        CGRectMake(point.x, point.y, self.size.width, self.size.height);
    CGRect interiorRect = CGRectInset(imageRect, radius, radius);

    CGPathAddArc(outlinePath, NULL,
        CGRectGetMinX(interiorRect), CGRectGetMinY(interiorRect),
        radius,
        DEGREES_TO_RADIANS(180), DEGREES_TO_RADIANS(270),
        NO);

    CGPathAddArc(outlinePath, NULL,
        CGRectGetMaxX(interiorRect), CGRectGetMinY(interiorRect),
        radius,
        DEGREES_TO_RADIANS(270), DEGREES_TO_RADIANS(360),
        NO);

    CGPathAddArc(outlinePath, NULL,
        CGRectGetMaxX(interiorRect), CGRectGetMaxY(interiorRect),
        radius,
        0, DEGREES_TO_RADIANS(90.0),
        NO);

    CGPathAddArc(outlinePath, NULL,
        CGRectGetMinX(interiorRect), CGRectGetMaxY(interiorRect),
        radius,
        DEGREES_TO_RADIANS(90.0), DEGREES_TO_RADIANS(180.0),
        NO);
    
    CGPathCloseSubpath(outlinePath);

    CGContextSaveGState(context); 

    CGContextAddPath(context, outlinePath); 
    CGContextClip(context); 

    CGPathRelease(outlinePath);

    // draw the actual image
    [self drawAtPoint:point];
}

@end
