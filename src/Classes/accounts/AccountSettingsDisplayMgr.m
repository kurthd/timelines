//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AccountSettingsDisplayMgr.h"
#import "AccountSettings.h"
#import "AccountSettingsChangedPublisher.h"

@interface AccountSettingsDisplayMgr ()

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) AccountSettingsViewController *
    accountSettingsViewController;

@property (nonatomic, retain) PhotoServicesDisplayMgr * photoServicesDisplayMgr;

@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation AccountSettingsDisplayMgr

@synthesize delegate;
@synthesize navigationController, accountSettingsViewController;
@synthesize photoServicesDisplayMgr;
@synthesize context;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationController = nil;
    self.accountSettingsViewController = nil;

    self.photoServicesDisplayMgr = nil;

    self.context = nil;

    [super dealloc];
}

- (id)initWithNavigationController:(UINavigationController *)aNavController
                           context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.navigationController = aNavController;
        self.context = aContext;
    }

    return self;
}

- (void)editSettingsForAccount:(TwitterCredentials *)credentials
{
    AccountSettings * settings =
        [AccountSettings settingsForKey:credentials.username];

    [self.accountSettingsViewController presentSettings:settings
                                             forAccount:credentials];

    [self.navigationController
        pushViewController:self.accountSettingsViewController animated:YES];
}

#pragma mark AccountSettingsViewControllerDelegate implementation

- (void)userDidCommitSettings:(AccountSettings *)newSettings
                   forAccount:(TwitterCredentials *)credentials
{
    AccountSettings * settings =
        [AccountSettings settingsForKey:credentials.username];

    if (![settings isEqualToSettings:newSettings]) {
        NSLog(@"Committing settings: '%@' for account: '%@'", newSettings,
            credentials);

        [AccountSettings setSettings:newSettings forKey:credentials.username];
        [AccountSettingsChangedPublisher
            publishAccountSettingsChanged:newSettings
                               forAccount:credentials.username];
    } else
        NSLog(@"User did not change settings for account: '%@'", settings);
}

- (void)userWantsToConfigurePhotoServicesForAccount:
    (TwitterCredentials *)credentials
{
    [self.photoServicesDisplayMgr
        configurePhotoServicesForAccount:credentials];
}

#pragma mark Accessors

- (AccountSettingsViewController *)accountSettingsViewController
{
    if (!accountSettingsViewController) {
        accountSettingsViewController =
            [[AccountSettingsViewController alloc]
            initWithNibName:@"AccountSettingsView" bundle:nil];
        accountSettingsViewController.delegate = self;
    }

    return accountSettingsViewController;
}

- (PhotoServicesDisplayMgr *)photoServicesDisplayMgr
{
    if (!photoServicesDisplayMgr) {
        photoServicesDisplayMgr =
            [[PhotoServicesDisplayMgr alloc]
            initWithNavigationController:self.navigationController
                                 context:self.context];
        photoServicesDisplayMgr.delegate = self;
    }

    return photoServicesDisplayMgr;
}

@end
