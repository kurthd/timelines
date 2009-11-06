//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "UIImage+DrawingAdditions.h"

#define DEGREES_TO_RADIANS(degrees) ((degrees) / 57.2958)

@interface UIImage (DrawingAdditionsPrivate)

- (void)roundCornersInRect:(CGRect)imageRect
                withRadius:(CGFloat)radius
              usingContext:(CGContextRef)context;

@end

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
    CGRect rect =
        CGRectMake(point.x, point.y, self.size.width, self.size.height);
    [self roundCornersInRect:rect withRadius:radius usingContext:context];

    // draw the actual image
    [self drawAtPoint:point];
}

- (void)drawInRect:(CGRect)rect withRoundedCornersWithRadius:(CGFloat)radius
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawInRect:rect
        withRoundedCornersWithRadius:radius usingContext:context];
}

- (void)drawInRect:(CGRect)rect withRoundedCornersWithRadius:(CGFloat)radius
    usingContext:(CGContextRef)context
{
    [self roundCornersInRect:rect withRadius:radius usingContext:context];

    // draw the actual image
    [self drawInRect:rect];
}

- (void)drawInRect:(CGRect)rect withRoundedCornersWithRadius:(CGFloat)radius
    alpha:(CGFloat)alpha
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawInRect:rect
        withRoundedCornersWithRadius:radius usingContext:context
        alpha:alpha];
}

- (void)drawInRect:(CGRect)rect withRoundedCornersWithRadius:(CGFloat)radius
    usingContext:(CGContextRef)context alpha:(CGFloat)alpha
{
    [self roundCornersInRect:rect withRadius:radius usingContext:context];

    // draw the actual image
    [self drawInRect:rect blendMode:kCGBlendModeNormal alpha:alpha];
}

- (void)roundCornersInRect:(CGRect)imageRect
                withRadius:(CGFloat)radius
              usingContext:(CGContextRef)context
{
    // round the corners
    CGMutablePathRef outlinePath = CGPathCreateMutable(); 

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
}

@end
