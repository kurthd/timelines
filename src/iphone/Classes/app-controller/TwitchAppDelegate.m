//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitchAppDelegate.h"
#import "DeviceRegistrar.h"
#import "LogInDisplayMgr.h"
#import "CredentialsUpdatePublisher.h"
#import "TwitterCredentials.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "InfoPlistConfigReader.h"
#import "TwitterService.h"
#import "ComposeTweetDisplayMgr.h"
#import "PersonalFeedSelectionMgr.h"
#import "UserTimelineDataSource.h"

@interface TwitchAppDelegate ()

@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;
@property (nonatomic, retain) ComposeTweetDisplayMgr * composeTweetDisplayMgr;
@property (nonatomic, retain) DeviceRegistrar * registrar;
@property (nonatomic, retain) NSMutableArray * credentials;

- (UIBarButtonItem *)sendingTweetProgressView;

- (void)initHomeTab;
- (void)initProfileTab;

- (UIBarButtonItem *)newTweetButtonItem;

@end

@implementation TwitchAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize logInDisplayMgr;
@synthesize composeTweetDisplayMgr;
@synthesize registrar;
@synthesize credentials;

- (void)dealloc
{
    [tabBarController release];
    [window release];

    [registrar release];
    [logInDisplayMgr release];

    [credentials release];
    [unregisteredCredentials release];

    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];

    [homeNetAwareViewController release];
    [profileNetAwareViewController release];
    [trendsNetAwareViewController release];
    [searchNetAwareViewController release];
    [accountsNetAwareViewController release];

    [timelineDisplayMgrFactory release];
    [timelineDisplayMgr release];
    [profileTimelineDisplayMgr release];

    [composeTweetDisplayMgr release];

    [sendingTweetProgressView release];

    [super dealloc];
}

#pragma mark UIApplicationDelegate implementation

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    // TEMPORARY
    unregisteredCredentials = [[NSMutableArray alloc] init];

    // reset the unread message count to 0
    application.applicationIconBadgeNumber = 0;

    registeredForPushNotifications = NO;

    /*
    UIRemoteNotificationType notificationTypes =
        (UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert);

    [[UIApplication sharedApplication]
        registerForRemoteNotificationTypes:notificationTypes];
     */

    credentialsUpdatePublisher =
        [[CredentialsUpdatePublisher alloc]
        initWithListener:self action:@selector(credentialsChanged:)];

    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:tabBarController.view];

    timelineDisplayMgrFactory =
        [[TimelineDisplayMgrFactory alloc]
        initWithContext:[self managedObjectContext]];
    [self initHomeTab];
    [self initProfileTab];

    if (self.credentials.count == 0)
        [self.logInDisplayMgr logIn];
    else {
        TwitterCredentials * c = [self.credentials objectAtIndex:0];
        [timelineDisplayMgr setCredentials:c];
        [profileTimelineDisplayMgr setCredentials:c];
        [self.composeTweetDisplayMgr setCredentials:c];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSError *error;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] &&
            ![managedObjectContext save:&error]) {
			// Handle error
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
        }
    }
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
    timelineDisplayMgr =
        [[timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        homeNetAwareViewController]
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
    profileTimelineDisplayMgr =
        [[timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        profileNetAwareViewController]
        retain];
    profileTimelineDisplayMgr.displayAsConversation = NO;
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
    [[CredentialsUpdatePublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];

    twitterService.delegate = dataSource;
    [profileTimelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO];
    dataSource.delegate = profileTimelineDisplayMgr;
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
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    NSLog(@"Device token: %@.", devToken);

    for (TwitterCredentials * c in unregisteredCredentials) {
        NSDictionary * args = [NSDictionary dictionaryWithObjectsAndKeys:
            c.username, @"username",
            c.password, @"password",
            nil];
        [self.registrar sendProviderDeviceToken:devToken args:args];
    }

    [credentials addObjectsFromArray:unregisteredCredentials];
    [unregisteredCredentials removeAllObjects];

    //const void * devTokenBytes = [devToken bytes];
    //self.registered = YES;
    //[self sendProviderDeviceToken:devTokenBytes]; // custom method
}
 
- (void)application:(UIApplication *)app
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)err
{
    NSLog(@"Error in registration. Error: %@", err);
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"The application received a server notification while running: "
        "%@.", userInfo);
}

#pragma mark DeviceRegistrarDelegate implementation

- (void)registeredDeviceWithToken:(NSData *)token
{
    NSLog(@"Successfully registered the device for push notifications: '%@'.",
        token);
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

- (void)registerForPushNotifications
{
    UIRemoteNotificationType notificationTypes =
    (UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeSound |
     UIRemoteNotificationTypeAlert);
    
    [[UIApplication sharedApplication]
        registerForRemoteNotificationTypes:notificationTypes];
}

#pragma mark Application notifications

- (void)credentialsChanged:(TwitterCredentials *)newCredentials
{
    [unregisteredCredentials addObject:newCredentials];
    [self registerForPushNotifications];
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
            [[NSSortDescriptor alloc] initWithKey:@"username" ascending:NO];
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
