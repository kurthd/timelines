//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountsViewController.h"
#import "LogInDisplayMgr.h"

@class CredentialsUpdatePublisher;

@interface AccountsDisplayMgr : NSObject <AccountsViewControllerDelegate>
{
    AccountsViewController * accountsViewController;
    LogInDisplayMgr * logInDisplayMgr;

    NSMutableSet * userAccounts;

    CredentialsUpdatePublisher * credentialsUpdatePublisher;

    NSManagedObjectContext * context;
}

- (id)initWithAccountsViewController:(AccountsViewController *)aViewController
                     logInDisplayMgr:(LogInDisplayMgr *)aLogInDisplayMgr
                             context:(NSManagedObjectContext *)aContext;

@end
