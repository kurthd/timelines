//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountsDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "CredentialsUpdatePublisher.h"

@interface AccountsDisplayMgr ()

@property (nonatomic, retain) AccountsViewController * accountsViewController;
@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;
@property (nonatomic, copy) NSMutableSet * userAccounts;
@property (nonatomic, retain) CredentialsUpdatePublisher *
    credentialsUpdatePublisher;
@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation AccountsDisplayMgr

@synthesize logInDisplayMgr, accountsViewController, userAccounts;
@synthesize context, credentialsUpdatePublisher;

- (void)dealloc
{
    self.accountsViewController = nil;
    self.logInDisplayMgr = nil;
    self.userAccounts = nil;
    self.credentialsUpdatePublisher = nil;
    self.context = nil;

    [super dealloc];
}

- (id)initWithAccountsViewController:(AccountsViewController *)aViewController
                     logInDisplayMgr:(LogInDisplayMgr *)aLogInDisplayMgr
                             context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.accountsViewController = aViewController;
        self.accountsViewController.delegate = self;
        self.logInDisplayMgr = aLogInDisplayMgr;
        self.logInDisplayMgr.allowsCancel = YES;
        self.context = aContext;

        credentialsUpdatePublisher =
            [[CredentialsUpdatePublisher alloc]
            initWithListener:self action:@selector(credentialsAdded:)];
    }

    return self;
}

#pragma mark CredentialsUpdatePublisher notification

- (void)credentialsAdded:(TwitterCredentials *)credentials
{
    [self.userAccounts addObject:credentials];
    [self.accountsViewController accountAdded:credentials];
}

#pragma mark AccountsViewControllerDelegate implementation

- (NSArray *)accounts
{
    return [self.userAccounts allObjects];
}

- (void)userWantsToAddAccount
{
    [self.logInDisplayMgr logIn];
}

#pragma mark Accessors

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
