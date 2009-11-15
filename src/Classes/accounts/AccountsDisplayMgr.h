//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountsViewController.h"
#import "OauthLogInDisplayMgr.h"
#import "TwitterCredentials.h"
#import "AccountSettingsDisplayMgr.h"
#import "UserFetcher.h"

@class CredentialsSetChangedPublisher;

@interface AccountsDisplayMgr :
    NSObject
    <AccountsViewControllerDelegate, OathLogInDisplayMgrDelegate,
    AccountSettingsDisplayMgrDelegate, UserFetcherDelegate>
{
    AccountsViewController * accountsViewController;

    OauthLogInDisplayMgr * logInDisplayMgr;
    AccountSettingsDisplayMgr * accountSettingsDisplayMgr;

    NSMutableSet * userAccounts;
    NSMutableSet * pendingUserFetches;

    CredentialsSetChangedPublisher * credentialsSetChangedPublisher;

    NSManagedObjectContext * context;
}

- (id)initWithAccountsViewController:(AccountsViewController *)aViewController
                     logInDisplayMgr:(OauthLogInDisplayMgr *)aLogInDisplayMgr
                             context:(NSManagedObjectContext *)aContext;

- (TwitterCredentials *)selectedAccount;

@end
