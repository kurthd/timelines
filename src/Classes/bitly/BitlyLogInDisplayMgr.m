//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "BitlyLogInDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "BitlyCredentials.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "TwitbitShared.h"

@interface BitlyLogInDisplayMgr ()

@property (nonatomic, retain) BitlyLogInViewController * viewController;
@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) UINavigationController * navigationController;

@property (nonatomic, retain) NSManagedObjectContext * context;

- (void)dismissLogInViewController;

@end

@implementation BitlyLogInDisplayMgr

@synthesize delegate;
@synthesize viewController, navigationController, rootViewController;
@synthesize credentials , context;

- (void)dealloc
{
    self.delegate = nil;

    self.viewController = nil;
    self.rootViewController = nil;
    self.navigationController = nil;

    self.credentials = nil;
    self.context = nil;

    [super dealloc];
}

- (id)initWithContext:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.context = aContext;
        authenticating = NO;
    }

    return self;
}

- (void)logInModallyForViewController:(UIViewController *)aRootViewController
{
    self.viewController = nil;
    self.rootViewController = aRootViewController;

    UINavigationController * navController =
        [[UINavigationController alloc]
        initWithRootViewController:self.viewController];
    self.navigationController = navController;
    [navController release];

    [self.rootViewController
        presentModalViewController:self.navigationController animated:YES];
}

- (void)configureExistingAccountWithNavigationController:
    (UINavigationController *)aNavigationController
{
    self.viewController = nil;
    self.rootViewController = nil;
    self.navigationController = aNavigationController;

    [self.navigationController pushViewController:self.viewController
                                         animated:YES];
}

#pragma mark BitlyLogInViewControllerDelegate implementation

- (void)userDidSave:(NSString *)username apiKey:(NSString *)apiKey
{
    BOOL editingExisting = NO;

    BitlyCredentials * bc = self.credentials.bitlyCredentials;
    if (!bc) {
        bc = [BitlyCredentials createInstance:context];
        bc.credentials = self.credentials;
        editingExisting = YES;
    }
    bc.username = username;
    bc.apiKey = apiKey;

    NSError * error = nil;
    if (![context save:&error])
        NSLog(@"Failed to save changes to bitly credentials: %@",
            [error detailedDescription]);

    if (editingExisting)
        [self.delegate accountEdited:bc];
    else
        [self.delegate accountCreated:bc];

    [self dismissLogInViewController];
}

- (void)userDidCancel
{
    if (self.credentials.bitlyCredentials)
        [self.delegate
            editingAccountCancelled:self.credentials.bitlyCredentials];
    else
        [self.delegate accountCreationCancelled];

    [self dismissLogInViewController];
}

- (void)deleteAccount:(NSString *)username
{
    BitlyCredentials * bc = self.credentials.bitlyCredentials;
    if (bc) {
        [self.delegate accountWillBeDeleted:bc];

        [self.context deleteObject:bc];
        [self.context save:NULL];
    }

    [self dismissLogInViewController];
}

#pragma mark Private implementation

- (void)dismissLogInViewController
{
    if (self.rootViewController)
        [self.rootViewController dismissModalViewControllerAnimated:YES];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Accessors

- (BitlyLogInViewController *)viewController
{
    if (!viewController) {
        BitlyCredentials * c = credentials.bitlyCredentials;
        viewController =
            [[BitlyLogInViewController alloc] initWithUsername:c.username
                                                        apiKey:c.apiKey];
        viewController.editingExistingAccount = !!c;
        viewController.delegate = self;
    }

    return viewController;
}

@end
