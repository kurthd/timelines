//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountsViewController.h"
#import "LogInDisplayMgr.h"

@interface AccountsDisplayMgr : NSObject <AccountsViewControllerDelegate>
{
    AccountsViewController * accountsViewController;

    NSArray * userAccounts;

    LogInDisplayMgr * logInDisplayMgr;

    NSManagedObjectContext * context;
}

- (id)initWithAccountsViewController:(AccountsViewController *)aViewController
                     logInDisplayMgr:(LogInDisplayMgr *)aLogInDisplayMgr
                             context:(NSManagedObjectContext *)aContext;

@end
