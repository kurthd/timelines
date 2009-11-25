//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CurrentLocationView : UIView
{
    IBOutlet UIActivityIndicatorView * activityIndicator;
    IBOutlet UITextField * textField;
}

- (void)setText:(NSString *)text;
- (void)displayActivity:(BOOL)displayActivity;

@end
