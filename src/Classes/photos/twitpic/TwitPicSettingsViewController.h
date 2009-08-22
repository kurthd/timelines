//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwitPicCredentials.h"

@protocol TwitPicSettingsViewControllerDelegate

- (void)userDidSaveUsername:(NSString *)username password:(NSString *)password;
- (void)userDidCancel;
- (void)deleteServiceWithCredentials:(TwitPicCredentials *)credentials;

@end

@interface TwitPicSettingsViewController :
    UITableViewController <UITextFieldDelegate, UIActionSheetDelegate>
{
    id<TwitPicSettingsViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * saveButton;
    IBOutlet UIBarButtonItem * cancelButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * passwordCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * passwordTextField;

    UIButton * deleteButton;

    BOOL enabled;

    TwitPicCredentials * credentials;
}

@property (nonatomic, assign) id<TwitPicSettingsViewControllerDelegate>
    delegate;
@property (nonatomic, retain) TwitPicCredentials * credentials;

- (void)enable;
- (void)disable;

#pragma mark Button actions

- (IBAction)userDidSave:(id)sender;
- (IBAction)userDidCancel:(id)sender;

@end
