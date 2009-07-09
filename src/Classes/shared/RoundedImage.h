//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RoundedImage : UIView
{
    IBOutlet UIImageView * imageView;
    float radius;
}

@property (nonatomic, assign) float radius;

- (id)initWithRadius:(float)aRadius;

- (void)setImage:(UIImage *)image;
- (UIImage *)image;

@end
