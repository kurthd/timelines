//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XauthLogInViewControllerDelegate;

@interface XauthLogInViewController :
    UITableViewController <UITextFieldDelegate>
{
    id<XauthLogInViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * saveButton;
    IBOutlet UIBarButtonItem * cancelButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * passwordCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * passwordTextField;
    
    IBOutlet UILabel * usernameLabel;
    IBOutlet UILabel * passwordLabel;

    BOOL allowsCancel;
}

@property (nonatomic, assign) id<XauthLogInViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL allowsCancel;

- (void)displayActivity:(BOOL)activity;

- (IBAction)userDidSave:(id)sender;
- (IBAction)userDidCancel:(id)sender;

@end


@protocol XauthLogInViewControllerDelegate

- (void)userDidSaveUsername:(NSString *)username password:(NSString *)password;
- (void)userDidCancel;

- (BOOL)isUsernameValid:(NSString *)username;

@end

