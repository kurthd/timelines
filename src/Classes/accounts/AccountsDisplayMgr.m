//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountsDisplayMgr.h"
#import "TwitbitShared.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "CredentialsSetChangedPublisher.h"
#import "AccountSettingsChangedPublisher.h"
#import "ActiveTwitterCredentials.h"
#import "NSManagedObject+TediousCodeAdditions.h"

@interface AccountsDisplayMgr ()

@property (nonatomic, retain) AccountsViewController * accountsViewController;
@property (nonatomic, retain) OauthLogInDisplayMgr * logInDisplayMgr;
@property (nonatomic, retain) AccountSettingsDisplayMgr *
    accountSettingsDisplayMgr;
@property (nonatomic, copy) NSMutableSet * userAccounts;
@property (nonatomic, retain) CredentialsSetChangedPublisher *
    credentialsSetChangedPublisher;
@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation AccountsDisplayMgr

@synthesize accountsViewController;
@synthesize logInDisplayMgr, accountSettingsDisplayMgr;
@synthesize userAccounts;
@synthesize context, credentialsSetChangedPublisher;

- (void)dealloc
{
    self.accountsViewController = nil;
    self.logInDisplayMgr = nil;
    self.accountSettingsDisplayMgr = nil;
    self.userAccounts = nil;
    self.credentialsSetChangedPublisher = nil;
    self.context = nil;

    [super dealloc];
}

- (id)initWithAccountsViewController:(AccountsViewController *)aViewController
                     logInDisplayMgr:(OauthLogInDisplayMgr *)aLogInDisplayMgr
                             context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.accountsViewController = aViewController;
        self.accountsViewController.delegate = self;

        self.logInDisplayMgr = aLogInDisplayMgr;
        self.logInDisplayMgr.allowsCancel = YES;
        self.logInDisplayMgr.delegate = self;

        self.context = aContext;

        credentialsSetChangedPublisher =
            [[CredentialsSetChangedPublisher alloc]
            initWithListener:self action:@selector(credentialsChanged:added:)];
    }

    return self;
}

- (TwitterCredentials *)selectedAccount
{
    return self.accountsViewController.selectedAccount;
}

#pragma mark CredentialsActivatedPublisher notification

- (void)credentialsChanged:(TwitterCredentials *)credentials
                     added:(NSNumber *)added
{
    if ([added integerValue]) {
        [self.userAccounts addObject:credentials];
        [self.accountsViewController accountAdded:credentials];
        self.logInDisplayMgr.allowsCancel = YES;
    }
}

#pragma mark AccountsViewControllerDelegate implementation

- (NSArray *)accounts
{
    return [self.userAccounts allObjects];
}

- (void)userWantsToAddAccount
{
    NSLog(@"User wants to add account");
    [self.logInDisplayMgr logIn:YES];
}

- (BOOL)userDeletedAccount:(TwitterCredentials *)credentials
{
    [self.userAccounts removeObject:credentials];
    if (self.userAccounts.count == 0) {
        self.logInDisplayMgr.allowsCancel = NO;
        [self.logInDisplayMgr logIn:YES];
    }

    NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        credentials, @"credentials",
        [NSNumber numberWithInteger:0], @"added",
        nil];

    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"CredentialsSetChangedNotification"
                      object:self
                    userInfo:userInfo];

    // Delete the credentials after the notification has been sent to allow
    // receivers to query the credentials object before it becomes invalid.

    NSString * username = [[credentials.username copy] autorelease];
    [context deleteObject:credentials];

    NSError * error = nil;
    if ([context save:&error])
        [AccountSettings deleteSettingsForKey:username];
    else {
        NSString * title = [NSString stringWithFormat:
            NSLocalizedString(@"account.deletion.failed.alert.title", @""),
            username];
        NSString * message = error.localizedDescription;
        [[UIAlertView simpleAlertViewWithTitle:title message:message] show];

        NSLog(@"WARNING: Failed to delete account '%@'. Detailed error:\n%@",
            username, [error detailedDescription]);

        return NO;
    }

    return YES;
}

- (void)userWantsToEditAccount:(TwitterCredentials *)credentials
{
    NSLog(@"Editing settings for account: '%@'.", credentials.username);
    [self.accountSettingsDisplayMgr editSettingsForAccount:credentials];
}

- (TwitterCredentials *)currentActiveAccount
{
    return [[ActiveTwitterCredentials findFirst:context] credentials];
}

#pragma mark LogInDisplayMgrDelegate implementation

- (BOOL)isUsernameValid:(NSString *)username
{
    for (TwitterCredentials * c in self.userAccounts)
        if ([c.username isEqualToString:username])
            return NO;
    return YES;
}

#pragma mark Accessors

- (AccountSettingsDisplayMgr *)accountSettingsDisplayMgr
{
    if (!accountSettingsDisplayMgr) {
        UINavigationController * navigationController =
            self.accountsViewController.navigationController;
        accountSettingsDisplayMgr =
            [[AccountSettingsDisplayMgr alloc]
            initWithNavigationController:navigationController
                                 context:self.context];
        accountSettingsDisplayMgr.delegate = self;
    }

    return accountSettingsDisplayMgr;
}

- (NSMutableSet *)userAccounts
{
    if (!userAccounts) {
        NSFetchRequest * request = [[NSFetchRequest alloc] init];
        NSEntityDescription * entity =
            [NSEntityDescription entityForName:@"TwitterCredentials"
                        inManagedObjectContext:self.context];
        [request setEntity:entity];

        NSSortDescriptor * sortDescriptor =
            [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
        NSArray *sortDescriptors =
            [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [request setSortDescriptors:sortDescriptors];

        [sortDescriptors release];
        [sortDescriptor release];

        NSError * error;
        NSArray * accounts =
            [context executeFetchRequest:request error:&error];

        if (!accounts) {
            NSString * title = NSLocalizedString(@"accounts.load.failed", @"");
            NSString * message = error.localizedDescription;

            UIAlertView * alert =
                [UIAlertView simpleAlertViewWithTitle:title
                                              message:message];
            [alert show];
        } else {
            userAccounts = [[NSSet setWithArray:accounts] mutableCopy];
            NSAssert1(userAccounts.count == accounts.count,
                @"Duplicate accounts have been persisted: '%@'.", accounts);
        }

        [request release];
    }

    return userAccounts;
}

@end
