//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitchAppDelegate.h"
#import "DeviceRegistrar.h"
#import "LogInDisplayMgr.h"
#import "CredentialsActivatedPublisher.h"
#import "CredentialsSetChangedPublisher.h"
#import "TwitterCredentials.h"
#import "TwitterCredentials+KeychainAdditions.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "InfoPlistConfigReader.h"
#import "TwitterService.h"
#import "TwitPicImageSender.h"
#import "ComposeTweetDisplayMgr.h"
#import "UserTimelineDataSource.h"
#import "TrendsDisplayMgr.h"
#import "SearchBarDisplayMgr.h"
#import "AccountsDisplayMgr.h"
#import "ActiveTwitterCredentials.h"
#import "UIStatePersistenceStore.h"
#import "UIState.h"
#import "UserTweet.h"
#import "Mention.h"
#import "DirectMessage.h"
#import "NSObject+RuntimeAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "TweetInfo.h"  // so they can be fed to the personalFeedSelectionMgr

@interface TwitchAppDelegate ()

@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;
@property (nonatomic, retain) ComposeTweetDisplayMgr * composeTweetDisplayMgr;
@property (nonatomic, retain) DeviceRegistrar * registrar;
@property (nonatomic, retain) NSMutableArray * credentials;
@property (nonatomic, retain) ActiveTwitterCredentials *
    activeCredentials;

- (void)initHomeTab;
- (void)initProfileTab;
- (void)initTrendsTab;
- (void)initAccountsTab;
- (void)initSearchTab;

- (UIBarButtonItem *)newTweetButtonItem;
- (UIBarButtonItem *)sendingTweetProgressView;

- (void)broadcastActivatedCredentialsChanged:(TwitterCredentials *)tc;

- (void)registerDeviceForPushNotifications;
- (NSDictionary *)deviceRegistrationArgsForCredentials:(NSArray *)credentials;

- (BOOL)saveContext;
- (void)prunePersistenceStore;
- (void)loadHomeViewWithCachedData:(TwitterCredentials *)account;
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
    [personalFeedSelectionMgr release];

    [composeTweetDisplayMgr release];

    [trendsDisplayMgr release];
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
    [self initTrendsTab];
    [self initSearchTab];
    [self initAccountsTab];

    if (self.credentials.count == 0) {
        NSAssert1(!self.activeCredentials.credentials, @"No credentials exist, "
            "but an active account has been set: '%@'.",
            self.activeCredentials.credentials);
        self.logInDisplayMgr.allowsCancel = NO;
        [self.logInDisplayMgr logIn:NO];
    } else {
        NSAssert(self.activeCredentials.credentials, @"Credentials exist, but "
            "no active account has been set.");

        TwitterCredentials * c = self.activeCredentials.credentials;
        NSLog(@"Active credentials: '%@'.", c);

        [timelineDisplayMgr setCredentials:c];
        [profileTimelineDisplayMgr setCredentials:c];
        [trendsDisplayMgr setCredentials:c];
        [searchBarDisplayMgr setCredentials:c];
        [self.composeTweetDisplayMgr setCredentials:c];

        [self loadHomeViewWithCachedData:c];
    }

    [self setUIStateFromPersistence];
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

    if (managedObjectContext != nil) {
        [self prunePersistenceStore];
        if (![self saveContext])
            exit(-1);  // fail
    }
    
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
    BOOL displayImmediately =
        control.selectedSegmentIndex == 0 ||
        control.selectedSegmentIndex == 1;
    [timelineDisplayMgr addTweet:tweet displayImmediately:displayImmediately];

    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self newTweetButtonItem]
                     animated:YES];
}

- (void)userFailedToSendTweet:(NSString *)tweet
{
    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self newTweetButtonItem]
                     animated:YES];

    [self.composeTweetDisplayMgr composeTweetWithText:tweet];
}

