//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitchAppDelegate.h"
#import "DeviceRegistrar.h"
#import "LogInDisplayMgr.h"
#import "CredentialsActivatedPublisher.h"
#import "CredentialsSetChangedPublisher.h"
#import "TwitterCredentials.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "InfoPlistConfigReader.h"
#import "TwitterService.h"
#import "ComposeTweetDisplayMgr.h"
#import "PersonalFeedSelectionMgr.h"
#import "UserTimelineDataSource.h"
#import "AccountsDisplayMgr.h"
#import "ActiveTwitterCredentials.h"
#import "UIStatePersistenceStore.h"
#import "UIState.h"

@interface TwitchAppDelegate ()

@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;
@property (nonatomic, retain) ComposeTweetDisplayMgr * composeTweetDisplayMgr;
@property (nonatomic, retain) DeviceRegistrar * registrar;
@property (nonatomic, retain) NSMutableArray * credentials;
@property (nonatomic, retain) ActiveTwitterCredentials *
    activeCredentials;

- (void)initHomeTab;
- (void)initProfileTab;
- (void)initAccountsTab;

- (UIBarButtonItem *)newTweetButtonItem;
- (UIBarButtonItem *)sendingTweetProgressView;

- (void)broadcastActivatedCredentialsChanged:(TwitterCredentials *)tc;

- (void)registerDeviceForPushNotifications;
- (NSDictionary *)deviceRegistrationArgsForCredentials:(NSArray *)credentials;

- (BOOL)saveContext;
- (void)setUIStateFromPersistence;
- (void)persistUIState;

@end

@implementation TwitchAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize logInDisplayMgr;
@synthesize composeTweetDisplayMgr;
@synthesize registrar;
@synthesize credentials;
@synthesize activeCredentials;

- (void)dealloc
{
    [tabBarController release];
    [window release];

    [registrar release];
    [logInDisplayMgr release];

    [credentials release];
    [activeCredentials release];

    [credentialsActivatedPublisher release];
    [credentialsSetChangedPublisher release];

    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];

    [homeNetAwareViewController release];
    [profileNetAwareViewController release];
    [trendsNetAwareViewController release];
    [searchNetAwareViewController release];

    [timelineDisplayMgrFactory release];
    [timelineDisplayMgr release];
    [profileTimelineDisplayMgr release];

    [composeTweetDisplayMgr release];

    [accountsDisplayMgr release];

    [sendingTweetProgressView release];

    [super dealloc];
}

#pragma mark UIApplicationDelegate implementation

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    deviceNeedsRegistration = YES;
    [self registerDeviceForPushNotifications];

    // reset the unread message count to 0
    application.applicationIconBadgeNumber = 0;

    credentialsActivatedPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:self action:@selector(credentialsActivated:)];
    credentialsSetChangedPublisher =
        [[CredentialsSetChangedPublisher alloc]
         initWithListener:self action:@selector(credentialSetChanged:added:)];

    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:tabBarController.view];

    timelineDisplayMgrFactory =
        [[TimelineDisplayMgrFactory alloc]
        initWithContext:[self managedObjectContext]];
    [self initHomeTab];
    [self initProfileTab];
    [self initAccountsTab];
    [self setUIStateFromPersistence];

    if (self.credentials.count == 0) {
        NSAssert1(!self.activeCredentials.credentials, @"No credentials exist, "
            "but an active account has been set: '%@'.",
            self.activeCredentials.credentials);
        self.logInDisplayMgr.allowsCancel = NO;
        [self.logInDisplayMgr logIn];
    } else {
        NSAssert(self.activeCredentials.credentials, @"Credentials exist, but "
            "no active account has been set.");

        TwitterCredentials * c = self.activeCredentials.credentials;
        NSLog(@"Active credentials: '%@'.", c);

        [timelineDisplayMgr setCredentials:c];
        [profileTimelineDisplayMgr setCredentials:c];
        [self.composeTweetDisplayMgr setCredentials:c];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    if (tabBarController.selectedViewController ==
        accountsViewController.navigationController) {
        // make sure account changes get saved
        TwitterCredentials * activeAccount =
            [accountsDisplayMgr selectedAccount];
        self.activeCredentials.credentials = activeAccount;

        [self registerDeviceForPushNotifications];
    }

    if (managedObjectContext != nil)
        if (![self saveContext])
            exit(-1);  // fail
    
    [self persistUIState];
}

