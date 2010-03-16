//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PosterousCredentials.h"

@protocol PosterousSettingsViewControllerDelegate

- (void)userDidSaveUsername:(NSString *)username password:(NSString *)password;
- (void)userDidCancel;
- (void)deleteServiceWithCredentials:(PosterousCredentials *)credentials;

@end

@interface PosterousSettingsViewController :
    UITableViewController <UITextFieldDelegate, UIActionSheetDelegate>
{
    id<PosterousSettingsViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * saveButton;
    IBOutlet UIBarButtonItem * cancelButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * passwordCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * passwordTextField;

    UIButton * deleteButton;

    BOOL enabled;

    PosterousCredentials * credentials;
}

@property (nonatomic, assign) id<PosterousSettingsViewControllerDelegate>
    delegate;
@property (nonatomic, retain) PosterousCredentials * credentials;

- (void)enable;
- (void)disable;

#pragma mark Button actions

- (IBAction)userDidSave:(id)sender;
- (IBAction)userDidCancel:(id)sender;

@end
