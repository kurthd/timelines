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

- (void)deleteAccount:(InstapaperCredentials *)credentials;

@end

@interface InstapaperLogInViewController :
    UITableViewController <UIActionSheetDelegate>
{
    id<InstapaperLogInViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * saveButton;
    IBOutlet UIBarButtonItem * cancelButton;
    IBOutlet UIBarButtonItem * activityButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * passwordCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * passwordTextField;

    InstapaperCredentials * credentials;

    InstapaperLogInViewControllerDisplayMode displayMode;

    BOOL displayingActivity;
    BOOL editingExistingAccount;
}

@property (nonatomic, assign) id<InstapaperLogInViewControllerDelegate>
    delegate;
@property (nonatomic, retain) InstapaperCredentials * credentials;
@property (nonatomic, assign) InstapaperLogInViewControllerDisplayMode
    displayMode;

@property (nonatomic, assign, readonly) BOOL displayingActivity;
@property (nonatomic, assign) BOOL editingExistingAccount;

- (id)initWithDelegate:(id<InstapaperLogInViewControllerDelegate>)aDelegate;

#pragma mark Public interface

- (void)displayActivity;
- (void)hideActivity;

#pragma mark Button actions

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end
