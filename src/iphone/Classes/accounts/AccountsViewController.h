//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwitterCredentials.h"

@protocol AccountsViewControllerDelegate

- (NSArray *)accounts;

- (void)userWantsToAddAccount;

@end

@interface AccountsViewController : UITableViewController
{
    id<AccountsViewControllerDelegate> delegate;

    NSArray * accounts;
}

@property (nonatomic, assign) id<AccountsViewControllerDelegate> delegate;

- (IBAction)userWantsToAddAccount:(id)sender;
- (IBAction)editAccounts:(id)sender;

- (void)accountAdded:(TwitterCredentials *)credentials;

@end
