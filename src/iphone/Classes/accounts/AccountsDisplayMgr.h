//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountsViewController.h"
#import "OauthLogInDisplayMgr.h"
#import "TwitterCredentials.h"

@class CredentialsSetChangedPublisher;

@interface AccountsDisplayMgr :
    NSObject <AccountsViewControllerDelegate, OathLogInDisplayMgrDelegate>
{
    AccountsViewController * accountsViewController;
    OauthLogInDisplayMgr * logInDisplayMgr;

    NSMutableSet * userAccounts;

    CredentialsSetChangedPublisher * credentialsSetChangedPublisher;

    NSManagedObjectContext * context;
}

- (id)initWithAccountsViewController:(AccountsViewController *)aViewController
                     logInDisplayMgr:(OauthLogInDisplayMgr *)aLogInDisplayMgr
                             context:(NSManagedObjectContext *)aContext;

- (TwitterCredentials *)selectedAccount;

@end
