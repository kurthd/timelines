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

    IBOutlet UINavigationBar * navigationBar;
    IBOutlet UIBarButtonItem * cancelButton;
    IBOutlet UIBarButtonItem * doneButton;
    IBOutlet UIBarButtonItem * savePinButton;

    IBOutlet UIView * enterPinView;
    IBOutlet UITextField * pinTextField;
}

@property (nonatomic, assign) id<OauthLogInViewControllerDelegate> delegate;

- (void)loadAuthRequest:(NSURLRequest *)request;

- (IBAction)userDidCancel;
- (IBAction)userIsDone;
- (IBAction)userDidSavePin;

@end