#pragma mark Composing tweets

- (IBAction)composeTweet:(id)sender
{
    [self.composeTweetDisplayMgr composeTweet];
}

#pragma mark ComposeTweetDisplayMgrDelegate implementation

- (void)userDidCancelComposingTweet
{
}

- (void)userIsSendingTweet:(NSString *)tweet
{
    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self sendingTweetProgressView]
                     animated:YES];
}

- (void)userDidSendTweet:(Tweet *)tweet
{
    UISegmentedControl * control = (UISegmentedControl *)
        homeNetAwareViewController.navigationItem.titleView;
    BOOL displayImmediately = control.selectedSegmentIndex == 0;
    NSLog(@"Displaying immediately? %d", displayImmediately);
    [timelineDisplayMgr addTweet:tweet displayImmediately:displayImmediately];

    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self newTweetButtonItem]
                     animated:YES];
}

- (void)userFailedToSendTweet:(NSString *)tweet
{
    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self sendingTweetProgressView]
                     animated:YES];

    [self.composeTweetDisplayMgr composeTweetWithText:tweet];
}

#pragma mark initialization helpers

- (void)initHomeTab
{
    NSString * homeTabTitle =
        NSLocalizedString(@"appdelegate.hometabtitle", @"");
    timelineDisplayMgr =
        [[timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        homeNetAwareViewController title:homeTabTitle
        managedObjectContext:[self managedObjectContext]]
        retain];
    timelineDisplayMgr.displayAsConversation = YES;
    UIBarButtonItem * refreshButton =
        homeNetAwareViewController.navigationItem.leftBarButtonItem;
    refreshButton.target = timelineDisplayMgr;
    refreshButton.action = @selector(refresh);

    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:[self managedObjectContext]]
        autorelease];

    PersonalFeedSelectionMgr * personalFeedSelectionMgr =
        [[PersonalFeedSelectionMgr alloc]
        initWithTimelineDisplayMgr:timelineDisplayMgr service:twitterService];
    UISegmentedControl * segmentedControl =
        (UISegmentedControl *)
        homeNetAwareViewController.navigationItem.titleView;
    [segmentedControl addTarget:personalFeedSelectionMgr
        action:@selector(tabSelected:)
        forControlEvents:UIControlEventValueChanged];
}

- (void)initProfileTab
{
    NSString * profileTabTitle =
        NSLocalizedString(@"appdelegate.profiletabtitle", @"");
    profileTimelineDisplayMgr =
        [[timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        profileNetAwareViewController title:profileTabTitle
        managedObjectContext:[self managedObjectContext]]
        retain];
    profileTimelineDisplayMgr.displayAsConversation = NO;
    profileTimelineDisplayMgr.setUserToFirstTweeter = YES;
    UIBarButtonItem * refreshButton =
        profileNetAwareViewController.navigationItem.leftBarButtonItem;
    refreshButton.target = profileTimelineDisplayMgr;
    refreshButton.action = @selector(refresh);

    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:[self managedObjectContext]]
        autorelease];
    UserTimelineDataSource * dataSource =
        [[[UserTimelineDataSource alloc] initWithTwitterService:twitterService]
        autorelease];

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];

    twitterService.delegate = dataSource;
    [profileTimelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO];
    dataSource.delegate = profileTimelineDisplayMgr;
}

- (void)initAccountsTab
{
    LogInDisplayMgr * displayMgr =
        [[LogInDisplayMgr alloc]
         initWithRootViewController:tabBarController
                managedObjectContext:[self managedObjectContext]];

    accountsDisplayMgr = [[AccountsDisplayMgr alloc]
        initWithAccountsViewController:accountsViewController
                       logInDisplayMgr:displayMgr
                               context:[self managedObjectContext]];

    [displayMgr release];
}

#pragma mark UITabBarControllerDelegate implementation

