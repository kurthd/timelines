//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountsViewController.h"
#import "LogInDisplayMgr.h"
#import "TwitterCredentials.h"

@class CredentialsSetChangedPublisher;

@interface AccountsDisplayMgr :
    NSObject <AccountsViewControllerDelegate, LogInDisplayMgrDelegate>
{
    AccountsViewController * accountsViewController;
    LogInDisplayMgr * logInDisplayMgr;

    NSMutableSet * userAccounts;

    CredentialsSetChangedPublisher * credentialsSetChangedPublisher;

    NSManagedObjectContext * context;
}

- (id)initWithAccountsViewController:(AccountsViewController *)aViewController
                     logInDisplayMgr:(LogInDisplayMgr *)aLogInDisplayMgr
                             context:(NSManagedObjectContext *)aContext;

- (TwitterCredentials *)selectedAccount;

@end
