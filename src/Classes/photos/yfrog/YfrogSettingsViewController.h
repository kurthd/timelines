//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YfrogCredentials.h"

@protocol YfrogSettingsViewControllerDelegate

- (void)userDidSaveUsername:(NSString *)username password:(NSString *)password;
- (void)userDidCancel;
- (void)deleteServiceWithCredentials:(YfrogCredentials *)credentials;

@end

@interface YfrogSettingsViewController :
    UITableViewController <UITextFieldDelegate, UIActionSheetDelegate>
{
    id<YfrogSettingsViewControllerDelegate> delegate;

    IBOutlet UIBarButtonItem * saveButton;
    IBOutlet UIBarButtonItem * cancelButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * passwordCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * passwordTextField;

    UIButton * deleteButton;

    BOOL enabled;

    YfrogCredentials * credentials;
}

@property (nonatomic, assign) id<YfrogSettingsViewControllerDelegate>
    delegate;
@property (nonatomic, retain) YfrogCredentials * credentials;

- (void)enable;
- (void)disable;

#pragma mark Button actions

- (IBAction)userDidSave:(id)sender;
- (IBAction)userDidCancel:(id)sender;

@end
