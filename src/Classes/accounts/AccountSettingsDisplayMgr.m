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
@property (nonatomic, retain) InstapaperLogInDisplayMgr * instapaperDisplayMgr;

@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation AccountSettingsDisplayMgr

@synthesize delegate;
@synthesize navigationController, accountSettingsViewController;
@synthesize photoServicesDisplayMgr, instapaperDisplayMgr;
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

- (void)userWantsToConfigureInstapaperForAccount:
    (TwitterCredentials *)credentials
{
    self.instapaperDisplayMgr.credentials = credentials;
    [self.instapaperDisplayMgr
        configureExistingAccountWithNavigationController:
        self.navigationController];
}

#pragma mark PhotoServiceDisplayMgrDelegate implementation

- (NSString *)currentlySelectedPhotoServiceName:(TwitterCredentials *)ctls
{
    AccountSettings * settings =
        [AccountSettings settingsForKey:ctls.username];
    return [settings photoServiceName];
}

- (NSString *)currentlySelectedVideoServiceName:(TwitterCredentials *)ctls
{
    AccountSettings * settings =
        [AccountSettings settingsForKey:ctls.username];
    return [settings videoServiceName];
}

- (void)userDidSelectPhotoServiceWithName:(NSString *)name
                              credentials:(TwitterCredentials *)ctls
{
    AccountSettings * settings =
        [AccountSettings settingsForKey:ctls.username];
    [settings setPhotoServiceName:name];
    [AccountSettings setSettings:settings forKey:ctls.username];
}

- (void)userDidSelectVideoServiceWithName:(NSString *)name
                              credentials:(TwitterCredentials *)ctls
{
    AccountSettings * settings =
        [AccountSettings settingsForKey:ctls.username];
    [settings setVideoServiceName:name];
    [AccountSettings setSettings:settings forKey:ctls.username];
}

#pragma mark InstapaperLogInDisplayMgrDelegate implementation

- (void)accountCreated:(InstapaperCredentials *)credentials
{
    [self.accountSettingsViewController reloadDisplay];
}

- (void)accountCreationCancelled
{
    // nothing changed, so nothing to do
}

- (void)accountEdited:(InstapaperCredentials *)credentials
{
    [self.accountSettingsViewController reloadDisplay];
}

- (void)editingAccountCancelled:(InstapaperCredentials *)credentials
{
    // nothing changed, so nothing to do
}

- (void)accountWillBeDeleted:(InstapaperCredentials *)instapaperCredentials
{
    [self.accountSettingsViewController reloadDisplay];
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

- (InstapaperLogInDisplayMgr *)instapaperDisplayMgr
{
    if (!instapaperDisplayMgr) {
        instapaperDisplayMgr =
            [[InstapaperLogInDisplayMgr alloc] initWithContext:self.context];
        instapaperDisplayMgr.delegate = self;
    }

    return instapaperDisplayMgr;
}

@end