- (void)userIsReplyingToTweet:(NSString *)origTweetId
                     fromUser:(NSString *)origUsername
                     withText:(NSString *)text
{
}

- (void)userDidReplyToTweet:(NSString *)origTweetId
                   fromUser:(NSString *)origUsername
                  withTweet:(Tweet *)reply
{
    UISegmentedControl * control = (UISegmentedControl *)
        homeNetAwareViewController.navigationItem.titleView;
    BOOL displayImmediately =
        control.selectedSegmentIndex == 0 ||
        control.selectedSegmentIndex == 1;
    [timelineDisplayMgr addTweet:reply displayImmediately:displayImmediately];
}

- (void)userFailedToReplyToTweet:(NSString *)origTweetId
                        fromUser:(NSString *)origUsername
                        withText:(NSString *)text
{
    [self.composeTweetDisplayMgr composeReplyToTweet:origTweetId
                                            fromUser:origUsername
                                            withText:text];
}

- (void)userIsSendingDirectMessage:(NSString *)dm to:(NSString *)username
{
}

- (void)userDidSendDirectMessage:(DirectMessage *)dm
{
    // should the dm be added to the timeline display mgr?
}

- (void)userFailedToSendDirectMessage:(NSString *)dm to:(NSString *)username
{
    [self.composeTweetDisplayMgr composeDirectMessageTo:username withText:dm];
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
        managedObjectContext:[self managedObjectContext]
        composeTweetDisplayMgr:self.composeTweetDisplayMgr]
        retain];
    timelineDisplayMgr.displayAsConversation = YES;
    UIBarButtonItem * refreshButton =
        homeNetAwareViewController.navigationItem.leftBarButtonItem;
    refreshButton.target = timelineDisplayMgr;
    refreshButton.action = @selector(refreshWithLatest);

    TwitterService * allService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:[self managedObjectContext]]
        autorelease];

    TwitterService * mentionsService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:[self managedObjectContext]]
        autorelease];

    TwitterService * messagesService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:[self managedObjectContext]]
        autorelease];

    personalFeedSelectionMgr =
        [[PersonalFeedSelectionMgr alloc]
        initWithTimelineDisplayMgr:timelineDisplayMgr allService:allService
        mentionsService:mentionsService messagesService:messagesService];
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
        managedObjectContext:[self managedObjectContext]
        composeTweetDisplayMgr:self.composeTweetDisplayMgr]
        retain];
    profileTimelineDisplayMgr.displayAsConversation = NO;
    profileTimelineDisplayMgr.setUserToFirstTweeter = YES;
    UIBarButtonItem * refreshButton =
        profileNetAwareViewController.navigationItem.leftBarButtonItem;
    refreshButton.target = profileTimelineDisplayMgr;
    refreshButton.action = @selector(refreshWithLatest);

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

- (void)initTrendsTab
{
    TwitterService * trendsService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:[self managedObjectContext]]
        autorelease];

    NetworkAwareViewController * navc =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    TimelineDisplayMgr * displayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:navc
        title:@"Trends"  // set programmatically later
        managedObjectContext:[self managedObjectContext]
        composeTweetDisplayMgr:self.composeTweetDisplayMgr];
    navc.delegate = displayMgr;

    trendsDisplayMgr =
        [[TrendsDisplayMgr alloc]
        initWithTwitterService:trendsService
            netAwareController:trendsNetAwareViewController
            timelineDisplayMgr:displayMgr];
}

- (void)initSearchTab
{
    TwitterService * searchService =
        [[[TwitterService alloc]
        initWithTwitterCredentials:nil
                           context:[self managedObjectContext]] autorelease];

    TimelineDisplayMgr * displayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        searchNetAwareViewController
        title:@"Search"  // set programmatically later
        managedObjectContext:[self managedObjectContext]
        composeTweetDisplayMgr:self.composeTweetDisplayMgr];
    searchNetAwareViewController.delegate = displayMgr;

    searchBarDisplayMgr =
        [[SearchBarDisplayMgr alloc]
        initWithTwitterService:searchService
            netAwareController:searchNetAwareViewController
            timelineDisplayMgr:displayMgr];
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
            [self loadHomeViewWithCachedData:activeAccount];
        }
    }

    if (viewController == searchNetAwareViewController.navigationController)
        [searchBarDisplayMgr searchBarViewWillAppear:YES];

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
    NSLog(@"Application did fail to register for push notifications. Error: %@",
        error);

