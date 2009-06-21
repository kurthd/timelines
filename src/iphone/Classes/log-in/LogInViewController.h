//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LogInViewControllerDelegate.h"

@interface LogInViewController : UIViewController
{
    id<LogInViewControllerDelegate> delegate;

    IBOutlet UITableView * tableView;

    IBOutlet UIBarButtonItem * logInButton;

    IBOutlet UITableViewCell * usernameCell;
    IBOutlet UITableViewCell * passwordCell;

    IBOutlet UITextField * usernameTextField;
    IBOutlet UITextField * passwordTextField;

    NSString * lighthouseDomain;
    NSString * lighthouseScheme;
}

@property (nonatomic, assign) id<LogInViewControllerDelegate> delegate;

- (void)promptForLogIn;

@end
