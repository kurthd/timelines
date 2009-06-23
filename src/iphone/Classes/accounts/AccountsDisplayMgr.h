//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountsViewController.h"

@interface AccountsDisplayMgr : NSObject <AccountsViewControllerDelegate>
{
    AccountsViewController * accountsViewController;

    NSArray * userAccounts;

    NSManagedObjectContext * context;
}

- (id)initWithAccountsViewController:(AccountsViewController *)aViewController
                             context:(NSManagedObjectContext *)aContext;

@end
