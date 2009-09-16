//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    BitlyLogInViewControllerDisplayModeCreateAccount,
    BitlyLogInViewControllerDisplayModeEditAccount
} BitlyLogInViewControllerDisplayMode;

@protocol BitlyLogInViewControllerDelegate

- (void)userDidSave:(NSString *)username password:(NSString *)password;
- (void)userDidCancel;

//- (void)deleteAccount:(BitlyCredentials *)credentials;

@end

@interface BitlyLogInViewController :
    UITableViewController <UIActionSheetDelegate>
{
    id<BitlyLogInViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * saveButton;
    IBOutlet UIBarButtonItem * cancelButton;
    IBOutlet UIBarButtonItem * activityButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * passwordCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * passwordTextField;

//    BitlyCredentials * credentials;

    BitlyLogInViewControllerDisplayMode displayMode;

    BOOL displayingActivity;
    BOOL editingExistingAccount;
}

@property (nonatomic, assign) id<BitlyLogInViewControllerDelegate> delegate;
//@property (nonatomic, retain) BitlyCredentials * credentials;
@property (nonatomic, assign) BitlyLogInViewControllerDisplayMode displayMode;

@property (nonatomic, assign, readonly) BOOL displayingActivity;
@property (nonatomic, assign) BOOL editingExistingAccount;

- (id)initWithDelegate:(id<BitlyLogInViewControllerDelegate>)aDelegate;

#pragma mark Public interface

- (void)displayActivity;
- (void)hideActivity;

#pragma mark Button actions

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end
