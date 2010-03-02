//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountsViewController.h"
#import "XauthLogInDisplayMgr.h"
#import "TwitterCredentials.h"
#import "AccountSettingsDisplayMgr.h"
#import "UserFetcher.h"

@class CredentialsSetChangedPublisher;

@interface AccountsDisplayMgr :
    NSObject
    <AccountsViewControllerDelegate, XauthLogInDisplayMgrDelegate,
    AccountSettingsDisplayMgrDelegate, UserFetcherDelegate>
{
    AccountsViewController * accountsViewController;

    XauthLogInDisplayMgr * logInDisplayMgr;
    AccountSettingsDisplayMgr * accountSettingsDisplayMgr;

    NSMutableSet * userAccounts;
    NSMutableSet * pendingUserFetches;

    CredentialsSetChangedPublisher * credentialsSetChangedPublisher;

    NSManagedObjectContext * context;
}

- (id)initWithAccountsViewController:(AccountsViewController *)aViewController
                     logInDisplayMgr:(XauthLogInDisplayMgr *)aLogInDisplayMgr
                             context:(NSManagedObjectContext *)aContext;

- (TwitterCredentials *)selectedAccount;

@end
