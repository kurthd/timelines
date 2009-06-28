//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OauthLogInViewControllerDelegate

- (void)userDidCancel;
- (void)userIsDone:(NSString *)pin;

@end

@interface OauthLogInViewController : UIViewController
{
    id<OauthLogInViewControllerDelegate> delegate;

    IBOutlet UIWebView * webView;

    IBOutlet UIBarButtonItem * cancelButton;
    IBOutlet UIBarButtonItem * doneButton;

    IBOutlet UIView * enterPinView;
    IBOutlet UITextField * pinTextField;

    NSURLRequest * request;
}

@property (nonatomic, assign) id<OauthLogInViewControllerDelegate> delegate;

- (IBAction)userDidCancel;
- (IBAction)userIsDone;

- (void)loadRequest:(NSURLRequest *)aRequest;

@end
