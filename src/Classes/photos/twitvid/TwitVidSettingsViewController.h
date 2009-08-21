//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwitVidCredentials.h"

@protocol TwitVidSettingsViewControllerDelegate

- (void)userDidSaveUsername:(NSString *)username password:(NSString *)password;
- (void)userDidCancel;
- (void)deleteServiceWithCredentials:(TwitVidCredentials *)credentials;

@end

@interface TwitVidSettingsViewController :
    UITableViewController <UITextFieldDelegate, UIActionSheetDelegate>
{
    id<TwitVidSettingsViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * saveButton;
    IBOutlet UIBarButtonItem * cancelButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * passwordCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * passwordTextField;

    UIButton * deleteButton;

    BOOL enabled;

    TwitVidCredentials * credentials;
}

@property (nonatomic, assign) id<TwitVidSettingsViewControllerDelegate>
    delegate;
@property (nonatomic, retain) TwitVidCredentials * credentials;

- (void)enable;
- (void)disable;

#pragma mark Button actions

- (IBAction)userDidSave:(id)sender;
- (IBAction)userDidCancel:(id)sender;

@end