- (BOOL)tabBarController:(UITabBarController *)tbc
    shouldSelectViewController:(UIViewController *)viewController
{
    if (viewController == tbc.selectedViewController)  // not switching tabs
        return YES;

    if (viewController != accountsViewController.navigationController) {
        // switching away from the accounts tab

        TwitterCredentials * activeAccount =
            [accountsDisplayMgr selectedAccount];

        if (activeAccount &&
            activeAccount != self.activeCredentials.credentials) {
            NSLog(@"Switching account to: '%@'.", activeAccount);
            [self broadcastActivatedCredentialsChanged:activeAccount];
        }
    }

    return YES;
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"Twitch.sqlite"]];
	
	NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
        // Handle error
    }    
	
    return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory
{
    NSArray *paths =
        NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

#pragma mark Push notification delegate methods

- (void)application:(UIApplication *)app
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"Application did register for remote notifications.");

    NSDictionary * args =
        [self deviceRegistrationArgsForCredentials:credentials];
    [self.registrar sendProviderDeviceToken:deviceToken args:args];
}

- (void)application:(UIApplication *)app
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Application did fail to register for push notificaitons. Error: %@",
        error);

#if !TARGET_IPHONE_SIMULATOR  // don't shot this error in the simulator

    NSString * title =
        NSLocalizedString(@"notification.registration.failed.alert.title", @"");
    NSString * message = error.localizedDescription;
    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];

#endif

}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"The application received a server notification while running: "
        "%@.", userInfo);
}

- (NSDictionary *)deviceRegistrationArgsForCredentials:(NSArray *)allCredentials
{
    NSMutableDictionary * args =
        [NSMutableDictionary dictionaryWithCapacity:allCredentials.count];
    for (NSInteger i = 0, count = allCredentials.count; i < count; ++i) {
        TwitterCredentials * c = [allCredentials objectAtIndex:i];

        NSString * usernameKey = [NSString stringWithFormat:@"username%d", i];
        NSString * passwordKey = [NSString stringWithFormat:@"password%d", i];

        [args setObject:c.username forKey:usernameKey];
        [args setObject:c.password forKey:passwordKey];
    }

    return args;
}

#pragma mark DeviceRegistrarDelegate implementation

- (void)registeredDeviceWithToken:(NSData *)token
{
    NSLog(@"Successfully registered the device for push notifications: '%@'.",
        token);

    deviceNeedsRegistration = NO;
}

- (void)failedToRegisterDeviceWithToken:(NSData *)token error:(NSError *)error
{
    NSLog(@"Failed to register device for push notifications: '%@', error: "
        "'%@'.", token, error);

    NSString * title =
        NSLocalizedString(@"notification.registration.failed.alert.title", @"");
    NSString * message =
        [NSString stringWithFormat:@"%@\n\n%@",
        error.localizedDescription,
        NSLocalizedString(@"notification.registration.failed.alert.message",
            @"")];

    UIAlertView * alert = [UIAlertView simpleAlertViewWithTitle:title
                                                        message:message];
    [alert show];
}

#pragma mark Push notification helpers

- (void)registerDeviceForPushNotifications
{
    UIRemoteNotificationType notificationTypes =
    (UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeSound |
     UIRemoteNotificationTypeAlert);

    [[UIApplication sharedApplication]
        registerForRemoteNotificationTypes:notificationTypes];
}

#pragma mark Application notifications

- (void)credentialsActivated:(TwitterCredentials *)activatedCredentials
{
    if (!self.activeCredentials)  // first account has been created
        activeCredentials =
            [[ActiveTwitterCredentials
            createInstance:[self managedObjectContext]] retain];

    self.activeCredentials.credentials = activatedCredentials;
    [self saveContext];
}

- (void)credentialSetChanged:(TwitterCredentials *)changedCredentials
                       added:(NSNumber *)added
{
    if ([added integerValue]) {
        if (self.credentials.count == 0)  // first credentials -- active them
            [self broadcastActivatedCredentialsChanged:changedCredentials];
        [self.credentials addObject:changedCredentials];
    } else {
        [TwitterCredentials
            deletePasswordForUsername:changedCredentials.username];
        [self.credentials removeObject:changedCredentials];
    }

    deviceNeedsRegistration = YES;
    [self registerDeviceForPushNotifications];

    NSLog(@"Active credentials: '%@'.", self.activeCredentials.credentials);
    [self saveContext];
}

