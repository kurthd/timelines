//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "RoundedImage.h"

@implementation RoundedImage

@synthesize radius;

- (void)dealloc
{
    [imageView release];
    [super dealloc];
}

- (void)awakeFromNib
{
    radius = 6.0;
}

- (id)init
{
    return [self initWithRadius:6.0];
}

- (id)initWithRadius:(float)aRadius
{
    if (self = [super init]) {
        imageView = [[UIImageView alloc] init];
        self.radius = aRadius;
    }

    return self;
}

- (void)drawRect:(CGRect)rect 
{ 
    CGContextRef ctx = UIGraphicsGetCurrentContext(); 
    CGMutablePathRef outlinePath = CGPathCreateMutable(); 

    float w = [self bounds].size.width; 
    float h = [self bounds].size.height;

    // Making the path and the rounded corners
    CGPathMoveToPoint(outlinePath, nil, radius, 0);
    CGPathAddArcToPoint(outlinePath, nil, 0, 0, 0, radius, radius);

    CGPathAddLineToPoint(outlinePath, nil, 0, h - radius); 
    CGPathAddArcToPoint(outlinePath, nil, 0, h, radius, h, radius);

    CGPathAddLineToPoint(outlinePath, nil, w - radius, h);
    CGPathAddArcToPoint(outlinePath, nil, w, h, w, h - radius, radius);

    CGPathAddLineToPoint(outlinePath, nil, w, radius);
    CGPathAddArcToPoint(outlinePath, nil, w, 0, w - radius, 0, radius);

    CGPathCloseSubpath(outlinePath);

    CGContextSaveGState(ctx); 
    
    CGContextAddPath(ctx, outlinePath); 
    CGContextClip(ctx); 
    
    // Drawing the image
    [imageView.image drawInRect:CGRectMake(0, 0, w, h)];
}

- (void)setImage:(UIImage *)image
{
    if (image != imageView.image) {
        imageView.image = image;
        [self setNeedsDisplay];
    }
}

- (UIImage *)image
{
    [self setNeedsDisplay];

    return imageView.image;
}

@end
