//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage (DrawingAdditions)

//
// Draw the image at the given point, with rounded corners of the provided
// radius. Preserves the image's native height and width.
//
- (void)drawWithRoundedCornersAtPoint:(CGPoint)point withRadius:(CGFloat)radius;
- (void)drawWithRoundedCornersAtPoint:(CGPoint)point
                           withRadius:(CGFloat)radius
                         usingContext:(CGContextRef)context;

//
// Draw the image within the bounds of the given rectangle, with rounded
// corners of the provided radius. Scales the image as appropriate to fill
// the contents of the rectangle.
//

- (void)drawInRect:(CGRect)rect withRoundedCornersWithRadius:(CGFloat)radius;
- (void)drawInRect:(CGRect)rect withRoundedCornersWithRadius:(CGFloat)radius
    usingContext:(CGContextRef)context;

- (void)drawInRect:(CGRect)rect withRoundedCornersWithRadius:(CGFloat)radius
    alpha:(CGFloat)alpha;
- (void)drawInRect:(CGRect)rect withRoundedCornersWithRadius:(CGFloat)radius
    usingContext:(CGContextRef)context alpha:(CGFloat)alpha;

@end
