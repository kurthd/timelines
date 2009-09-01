//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InstapaperCredentials.h"

typedef enum {
    InstapaperLogInViewControllerDisplayModeCreateAccount,
    InstapaperLogInViewControllerDisplayModeEditAccount
} InstapaperLogInViewControllerDisplayMode;

@protocol InstapaperLogInViewControllerDelegate

- (void)userDidSave:(NSString *)username password:(NSString *)password;
- (void)userDidCancel;

@end

@interface InstapaperLogInViewController : UITableViewController
{
    id<InstapaperLogInViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * saveButton;
    IBOutlet UIBarButtonItem * cancelButton;
    IBOutlet UIBarButtonItem * activityButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * passwordCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * passwordTextField;

    UIButton * deleteButton;

    InstapaperCredentials * credentials;

    InstapaperLogInViewControllerDisplayMode displayMode;

    BOOL displayingActivity;
}

@property (nonatomic, assign) id<InstapaperLogInViewControllerDelegate>
    delegate;
@property (nonatomic, retain) InstapaperCredentials * credentials;
@property (nonatomic, assign) InstapaperLogInViewControllerDisplayMode
    displayMode;

@property (nonatomic, assign, readonly) BOOL displayingActivity;

- (id)initWithDelegate:(id<InstapaperLogInViewControllerDelegate>)aDelegate;

#pragma mark Public interface

- (void)displayActivity;
- (void)hideActivity;

#pragma mark Button actions

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end
