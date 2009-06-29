//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kAuthChallenge,
    kEnterPin,
    kOther
} AuthState;

@protocol OauthLogInViewControllerDelegate

- (void)userDidCancel;
- (void)userIsDone:(NSString *)pin;
- (void)userDidStartOver;

@end

@interface OauthLogInViewController : UIViewController
{
    id<OauthLogInViewControllerDelegate> delegate;

    IBOutlet UIWebView * webView;

    IBOutlet UINavigationBar * navigationBar;
    IBOutlet UIBarButtonItem * cancelButton;
    IBOutlet UIBarButtonItem * doneButton;
    IBOutlet UIBarButtonItem * startOverButton;

    IBOutlet UIView * enterPinView;
    IBOutlet UITextField * pinTextField;

    IBOutlet UIView * activityView;

    BOOL logInCanBeCancelled;

    AuthState authState;
}

@property (nonatomic, assign) id<OauthLogInViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL logInCanBeCancelled;

- (void)loadAuthRequest:(NSURLRequest *)request;

- (void)showActivityView:(BOOL)animated;
- (void)hideActivityView:(BOOL)animated;

- (IBAction)userDidCancel;
- (IBAction)userDidFinish;
- (IBAction)userDidStartOver;

@end
