//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TwitterCredentials.h"

@protocol AccountsViewControllerDelegate

- (NSArray *)accounts;

- (void)userWantsToAddAccount;
- (BOOL)userDeletedAccount:(TwitterCredentials *)credentials;

- (void)userWantsToEditAccount:(TwitterCredentials *)credentials;

- (TwitterCredentials *)currentActiveAccount;

@end

@interface AccountsViewController : UITableViewController
{
    id<AccountsViewControllerDelegate> delegate;

    NSArray * accounts;
    TwitterCredentials * selectedAccount;
}

@property (nonatomic, assign) id<AccountsViewControllerDelegate> delegate;
@property (nonatomic, retain) TwitterCredentials * selectedAccount;

- (IBAction)userWantsToAddAccount:(id)sender;

- (void)accountAdded:(TwitterCredentials *)credentials;

@end