#if !TARGET_IPHONE_SIMULATOR  // don't show this error in the simulator

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

- (void)prunePersistenceStore
{
    //
    // we only want to keep UserTweets, Mentions, DirectMessages, and the User
    // instances they point to
    //

    // important to access the context via the accessor
    NSManagedObjectContext * context = [self managedObjectContext];

    NSArray * allTweets = [Tweet findAll:context];
    NSMutableSet * sparedUsers = [NSMutableSet set];

    // delete all 'un-owned' tweets -- everything that's not in the user's
    // timeline, a mention, or a dm
    for (Tweet * tweet in allTweets) {
        BOOL isOwned =
            [tweet isKindOfClass:[UserTweet class]] ||
            [tweet isKindOfClass:[Mention class]];
        if (!isOwned) {
            NSLog(@"Deleting tweet: '%@': '%@'.", tweet.user.name, tweet.text);
            [context deleteObject:tweet];
        }
    }

    // only keep the last n tweets, mentions, and dms for each account
    static const NSUInteger NUM_TO_KEEP = 20;

    NSMutableDictionary * living =
        [NSMutableDictionary dictionaryWithCapacity:self.credentials.count];
    NSMutableArray * hitList =
        [NSMutableArray arrayWithCapacity:allTweets.count];

    // won't include deleted tweets
    allTweets =
        [[Tweet findAll:context] sortedArrayUsingSelector:@selector(compare:)];

    for (NSInteger i = 0, count = allTweets.count; i < count; ++i) {
        Tweet * t = [allTweets objectAtIndex:i];
        NSString * key = nil;
        TwitterCredentials * c = nil;

        if ([t isKindOfClass:[UserTweet class]]) {
            c = [((UserTweet *) t) credentials];
            key = @"user-tweet";
        } else if ([t isKindOfClass:[Mention class]]) {
            c = [((Mention *) t) credentials];
            key = @"mention";
        } else
            NSLog(@"Still have a %@ tweet type!", [t class]);

        if (c) {
            NSMutableDictionary * perCredentials =
                [living objectForKey:c.username];
            if (!perCredentials) {
                perCredentials = [NSMutableDictionary dictionary];
                [living setObject:perCredentials forKey:c.username];
            }

            NSMutableArray * perTweetType = [perCredentials objectForKey:key];
            if (!perTweetType) {
                perTweetType = [NSMutableArray array];
                [perCredentials setObject:perTweetType forKey:key];
            }

            // finally, insert the tweet if it should be saved
            if (perTweetType.count < NUM_TO_KEEP) {
                [perTweetType addObject:t];  // it lives
                [sparedUsers addObject:t.user];
                NSLog(@"Saved tweets for '%@': '%d'.", c.username, perTweetType.count);
            } else
                [hitList addObject:t];  // it dies
        }
    }

    // delete all unneeded tweets
    for (Tweet * tweet in hitList)
        [context deleteObject:tweet];

    // now do a similar routine for dms

    // all users involved in a direct message must be spared
    [living removeAllObjects];
    [hitList removeAllObjects];

    NSArray * allDms = [DirectMessage findAll:context];
    for (DirectMessage * dm in allDms) {
        TwitterCredentials * c = dm.credentials;

        NSMutableArray * perCredentials = [living objectForKey:c.username];
        if (!perCredentials) {
            perCredentials = [NSMutableArray array];
            [living setObject:perCredentials forKey:c.username];
        }

        if (perCredentials.count < NUM_TO_KEEP) {
            [perCredentials addObject:dm];
            [sparedUsers addObject:dm.recipient];
            [sparedUsers addObject:dm.sender];
        } else
            [context deleteObject:dm];

    }

    // delete all unneeeded users
    NSArray * potentialVictims = [User findAll:context];
    for (User * user in potentialVictims)
        if (![sparedUsers containsObject:user]) {
            NSLog(@"Deleting user: '%@'.", user.username);
            [context deleteObject:user];
        }
}

