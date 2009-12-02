//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CurrentLocationViewDelegate;

@interface CurrentLocationView : UIView
{
    id<CurrentLocationViewDelegate> delegate;

    IBOutlet UIImageView * pushpinImageView;
    IBOutlet UIImageView * errorImageView;
    IBOutlet UIActivityIndicatorView * activityIndicator;
    IBOutlet UILabel * descriptionLabel;
}

@property (nonatomic, assign) IBOutlet <CurrentLocationViewDelegate> delegate;

- (void)setText:(NSString *)text;
- (void)displayActivity:(BOOL)displayActivity;
- (void)setErrorMessage:(NSString *)errorMessage;

@end


@protocol CurrentLocationViewDelegate

- (void)userDidTouchView:(CurrentLocationView *)view;

@end
