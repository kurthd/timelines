//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LogInViewControllerDelegate.h"

@interface LogInViewController : UIViewController
{
    id<LogInViewControllerDelegate> delegate;

    IBOutlet UINavigationBar * navigationBar;
    IBOutlet UITableView * tableView;

    IBOutlet UIBarButtonItem * logInButton;
    IBOutlet UIBarButtonItem * cancelButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * passwordCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * passwordTextField;
    
    NSString * title;
    NSString * footer;
}

@property (nonatomic, assign) id<LogInViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * footer;

- (void)promptForLogIn;
- (void)promptForLoginWithUsername:(NSString *)username editable:(BOOL)editable;

- (IBAction)userDidSave:(id)sender;
- (IBAction)userDidCancel:(id)sender;

@end
