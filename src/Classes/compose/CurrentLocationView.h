//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CurrentLocationView : UIView
{
    IBOutlet UIImageView * pushpinImageView;
    IBOutlet UIImageView * errorImageView;
    IBOutlet UIActivityIndicatorView * activityIndicator;
    IBOutlet UILabel * descriptionLabel;
}

- (void)setText:(NSString *)text;
- (void)displayActivity:(BOOL)displayActivity;
- (void)setErrorMessage:(NSString *)errorMessage;

@end
