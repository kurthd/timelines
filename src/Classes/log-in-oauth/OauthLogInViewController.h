//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OauthLogInViewControllerDelegate

- (void)userDidCancel;
- (void)userIsDone:(NSString *)pin;

@end

@interface OauthLogInViewController : UIViewController <UITextFieldDelegate>
{
    id<OauthLogInViewControllerDelegate> delegate;

    IBOutlet UIWebView * webView;

    UIBarButtonItem * cancelButton;
    UIBarButtonItem * doneButton;

    IBOutlet UIBarButtonItem * activityButton;
    IBOutlet UIActivityIndicatorView * activityIndicator;

    IBOutlet UITextField * pinTextField;

    UIViewController * helpViewController;
}

@property (nonatomic, assign) id<OauthLogInViewControllerDelegate> delegate;

@property (nonatomic, retain) UIBarButtonItem * cancelButton;
@property (nonatomic, retain) UIBarButtonItem * doneButton;

- (void)loadAuthRequest:(NSURLRequest *)request;

- (IBAction)userDidCancel;
- (IBAction)userIsDone;
- (IBAction)showHelpView;

@end