- (void)broadcastActivatedCredentialsChanged:(TwitterCredentials *)tc
{
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        tc, @"credentials", nil];
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"ActiveCredentialsChangedNotification"
                      object:self
                    userInfo:userInfo];
}

#pragma mark Persistence helpers

- (BOOL)saveContext
{
    NSError * error;
    if ([managedObjectContext hasChanges] &&
        ![managedObjectContext save:&error]) {
        // Handle error
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        return NO;
    }

    return YES;
}

- (void)setUIStateFromPersistence
{
    UIStatePersistenceStore * uiStatePersistenceStore =
        [[[UIStatePersistenceStore alloc] init] autorelease];
    UIState * uiState = [uiStatePersistenceStore load];
    tabBarController.selectedIndex = uiState.selectedTab;
    UISegmentedControl * control = (UISegmentedControl *)
        homeNetAwareViewController.navigationItem.titleView;
    control.selectedSegmentIndex = uiState.selectedTimelineFeed;
}

- (void)persistUIState
{
    UIStatePersistenceStore * uiStatePersistenceStore =
        [[[UIStatePersistenceStore alloc] init] autorelease];
    UIState * uiState = [[[UIState alloc] init] autorelease];
    uiState.selectedTab = tabBarController.selectedIndex;
    UISegmentedControl * control = (UISegmentedControl *)
        homeNetAwareViewController.navigationItem.titleView;
    uiState.selectedTimelineFeed = control.selectedSegmentIndex;
    [uiStatePersistenceStore save:uiState];
}

#pragma mark Accessors

- (DeviceRegistrar *)registrar
{
    if (!registrar) {
        NSString * url =
            [[InfoPlistConfigReader reader]
            valueForKey:@"DeviceRegistrationUrl"];
        registrar = [[DeviceRegistrar alloc] initWithUrl:url];
        registrar.delegate = self;
    }

    return registrar;
}

- (LogInDisplayMgr *)logInDisplayMgr
{
    if (!logInDisplayMgr)
        logInDisplayMgr =
            [[LogInDisplayMgr alloc]
            initWithRootViewController:tabBarController
                  managedObjectContext:[self managedObjectContext]];

    return logInDisplayMgr;
}

- (NSMutableArray *)credentials
{
    if (!credentials) {
        NSFetchRequest * request = [[NSFetchRequest alloc] init];
        NSEntityDescription * entity =
            [NSEntityDescription entityForName:@"TwitterCredentials"
                        inManagedObjectContext:[self managedObjectContext]];
        [request setEntity:entity];

        NSSortDescriptor * sortDescriptor =
            [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
        NSArray *sortDescriptors =
            [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [request setSortDescriptors:sortDescriptors];

        [sortDescriptors release];
        [sortDescriptor release];

        NSError * error;
        credentials =
            [[managedObjectContext executeFetchRequest:request
                                                 error:&error] mutableCopy];
        NSAssert(credentials, @"Failed to load any credentials.");

        [request release];
    }

    return credentials;
}

- (ActiveTwitterCredentials *)activeCredentials
{
    if (!activeCredentials)
        activeCredentials =
            [[ActiveTwitterCredentials
            findFirst:[self managedObjectContext]] retain];

    return activeCredentials;
}

- (ComposeTweetDisplayMgr *)composeTweetDisplayMgr
{
    if (!composeTweetDisplayMgr) {
        TwitterService * service =
            [[TwitterService alloc]
            initWithTwitterCredentials:nil context:[self managedObjectContext]];
        composeTweetDisplayMgr =
            [[ComposeTweetDisplayMgr alloc]
            initWithRootViewController:self.tabBarController
                        twitterService:service];
        [service release];

        composeTweetDisplayMgr.delegate = self;
    }

    return composeTweetDisplayMgr;
}

- (UIBarButtonItem *)sendingTweetProgressView
{
    if (!sendingTweetProgressView) {
        UIActivityIndicatorView * view =
            [[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

        sendingTweetProgressView =
            [[UIBarButtonItem alloc] initWithCustomView:view];

        [view startAnimating];

        [view release];
    }

    return sendingTweetProgressView;
}

- (UIBarButtonItem *)newTweetButtonItem
{
    UIBarButtonItem * button =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                             target:self
                             action:@selector(composeTweet:)];

    return [button autorelease];
}

@end