- (void)loadHomeViewWithCachedData:(TwitterCredentials *)account
{
    // important to access the context via the accessor
    NSManagedObjectContext * context = [self managedObjectContext];

    NSPredicate * predicate = 
        [NSPredicate predicateWithFormat:@"credentials.username == %@",
        account.username];

    NSArray * allTweets = [UserTweet findAll:predicate context:context];
    NSArray * allMentions = [Mention findAll:predicate context:context];
    NSArray * allDms = [DirectMessage findAll:predicate context:context];

    NSLog(@"Loaded tweets: '%@'.", allTweets);
    NSLog(@"Loaded mentions: '%@'.", allMentions);
    NSLog(@"Loaded direct messages: '%@'.", allDms);

    // convert them all to dictionaries
    NSMutableDictionary * tweets =
        [NSMutableDictionary dictionaryWithCapacity:allTweets.count];
    NSMutableDictionary * mentions =
        [NSMutableDictionary dictionaryWithCapacity:allMentions.count];
    NSMutableDictionary * dms =
        [NSMutableDictionary dictionaryWithCapacity:allDms.count];
    for (UserTweet * tweet in allTweets)
        [tweets setObject:[TweetInfo createFromTweet:tweet]
                   forKey:tweet.identifier];
    for (Mention * mention in allMentions)
        [mentions setObject:[TweetInfo createFromTweet:mention]
                     forKey:mention.identifier];
    for (DirectMessage * dm in allDms)
        [dms setObject:[TweetInfo createFromDirectMessage:dm]
                forKey:dm.identifier];

    
    personalFeedSelectionMgr.allTimelineTweets = tweets;
    personalFeedSelectionMgr.mentionsTimelineTweets = mentions;
    personalFeedSelectionMgr.messagesTimelineTweets = dms;
}

- (void)setUIStateFromPersistence
{
    UIStatePersistenceStore * uiStatePersistenceStore =
        [[[UIStatePersistenceStore alloc] init] autorelease];
    UIState * uiState = [uiStatePersistenceStore load];
    tabBarController.selectedIndex = uiState.selectedTab;
    UISegmentedControl * control = (UISegmentedControl *)
        homeNetAwareViewController.navigationItem.titleView;
    NSLog(@"Setting segmented control index");
    control.selectedSegmentIndex = uiState.selectedTimelineFeed;
    
    // HACK: Force tab selected to be called when selected index is zero, which
    // is the default
    if (uiState.selectedTimelineFeed == 0)
        [personalFeedSelectionMgr tabSelected:control];

    // HACK: Let the search view do some custom drawing when it appears
    if (uiState.selectedTab == 3)
        [searchBarDisplayMgr searchBarViewWillAppear:NO];
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
            valueForKey:@"DeviceRegistrationDomain"];
        registrar = [[DeviceRegistrar alloc] initWithDomain:url];
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

        NSString * twitPicUrl =
            [[InfoPlistConfigReader reader] valueForKey:@"TwitPicPostUrl"];
        TwitPicImageSender * imageSender =
            [[TwitPicImageSender alloc] initWithUrl:twitPicUrl];

        composeTweetDisplayMgr =
            [[ComposeTweetDisplayMgr alloc]
            initWithRootViewController:self.tabBarController
                        twitterService:service
                           imageSender:imageSender];
        [service release];
        [imageSender release];

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
