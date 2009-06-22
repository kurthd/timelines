//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RoundedImage : UIView
{
    IBOutlet UIImageView * imageView;
    float radius;
}

@property (nonatomic, retain) UIImageView * imageView;
@property (nonatomic, assign) float radius;

@end
