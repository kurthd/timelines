//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountsDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface AccountsDisplayMgr ()

@property (nonatomic, retain) AccountsViewController * accountsViewController;
@property (nonatomic, copy) NSArray * userAccounts;
@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;
@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation AccountsDisplayMgr

@synthesize logInDisplayMgr, accountsViewController, userAccounts, context;

- (void)dealloc
{
    self.accountsViewController = nil;
    self.userAccounts = nil;
    self.logInDisplayMgr = nil;
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
    }

    return self;
}

#pragma mark AccountsViewControllerDelegate implementation

- (NSArray *)accounts
{
    return self.userAccounts;
}

- (void)userWantsToAddAccount
{
    [self.logInDisplayMgr logIn];
}

#pragma mark Accessors

- (NSArray *)userAccounts
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
        userAccounts =
            [[context executeFetchRequest:request error:&error] retain];

        if (!userAccounts) {
            NSString * title = NSLocalizedString(@"accounts.load.failed", @"");
            NSString * message = error.localizedDescription;

            UIAlertView * alert =
                [UIAlertView simpleAlertViewWithTitle:title
                                              message:message];
            [alert show];
        }

        [request release];
    }

    return userAccounts;
}

@end
