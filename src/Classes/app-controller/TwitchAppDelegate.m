//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitchAppDelegate.h"
#import "DeviceRegistrar.h"
#import "XauthLogInDisplayMgr.h"
#import "CredentialsActivatedPublisher.h"
#import "CredentialsSetChangedPublisher.h"
#import "AccountSettingsChangedPublisher.h"
#import "TwitterCredentials.h"
#import "TwitterCredentials+KeychainAdditions.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "InfoPlistConfigReader.h"
#import "TwitterService.h"
#import "TwitPicPhotoService.h"
#import "ComposeTweetDisplayMgr.h"
#import "UserTimelineDataSource.h"
#import "AccountsDisplayMgr.h"
#import "ActiveTwitterCredentials.h"
#import "UIStatePersistenceStore.h"
#import "UserTweet.h"
#import "Mention.h"
#import "NSObject+RuntimeAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "ArbUserTimelineDataSource.h"
#import "UserListDisplayMgrFactory.h"
#import "TwitchWebBrowserDisplayMgr.h"
#import "PhotoBrowserDisplayMgr.h"
#import "SettingsReader.h"
#import "UIApplication+ConfigurationAdditions.h"
#import "NSArray+IterationAdditions.h"
#import "TwitbitShared.h"
#import "ErrorState.h"
#import "UserTwitterList.h"
#import "ContactCachePersistenceStore.h"
#import "Tweet+CoreDataAdditions.h"
#import "DirectMessage+CoreDataAdditions.h"
#import "PushNotificationMessage.h"
#import "ManagedObjectContextPruner.h"
#import "AnalyticsService.h"

@interface TwitchAppDelegate ()

@property (nonatomic, retain) XauthLogInDisplayMgr * logInDisplayMgr;
@property (nonatomic, retain) ComposeTweetDisplayMgr * composeTweetDisplayMgr;
@property (nonatomic, retain) DeviceRegistrar * registrar;
@property (nonatomic, retain) NSMutableArray * credentials;
@property (nonatomic, retain) ActiveTwitterCredentials *
    activeCredentials;

@property (nonatomic, retain) InstapaperService * instapaperService;
@property (nonatomic, copy) NSString * savingInstapaperUrl;
@property (nonatomic, retain) InstapaperLogInDisplayMgr *
    instapaperLogInDisplayMgr;

@property (nonatomic, retain) UIAcceleration* lastAcceleration;

@property (nonatomic, retain) AnalyticsService * analyticsService;

- (void)initHomeTab;
- (void)initMentionsTab;
- (void)initFavoritesTab;
- (void)initRetweetsTab;
- (void)initAccountsView;
- (void)initListsMgr;

- (void)initAnalytics;
- (void)terminateAnalytics;

- (UIBarButtonItem *)newTweetButtonItem;
- (UIBarButtonItem *)homeSendingTweetProgressView;
- (UIBarButtonItem *)mentionsSendingTweetProgressView;

- (void)broadcastActivatedCredentialsChanged:(TwitterCredentials *)tc;

- (NSDictionary *)deviceRegistrationArgsForCredentials:(NSArray *)credentials;

- (BOOL)saveContext;
- (void)prunePersistentStore;
- (void)loadHomeViewWithCachedData:(TwitterCredentials *)account;
- (void)loadMentionsViewWithCachedData:(TwitterCredentials *)account;
- (void)setUIStateFromPersistenceAndNotification:(NSDictionary *)notification;
- (void)updateUIStateWithNotification:(NSDictionary *)notification
    mentionTabLocation:(NSInteger)mentionTabLocation
    messageTabLocation:(NSInteger)messageTabLocation;
- (void)persistUIState;

- (void)finishInitializationWithTimeInsensitiveOperations;

- (void)processUserAccountSelection;

- (void)activateAccountWithName:(NSString *)accountName;
- (void)processAccountChange:(TwitterCredentials *)activeAccount;

- (void)loadContactCache;

- (void)showTimelineAnimated:(BOOL)animated;
- (void)showMentionsAnimated:(BOOL)animated;
- (void)showFavoritesAnimated:(BOOL)animated;
- (void)showRetweetsAnimated:(BOOL)animated;

+ (NSInteger)mentionsTabBarItemTag;

@end

enum {
    kOriginalTabOrderTimeline,
    kOriginalTabOrderMentions,
    kOriginalTabOrderMessages,
    kOriginalTabOrderLists,
    kOriginalTabOrderSearch,
    kOriginalTabOrderPeople,
    kOriginalTabOrderProfile,
    kOriginalTabOrderTrends
} OriginalTabOrder;

@implementation TwitchAppDelegate

@synthesize window;
@synthesize logInDisplayMgr;
@synthesize composeTweetDisplayMgr;
@synthesize registrar;
@synthesize credentials;
@synthesize activeCredentials;
@synthesize instapaperService;
@synthesize savingInstapaperUrl;
@synthesize instapaperLogInDisplayMgr;
@synthesize lastAcceleration;
@synthesize analyticsService;

- (void)dealloc
{
    [window release];

    [registrar release];
    [logInDisplayMgr release];

    [credentials release];
    [activeCredentials release];

    [credentialsActivatedPublisher release];
    [credentialsSetChangedPublisher release];
    [accountSettingsChangedPublisher release];
    
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [managedObjectContextPruner release];
    
    [mainNavController release];
    [homeNetAwareViewController release];
    
    [contactCache release];
    [contactMgr release];
    
    [accountsViewController release];
    
    [timelineDisplayMgrFactory release];
    [timelineDisplayMgr release];
    [mentionsAcctMgr release];
    [mentionDisplayMgr release];
    [favoritesDisplayMgr release];
    [retweetsDisplayMgr release];
    [listsDisplayMgr release];
    [composeTweetDisplayMgr release];

    [accountsDisplayMgr release];

    [homeSendingTweetProgressView release];
    [mentionsSendingTweetProgressView release];

    [instapaperService release];
    [savingInstapaperUrl release];
    [instapaperLogInDisplayMgr release];

    [uiState release];

    [lastAcceleration release];

    [analyticsService release];

    [super dealloc];
}

#pragma mark UIApplicationDelegate implementation

- (void)processApplicationLaunch:(UIApplication *)application
          withRemoteNotification:(NSDictionary *)notification
{
    NSLog(@"Device ID: %@", [UIDevice currentDevice].uniqueIdentifier);
    NSLog(@"Application did finish launching; initializing");

    credentialsActivatedPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:self action:@selector(credentialsActivated:)];
    credentialsSetChangedPublisher =
        [[CredentialsSetChangedPublisher alloc]
         initWithListener:self action:@selector(credentialsSetChanged:added:)];
    accountSettingsChangedPublisher =
        [[AccountSettingsChangedPublisher alloc]
        initWithListener:self
                  action:@selector(accountSettingsChanged:forAccount:)];

    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:mainNavController.view];

    contactCache = [[ContactCache alloc] init];
    contactMgr =
        [[ContactMgr alloc]
        initWithTabBarController:mainNavController
        contactCacheSetter:contactCache];

    timelineDisplayMgrFactory =
        [[TimelineDisplayMgrFactory alloc]
        initWithContext:[self managedObjectContext]
        findPeopleBookmarkMgr:nil contactCache:contactCache
        contactMgr:contactMgr];

    [self initAccountsView];

    if (self.credentials.count == 0) {
        NSAssert1(!self.activeCredentials.credentials, @"No credentials exist, "
            "but an active account has been set: '%@'.",
            self.activeCredentials.credentials);
        self.logInDisplayMgr.allowsCancel = NO;
        [self.logInDisplayMgr logIn:NO];
    } else {
        if (!self.activeCredentials.credentials) {
            NSLog(@"Recovering credentials after crash");
            // for some reason the active credentials weren't set correctly
            // last time, probably due to a crash while the app was in use;
            // prevent another crash and set the active credentials here
            self.activeCredentials.credentials =
                [self.credentials objectAtIndex:0];
        }
        
        TwitterCredentials * c = self.activeCredentials.credentials;
        NSLog(@"Active credentials on startup: '%@'.", c.username);
        [self.composeTweetDisplayMgr setCredentials:c];
        
        timelineSelectionController.navigationItem.title = c.username;
        
        [mainNavController pushViewController:timelineSelectionController
            animated:YES];
        
        [self setUIStateFromPersistenceAndNotification:notification];
    }
    
    [self performSelector:
        @selector(finishInitializationWithTimeInsensitiveOperations)
        withObject:nil
        afterDelay:0.6];
    
    [self initListsMgr];
    
    NSLog(@"Application did finish initializing");
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [self processApplicationLaunch:application
            withRemoteNotification:nil];
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)options
{
    NSString * crazyLongKey = UIApplicationLaunchOptionsRemoteNotificationKey;
    NSDictionary * remoteNotification = [options objectForKey:crazyLongKey];

    NSString * urlKey = UIApplicationLaunchOptionsURLKey;
    NSURL * url = [options objectForKey:urlKey];
    NSString * username = nil;
    NSString * messageText = nil;
    if (url) {
        NSString * urlString = [url absoluteString];
        NSArray * urlArray = [urlString componentsSeparatedByString:@"//"];
        NSString * domain =
            [urlArray count] > 1 ? [urlArray objectAtIndex:1] : nil;
        if (domain) {
            NSArray * domainArray =
                [domain componentsSeparatedByString:@"action.compose"];
            if (domainArray.count == 1) { // interpret as username
                username = domain;
                if (username)
                    showHomeTab = YES;
            } else { // interpret as action
                NSArray * domainArgArray =
                    [domain componentsSeparatedByString:@"?body="];
                if (domainArgArray.count == 1)
                    messageText = @"";
                else {
                    NSString * encodedBody = [domainArgArray objectAtIndex:1];
                    messageText =
                        [encodedBody
                        stringByReplacingPercentEscapesUsingEncoding:
                        NSASCIIStringEncoding];
                }
            }
        }
    }
    
    [self processApplicationLaunch:application
            withRemoteNotification:remoteNotification];
    
    if (username) {
        [self loadContactCache];
        [timelineDisplayMgr showUserInfoForUsername:username];
    } else if (messageText)
        [self.composeTweetDisplayMgr composeTweetWithText:messageText
            animated:NO];
    
    return YES;
}

- (void)finishInitializationWithTimeInsensitiveOperations
{
    TwitchWebBrowserDisplayMgr * webDispMgr =
        [TwitchWebBrowserDisplayMgr instance];
    if (!webDispMgr.delegate) {
        webDispMgr.composeTweetDisplayMgr = self.composeTweetDisplayMgr;
        webDispMgr.hostViewController = mainNavController;
        webDispMgr.delegate = self;
    }

    PhotoBrowserDisplayMgr * photoBrowserDispMgr =
        [PhotoBrowserDisplayMgr instance];
    photoBrowserDispMgr.composeTweetDisplayMgr = self.composeTweetDisplayMgr;
    photoBrowserDispMgr.hostViewController = mainNavController;

    if (!mentionDisplayMgr)
        [self initMentionsTab];
    if (!timelineDisplayMgr)
        [self initHomeTab];

    if ([SettingsReader displayTheme] == kDisplayThemeDark)
        window.backgroundColor = [UIColor blackColor];

    [self loadContactCache];

    [UIAccelerometer sharedAccelerometer].delegate = self;

    [self initAnalytics];
}

- (void)loadContactCache
{
    if (!loadedContactCache) {
        ContactCachePersistenceStore * contactCachePersistenceStore =
            [[[ContactCachePersistenceStore alloc]
            initWithContactCache:contactCache] autorelease];
        [contactCachePersistenceStore load];
        loadedContactCache = YES;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self persistUIState];

    if (managedObjectContext != nil) {
        [self prunePersistentStore];
        if (![self saveContext]) {
            NSLog(@"Failed to save state on application shutdown.");
            exit(-1);
        }
    }

    // Note that the Pinch documentation suggestions calling this method
    // last, as the iPhone OS has a watchdog that terminates processes if
    // they don't terminate in an unspecified amount of time. Do all
    // application-critical stuff first. If analytics communication fails,
    // the data will be sent next time the application runs on startup.
    [self terminateAnalytics];
}

#pragma mark Composing tweets

- (IBAction)composeTweet:(id)sender
{
    [self.composeTweetDisplayMgr composeTweetAnimated:YES];
}

#pragma mark Location management

- (void)setLocation:(CLLocation *)location
{
    [self.analyticsService setLocation:location];
}

#pragma mark ComposeTweetDisplayMgrDelegate implementation

- (void)userDidCancelComposingTweet
{}

- (void)userIsSendingTweet:(NSString *)tweet
{
    NSLog(@"User is sending tweet...");
    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self homeSendingTweetProgressView]
        animated:YES];
}

- (void)userDidSendTweet:(Tweet *)tweet
{
    NSLog(@"User did send tweet...");
    [timelineDisplayMgr addTweet:tweet];

    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self newTweetButtonItem]
        animated:YES];
}

- (void)userFailedToSendTweet:(NSString *)tweet
{
    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self newTweetButtonItem]
        animated:YES];

    // if the error happened quickly, while the compose modal view is still
    // dismissing, re-presenting it has no effect; force a brief delay for now
    // and revisit later
    [self.composeTweetDisplayMgr
        performSelector:@selector(composeTweetWithText:)
             withObject:tweet
             afterDelay:0.8];
}

- (void)userIsReplyingToTweet:(NSNumber *)origTweetId
                     fromUser:(NSString *)origUsername
                     withText:(NSString *)text
{
}

- (void)userDidReplyToTweet:(NSNumber *)origTweetId
                   fromUser:(NSString *)origUsername
                  withTweet:(Tweet *)reply
{
    [timelineDisplayMgr addTweet:reply];
}

- (void)userFailedToReplyToTweet:(NSNumber *)origTweetId
                        fromUser:(NSString *)origUsername
                        withText:(NSString *)text
{
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        origTweetId, @"origTweetId",
        origUsername, @"origUsername",
        text, @"text", nil];

    // if the error happened quickly, while the compose modal view is still
    // dismissing, re-presenting it has no effect; force a brief delay for now
    // and revisit later
    [NSTimer
        scheduledTimerWithTimeInterval:0.8
                                target:self
                              selector:@selector(presentFailedReplyOnTimer:)
                              userInfo:userInfo
                               repeats:NO];
}

- (void)presentFailedReplyOnTimer:(NSTimer *)timer
{
    NSDictionary * userInfo = timer.userInfo;
    NSNumber * origTweetId = [userInfo objectForKey:@"origTweetId"];
    NSString * origUsername = [userInfo objectForKey:@"origUsername"];
    NSString * text = [userInfo objectForKey:@"text"];

    [self.composeTweetDisplayMgr composeReplyToTweet:origTweetId
                                            fromUser:origUsername
                                            withText:text];
}

- (void)userIsSendingDirectMessage:(NSString *)dm to:(NSString *)username
{
    NSLog(@"Twitch app delegate: sending direct message");
}

- (void)userDidSendDirectMessage:(DirectMessage *)dm
{
    NSLog(@"Twitch app delegate: sent direct message");
}

- (void)userFailedToSendDirectMessage:(NSString *)dm to:(NSString *)username
{
    NSLog(@"Twitch app delegate: failed to send direct message");

    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        dm, @"dm",
        username, @"username", nil];

    // if the error happened quickly, while the compose modal view is still
    // dismissing, re-presenting it has no effect; force a brief delay for now
    // and revisit later
    SEL sel = @selector(presentFailedDirectMessageOnTimer:);
    [NSTimer scheduledTimerWithTimeInterval:0.8
                                     target:self
                                   selector:sel
                                   userInfo:userInfo
                                    repeats:NO];
}

- (void)presentFailedDirectMessageOnTimer:(NSTimer *)timer
{
    NSDictionary * userInfo = timer.userInfo;
    NSString * dm = [userInfo objectForKey:@"dm"];
    NSString * username = [userInfo objectForKey:@"username"];

    [self.composeTweetDisplayMgr composeDirectMessageTo:username withText:dm
        animated:YES];
}

#pragma mark TwitchWebBrowserDisplayMgrDelegate implementation

- (void)readLater:(NSString *)aUrl
{
    NSLog(@"User wants to read '%@' later.", aUrl);

    InstapaperCredentials * instapaperCredentials =
        self.activeCredentials.credentials.instapaperCredentials;
    if (instapaperCredentials) {
        self.instapaperService.credentials = instapaperCredentials;
        [self.instapaperService addUrl:aUrl];
    } else {
        // prompt the user to set up an account
        self.instapaperLogInDisplayMgr.credentials =
            self.activeCredentials.credentials;
        [self.instapaperLogInDisplayMgr
            logInModallyForViewController:
            [[TwitchWebBrowserDisplayMgr instance] browserController]];
        self.savingInstapaperUrl = aUrl;  // remember for later
    }
}

#pragma mark InstapaperLogInDisplayMgrDelegate implementation

- (void)accountCreated:(InstapaperCredentials *)instapaperCredentials
{
    NSAssert(self.savingInstapaperUrl,
        @"I don't know which URL I'm supposed to be saving.");

    self.instapaperService.credentials = instapaperCredentials;
    [self.instapaperService addUrl:self.savingInstapaperUrl];
}

- (void)accountCreationCancelled
{
    self.savingInstapaperUrl = nil;
}

- (void)accountEdited:(InstapaperCredentials *)credentials
{
    // don't care
}

- (void)editingAccountCancelled:(InstapaperCredentials *)credentials
{
    // don't care
}

- (void)accountWillBeDeleted:(InstapaperCredentials *)credentials
{
    // don't care
}

- (void)postedUrl:(NSString *)url
{
    NSLog(@"Successfully saved '%@' to Instapaper.", url);
    if ([url isEqualToString:self.savingInstapaperUrl])
        self.savingInstapaperUrl = nil;
}

- (void)failedToPostUrl:(NSString *)url error:(NSError *)error
{
    NSString * title =
        NSLocalizedString(@"instapaper.save.failed.alert.title", @"");
    NSString * message = error.localizedDescription;

    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
}

#pragma mark initialization helpers

- (void)initHomeTab
{
    NSString * homeTabTitle =
        NSLocalizedString(@"appdelegate.hometabtitle", @"");
    timelineDisplayMgr =
        [[timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        homeNetAwareViewController
        navigationController:mainNavController
        title:homeTabTitle
        composeTweetDisplayMgr:self.composeTweetDisplayMgr]
        retain];
    timelineDisplayMgr.displayAsConversation = YES;
    timelineDisplayMgr.showMentions = YES;

    TwitterCredentials * c = self.activeCredentials.credentials;
    if (c) {
        [timelineDisplayMgr setCredentials:c];
        [self loadHomeViewWithCachedData:c];
    }

    CGFloat offset = uiState.timelineContentOffset;
    if (offset > 44 && offset < [timelineDisplayMgr timelineContentHeight] &&
        ![SettingsReader scrollToTop])
        [timelineDisplayMgr setTableViewContentOffset:offset];
}

- (void)initMentionsTab
{
    TimelineViewController * timelineController =
        [[[TimelineViewController alloc]
        initWithNibName:@"TimelineView" bundle:nil] autorelease];
    mentionsNetAwareViewController.targetViewController = timelineController;
    
    TwitterService * service =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:[self managedObjectContext]]
        autorelease];
    
    UserListDisplayMgrFactory * userListDisplayMgrFactory =
        [[[UserListDisplayMgrFactory alloc]
        initWithContext:[self managedObjectContext]
        findPeopleBookmarkMgr:nil contactCache:contactCache
        contactMgr:contactMgr]
        autorelease];
    
    mentionDisplayMgr =
        [[MentionTimelineDisplayMgr alloc]
        initWithWrapperController:mentionsNetAwareViewController
        navigationController:mainNavController
        timelineController:timelineController
        service:service
        factory:timelineDisplayMgrFactory
        managedObjectContext:[self managedObjectContext]
        composeTweetDisplayMgr:self.composeTweetDisplayMgr
        findPeopleBookmarkMgr:nil
        userListDisplayMgrFactory:userListDisplayMgrFactory
        tabBarItem:nil contactCache:contactCache contactMgr:contactMgr];
    service.delegate = mentionDisplayMgr;
    timelineController.delegate = mentionDisplayMgr;
    mentionsNetAwareViewController.delegate = mentionDisplayMgr;
    
    mentionsAcctMgr =
        [[MentionsAcctMgr alloc]
        initWithMentionTimelineDisplayMgr:mentionDisplayMgr];
    
    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:mentionDisplayMgr action:@selector(setCredentials:)];
    
    TwitterCredentials * c = self.activeCredentials.credentials;
    if (c) {
        [mentionDisplayMgr setCredentials:c];
        [self loadMentionsViewWithCachedData:c];
    }
}

- (void)initFavoritesTab
{
    favoritesDisplayMgr =
        [[timelineDisplayMgrFactory
        createFavoritesDisplayMgrWithWrapperController:
        favoritesNetAwareViewController
        navigationController:mainNavController
        title:@"Favorites"
        composeTweetDisplayMgr:self.composeTweetDisplayMgr]
        retain];
    favoritesDisplayMgr.displayAsConversation = YES;
    favoritesDisplayMgr.showMentions = YES;
    
    TwitterCredentials * c = self.activeCredentials.credentials;
    if (c)
        [favoritesDisplayMgr setCredentials:c];
}

- (void)initRetweetsTab
{
    retweetsDisplayMgr =
        [[timelineDisplayMgrFactory
        createRetweetsDisplayMgrWithWrapperController:
        retweetsNetAwareViewController
        navigationController:mainNavController
        title:@"Retweets"
        composeTweetDisplayMgr:self.composeTweetDisplayMgr]
        retain];
    retweetsDisplayMgr.displayAsConversation = YES;
    retweetsDisplayMgr.showMentions = YES;
    
    TwitterCredentials * c = self.activeCredentials.credentials;
    if (c)
        [retweetsDisplayMgr setCredentials:c];
}

- (void)initAccountsView
{
    accountsViewController.navigationController.navigationBar.barStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIBarStyleBlackOpaque : UIBarStyleDefault;
    accountsViewController.selectedAccountTarget = self;
    accountsViewController.selectedAccountAction =
        @selector(processUserAccountSelection);

    XauthLogInDisplayMgr * displayMgr =
        [[XauthLogInDisplayMgr alloc]
        initWithRootViewController:mainNavController
        managedObjectContext:[self managedObjectContext]];
    // displayMgr.navigationController = mainNavController;

    accountsDisplayMgr =
        [[AccountsDisplayMgr alloc]
        initWithAccountsViewController:accountsViewController
        logInDisplayMgr:displayMgr
        context:[self managedObjectContext]];
    
    [displayMgr release];
}

- (void)initListsMgr
{
    TwitterCredentials * creds =
        self.activeCredentials ? self.activeCredentials.credentials : nil;

    TwitterService * service =
        [[[TwitterService alloc]
        initWithTwitterCredentials:creds
        context:[self managedObjectContext]] autorelease];

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:service action:@selector(setCredentials:)];

    listsDisplayMgr =
        [[ListsDisplayMgr alloc]
        initWithWrapperController:listsNetAwareViewController
        navigationController:mainNavController
        listsViewController:timelineSelectionController
        service:service
        factory:timelineDisplayMgrFactory
        composeTweetDisplayMgr:self.composeTweetDisplayMgr
        context:[self managedObjectContext]];
    service.delegate = listsDisplayMgr;
    listsNetAwareViewController.delegate = listsDisplayMgr;
    
    [listsDisplayMgr setCredentials:creds];
    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:listsDisplayMgr action:@selector(setCredentials:)];

    if (creds) {
        NSPredicate * predicate =
            [NSPredicate predicateWithFormat:@"credentials.username == %@",
            creds.username];
        NSArray * lists = [UserTwitterList findAll:predicate
                                           context:[self managedObjectContext]];

        [listsDisplayMgr displayLists:lists];
        [listsDisplayMgr refreshLists];
    }
}

- (void)initAnalytics
{
    NSLog(@"Starting analytics collection.");
    [self.analyticsService startAnalytics];
}

- (void)terminateAnalytics
{
    NSLog(@"Stopping analytics collection");
    [self.analyticsService stopAnalytics];
    NSLog(@"Analytics collection stopped");
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

    managedObjectModel =
        [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}

+ (NSString *)persistentStoreType
{
    return NSSQLiteStoreType;
}

- (NSString *)legacyStorePath
{
    NSString * documentsDir = [self applicationDocumentsDirectory];
    return [documentsDir stringByAppendingPathComponent:@"Twitch.sqlite"];
}

- (NSURL *)legacyStoreUrl
{
    return [NSURL fileURLWithPath:[self legacyStorePath]];
}

- (NSString *)storePath
{
    NSString * documentsDir = [self applicationDocumentsDirectory];
    return [documentsDir stringByAppendingPathComponent:@"Twitbit.sqlite"];
}

- (NSURL *)storeUrl
{
    return [NSURL fileURLWithPath:[self storePath]];
}

- (NSDictionary *)metaDataForStoreAtUrl:(NSURL *)storeUrl
{
    NSError * error = nil;
    NSDictionary * sourceMetadata =
        [NSPersistentStoreCoordinator
        metadataForPersistentStoreOfType:[[self class] persistentStoreType]
                                     URL:storeUrl
                                   error:&error];

    return sourceMetadata;
}

- (BOOL)migratePersistentStoreFromUrl:(NSURL *)sourceUrl
                                toUrl:(NSURL *)destUrl
                                error:(NSError **)error
{
    NSDictionary * sourceMetadata = [self metaDataForStoreAtUrl:sourceUrl];
    if (!sourceMetadata)
        return NO;

    NSManagedObjectModel * sourceModel =
        [NSManagedObjectModel mergedModelFromBundles:nil
                                    forStoreMetadata:sourceMetadata];

    NSManagedObjectModel * destinationModel = [self managedObjectModel];
    NSMappingModel * mappingModel =
        [NSMappingModel mappingModelFromBundles:nil
                                 forSourceModel:sourceModel
                               destinationModel:destinationModel];

    if (mappingModel == nil) {
        // deal with the error
        NSLog(@"Failed to find mapping model.");
        return NO;
    }

    NSMigrationManager * migrationManager =
        [[NSMigrationManager alloc] initWithSourceModel:sourceModel
                                       destinationModel:destinationModel];

    NSDictionary * sourceStoreOptions = nil;
    NSString * storeType = [[self class] persistentStoreType];
    NSDictionary * destinationStoreOptions = nil;

    BOOL ok = [migrationManager migrateStoreFromURL:sourceUrl
                                               type:storeType
                                            options:sourceStoreOptions
                                   withMappingModel:mappingModel
                                   toDestinationURL:destUrl
                                    destinationType:storeType
                                 destinationOptions:destinationStoreOptions
                                              error:error];

    return ok;
}

- (BOOL)migrateFromLegacyPersistentStoreIfNecessary
{
    BOOL migrated = NO;
    NSError * error = nil;

    NSFileManager * fm = [NSFileManager defaultManager];

    BOOL legacyStoreExists = [fm fileExistsAtPath:[self legacyStorePath]];
    BOOL storeExists = [fm fileExistsAtPath:[self storePath]];

    if (legacyStoreExists && !storeExists) {
        NSURL * sourceUrl = [self legacyStoreUrl];
        NSURL * destUrl = [self storeUrl];

        BOOL migrated =
            [self migratePersistentStoreFromUrl:sourceUrl
                                          toUrl:destUrl
                                          error:&error];


        if (migrated)
            NSLog(@"Migration from '%@' to '%@' succeeded.", sourceUrl,
                destUrl);
        else
            NSLog(@"Failed to migrate from '%@' to '%@': %@", sourceUrl,
                destUrl, [error detailedDescription]);
    }

    if (legacyStoreExists) {
        if ([fm removeItemAtPath:[self legacyStorePath] error:&error])
            NSLog(@"Deleted legacy persistent store at: '%@'",
                [self legacyStorePath]);
        else
            NSLog(@"Failed to remove legacy source store at: '%@': %@",
                [self legacyStorePath], [error detailedDescription]);
    }

    return migrated;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
        return persistentStoreCoordinator;

    if ([self migrateFromLegacyPersistentStoreIfNecessary])
        NSLog(@"Successfully migrated from legacy persistent store.");
	
    NSURL * storeUrl = [self storeUrl];
	
	NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSDictionary * pscOptions =
        [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
        [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:pscOptions error:&error]) {
        NSLog(@"Failed to created persistent store coordinator: '%@'.", [error detailedDescription]);

        NSString * message;
        if (error.userInfo) {
            message = [error.userInfo valueForKeyPath:@"reason"];
            NSLog(@"Reason: %@", message);
            NSLog(@"User info: '%@'.", error.userInfo);
        } else
            message = error.localizedDescription;

        NSString * title =
            NSLocalizedString(@"persistence.initialization.failed.title", @"");
        [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
    }    
	
    return persistentStoreCoordinator;
}

- (ManagedObjectContextPruner *)managedObjectContextPruner
{
    if (!managedObjectContextPruner) {
        NSManagedObjectContext * context = [self managedObjectContext];
        NSInteger numTweets = [SettingsReader fetchQuantity];
        NSInteger numMentions = [SettingsReader fetchQuantity];
        NSInteger numDms = 500;

        managedObjectContextPruner =
            [[ManagedObjectContextPruner alloc] initWithContext:context
                                                numTweetsToKeep:numTweets
                                              numMentionsToKeep:numMentions
                                                   numDmsToKeep:numDms];
    }

    return managedObjectContextPruner;
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

    NSInteger count = credentials.count;
    NSLog(@"Have %d credentials", count);
    for (int i = 0; i < count; ++i) {
        id c = [credentials objectAtIndex:i];
        NSLog(@"%d: Credentials: %@", i, c);
    }

    NSDictionary * args =
        [self deviceRegistrationArgsForCredentials:credentials];
    [self.registrar sendProviderDeviceToken:deviceToken args:args];
}

- (void)application:(UIApplication *)app
    didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Application failed to register for push notifications: %@", error);

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
        AccountSettings * settings =
            [AccountSettings settingsForKey:c.username];

        NSString * usernameKey = [NSString stringWithFormat:@"username%d", i];
        NSString * keyKey = [NSString stringWithFormat:@"key%d", i];
        NSString * secretKey = [NSString stringWithFormat:@"secret%d", i];
        NSString * configKey =
            [NSString stringWithFormat:@"push_notification_config%d", i];
        NSString * soundFileKey =
            [NSString stringWithFormat:@"push_notification_sound%d", i];

        [args setObject:c.username forKey:usernameKey];
        [args setObject:c.key forKey:keyKey];
        [args setObject:c.secret forKey:secretKey];
        [args setObject:[settings pushSettings] forKey:configKey];
        [args setObject:[settings pushNotificationSound].file
                 forKey:soundFileKey];
    }

    return args;
}

#pragma mark DeviceRegistrarDelegate implementation

- (void)registeredDeviceWithToken:(NSData *)token
{
    NSLog(@"Successfully registered the device for push notifications: '%@'.",
        token);
}

- (void)failedToRegisterDeviceWithToken:(NSData *)token error:(NSError *)error
{
    // only log the error for now; add an error message later if it becomes
    // necessary
    NSLog(@"Failed to register device for push notifications: '%@', error: "
        "'%@'.", token, error);
}

#pragma mark Application notifications

- (void)credentialsActivated:(TwitterCredentials *)activatedCredentials
{
    if (!self.activeCredentials) // first account has been created
        activeCredentials =
            [[ActiveTwitterCredentials
            createInstance:[self managedObjectContext]] retain];

    self.activeCredentials.credentials = activatedCredentials;
    [self saveContext];
}

- (void)credentialsSetChanged:(TwitterCredentials *)changedCredentials
                        added:(NSNumber *)added
{
    if ([added boolValue]) {
        if (self.credentials.count == 0) { // first credentials -- active them
            NSLog(@"Setting first credentials");
            [self broadcastActivatedCredentialsChanged:changedCredentials];

            [mentionsAcctMgr
                processAccountChangeToUsername:changedCredentials.username
                fromUsername:nil];
            
            [mainNavController pushViewController:timelineSelectionController
                animated:NO];
            [listsDisplayMgr refreshLists];
        }
        [self.credentials addObject:changedCredentials];
    } else {
        [TwitterCredentials
            deleteKeyAndSecretForUsername:changedCredentials.username];
        [self.credentials removeObject:changedCredentials];
        [mentionsAcctMgr
            processAccountRemovedForUsername:changedCredentials.username];
    }

    NSLog(@"Active credentials after account switch: '%@'.",
        self.activeCredentials.credentials.username);
    [self saveContext];
}

- (void)accountSettingsChanged:(AccountSettings *)settings
                    forAccount:(NSString *)account
{
    NSLog(@"Handling account settings change");
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

+ (NSInteger)mentionsTabBarItemTag
{
    return 1;
}

#pragma mark Persistence helpers

- (BOOL)saveContext
{
    NSError * error;
    if ([managedObjectContext hasChanges] &&
        ![managedObjectContext save:&error]) {
        // Handle error
        NSLog(@"Failed to save to data store: %@",
            [error localizedDescription]);
        NSArray * detailedErrors =
            [[error userInfo] objectForKey:NSDetailedErrorsKey];
        if(detailedErrors != nil && [detailedErrors count] > 0)
            for(NSError * detailedError in detailedErrors)
                NSLog(@"  Detailed error: %@", [detailedError userInfo]);
        else
            NSLog(@"  %@", [error userInfo]);
    }

    return YES;
}

- (void)prunePersistentStore
{
    [self.managedObjectContextPruner pruneContext];
}

- (void)loadHomeViewWithCachedData:(TwitterCredentials *)account
{
    // important to access the context via the accessor
    NSManagedObjectContext * context = [self managedObjectContext];

    NSPredicate * predicate = 
        [NSPredicate predicateWithFormat:@"credentials.username == %@",
        account.username];

    NSArray * paths =
        [NSArray arrayWithObjects:@"user", @"user.avatar", @"retweet",
        @"retweet.user", @"retweet.user.avatar", nil];
    NSArray * allTweets = [UserTweet findAll:predicate
                                     context:context
                          prefetchedKeyPaths:paths];

    NSLog(@"***************** Persistence check *****************");
    NSLog(@"** %@: Loaded %d persisted tweets.", account.username,
        allTweets.count);

    // allTweets are now sorted in ascending order, e.g. from oldest to newest
    allTweets = [allTweets sortedArrayUsingSelector:@selector(compare:)];
    Tweet * newestTweet = allTweets.count ? [allTweets lastObject] : nil;
    NSNumber * newestTweetId =
        newestTweet ?
        [NSNumber numberWithLongLong:[newestTweet.identifier longLongValue]] :
        [NSNumber numberWithInt:0];
    if (allTweets.count) {
        Tweet * oldestTweet = [allTweets objectAtIndex:0];
        NSLog(@"** Newest tweet loaded from persistence: '%@': '%@': '%@'",
            newestTweet.identifier, newestTweet.user.username,
            newestTweet.text);
        NSLog(@"** Oldest tweet loaded from persistence: '%@': '%@': '%@'",
            oldestTweet.identifier, oldestTweet.user.username,
            oldestTweet.text);
    }

    /*
     * The first time we load cached data for an account, make sure we only load
     * the most recent n tweets, where n is the fetch quantity setting. If, for
     * example, the application crashed, it's possible there will be more than
     * n tweets loaded from persistence. This will cause the timeline code to
     * think it should load a page other than the first page when it does its
     * initial fetch from Twitter. For example, if n is 20, and 23 tweets are
     * loaded from persistence, the timeline will fetch page 2.
     *
     * We only want to do this pruning the first time we load tweets for an
     * account. Subsequent times are from account switching, and we want the
     * full range of tweets to remain.
     */
    static NSMutableSet * alreadyLoaded = nil;
    if (!alreadyLoaded)
        alreadyLoaded = [[NSMutableSet alloc] init];

    if (![alreadyLoaded containsObject:account.username]) {
        [alreadyLoaded addObject:account.username];

        const NSUInteger MAX_SIZE = [SettingsReader fetchQuantity];
        if (allTweets.count > MAX_SIZE) {
            NSLog(@"Trimming tweets down to %d.", MAX_SIZE);

            NSRange range = NSMakeRange(0, allTweets.count - MAX_SIZE);
            NSArray * tweetsToDelete = [allTweets subarrayWithRange:range];
            for (UserTweet * tweet in tweetsToDelete)
                [context deleteObject:tweet];
            [self saveContext];

            range = NSMakeRange(allTweets.count - MAX_SIZE, MAX_SIZE);
            allTweets = [allTweets subarrayWithRange:range];
        }
    }
    NSLog(@"***************** Persistence check *****************");

    // convert them all to dictionaries
    NSMutableDictionary * tweets =
        [NSMutableDictionary dictionaryWithCapacity:allTweets.count];
    for (UserTweet * tweet in allTweets)
        [tweets setObject:tweet forKey:tweet.identifier];

    timelineDisplayMgr.tweetIdToShow = newestTweetId;
    [timelineDisplayMgr setTweets:tweets];
}

- (void)loadMentionsViewWithCachedData:(TwitterCredentials *)account
{
    // important to access the context via the accessor
    NSManagedObjectContext * context = [self managedObjectContext];

    NSPredicate * predicate = 
        [NSPredicate predicateWithFormat:@"credentials.username == %@",
        account.username];

    NSArray * paths = [NSArray arrayWithObjects:@"user", @"user.avatar", nil];
    NSArray * allMentions =
        [Mention findAll:predicate context:context prefetchedKeyPaths:paths];

    allMentions = [allMentions sortedArrayUsingSelector:@selector(compare:)];
    Tweet * newestTweet = allMentions.count ? [allMentions lastObject] : nil;
    NSNumber * newestTweetId =
        newestTweet ?
        [NSNumber numberWithLongLong:[newestTweet.identifier longLongValue]] :
        [NSNumber numberWithInt:0];

    /*
     * The first time we load cached data for an account, make sure we only load
     * the most recent n tweets, where n is the fetch quantity setting. If, for
     * example, the application crashed, it's possible there will be more than
     * n tweets loaded from persistence. This will cause the timeline code to
     * think it should load a page other than the first page when it does its
     * initial fetch from Twitter. For example, if n is 20, and 23 tweets are
     * loaded from persistence, the timeline will fetch page 2.
     *
     * We only want to do this pruning the first time we load tweets for an
     * account. Subsequent times are from account switching, and we want the
     * full range of tweets to remain.
     */
    static NSMutableSet * alreadyLoaded = nil;
    if (!alreadyLoaded)
        alreadyLoaded = [[NSMutableSet alloc] init];

    if (![alreadyLoaded containsObject:account.username]) {
        [alreadyLoaded addObject:account.username];

        const NSUInteger MAX_SIZE = [SettingsReader fetchQuantity];
        if (allMentions.count > MAX_SIZE) {
            NSLog(@"Trimming mentions down to %d.", MAX_SIZE);

            NSRange range = NSMakeRange(0, allMentions.count - MAX_SIZE);
            NSArray * mentionsToDelete = [allMentions subarrayWithRange:range];
            for (Mention * mention in mentionsToDelete)
                [context deleteObject:mention];
            [self saveContext];

            range = NSMakeRange(allMentions.count - MAX_SIZE, MAX_SIZE);
            allMentions = [allMentions subarrayWithRange:range];
        }
    }

    // convert them all to dictionaries with TweetInfo objects as values
    NSMutableDictionary * mentions =
        [NSMutableDictionary dictionaryWithCapacity:allMentions.count];
    for (Mention * mention in allMentions)
        [mentions setObject:mention forKey:mention.identifier];

    mentionDisplayMgr.mentionIdToShow = newestTweetId;
    [mentionDisplayMgr setTimeline:mentions updateId:newestTweetId];
}

- (void)setUIStateFromPersistenceAndNotification:(NSDictionary *)notification
{
    UIStatePersistenceStore * uiStatePersistenceStore =
        [[[UIStatePersistenceStore alloc] init] autorelease];
    uiState = [[uiStatePersistenceStore load] retain];

    if (notification)
        [self updateUIStateWithNotification:notification
            mentionTabLocation:0
            messageTabLocation:0];

    if (uiState.composingTweet)
        [self.composeTweetDisplayMgr composeTweetAnimated:NO];

    if (uiState.viewingUrl) {
        TwitchWebBrowserDisplayMgr * webDispMgr =
            [TwitchWebBrowserDisplayMgr instance];
        webDispMgr.composeTweetDisplayMgr = self.composeTweetDisplayMgr;
        webDispMgr.hostViewController = mainNavController;
        webDispMgr.delegate = self;

        [webDispMgr visitWebpage:uiState.viewingUrl withHtml:nil animated:NO];
    }

    // Show the appropriate timeline
    switch (uiState.currentlyViewedTimeline) {
        case 0: // timeline
            [self showTimelineAnimated:NO];
            break;
        case 1: // mentions
            [self showMentionsAnimated:NO];
            break;
        case 2: // favorites
            [self showFavoritesAnimated:NO];
            break;
        case 3: // retweets
            [self showRetweetsAnimated:NO];
            break;
    }
    
    if (uiState.currentlyViewedTweetId) {
        [self initHomeTab];
        Tweet * tweet =
            [Tweet tweetWithId:uiState.currentlyViewedTweetId
            context:[self managedObjectContext]];
        if (tweet)
            [timelineDisplayMgr pushTweetWithoutAnimation:tweet];
        else
            [timelineDisplayMgr
                loadNewTweetWithId:uiState.currentlyViewedTweetId
                username:nil animated:NO];
    }
}

- (void)updateUIStateWithNotification:(NSDictionary *)notification
    mentionTabLocation:(NSInteger)mentionTabLocation
    messageTabLocation:(NSInteger)messageTabLocation
{
    PushNotificationMessage * pnm =
        [PushNotificationMessage parseFromDictionary:notification];
    if (pnm) {
        if (pnm.messageType == kPushNotificationMessageTypeMention) {
            uiState.currentlyViewedMentionId = pnm.messageId;
        }

        NSString * account = pnm.accountUsername;
        NSPredicate * pred =
            [NSPredicate predicateWithFormat:@"SELF.username == %@", account];
        NSArray * creds =
            [credentials filteredArrayUsingPredicate:pred];

        if ([creds count] == 1) {
            NSString * currentUser = activeCredentials.credentials.username;
            if (![currentUser isEqualToString:account]) {
                [self activateAccountWithName:account];
                uiState.timelineContentOffset = 0;
            }
        }
    }
}

- (void)persistUIState
{
    UIStatePersistenceStore * uiStatePersistenceStore =
        [[[UIStatePersistenceStore alloc] init] autorelease];

    NSUInteger numUnreadMentions = 0;

    uiState.composingTweet = self.composeTweetDisplayMgr.composingTweet;

    TwitchWebBrowserDisplayMgr * webDispMgr =
        [TwitchWebBrowserDisplayMgr instance];
    uiState.viewingUrl = webDispMgr.currentUrl;

    uiState.currentlyViewedTweetId = timelineDisplayMgr.currentlyViewedTweetId;
    uiState.currentlyViewedMentionId = mentionDisplayMgr.currentlyViewedTweetId;

    uiState.timelineContentOffset = [timelineDisplayMgr tableViewContentOffset];

    [uiStatePersistenceStore save:uiState];
    
    NSUInteger numTotalMessages = numUnreadMentions;
    [[UIApplication sharedApplication]
        setApplicationIconBadgeNumber:numTotalMessages];

    ContactCachePersistenceStore * contactCachePersistenceStore =
        [[[ContactCachePersistenceStore alloc]
        initWithContactCache:contactCache] autorelease];
    [contactCachePersistenceStore save];
}

#pragma mark Account management

- (void)activateAccountWithName:(NSString *)accountName
{
    NSPredicate * pred =
        [NSPredicate predicateWithFormat:@"username == %@", accountName];
    TwitterCredentials * creds =
        [TwitterCredentials findFirst:pred context:[self managedObjectContext]];

    if (creds) {
        [homeNetAwareViewController setCachedDataAvailable:NO];
        [self processAccountChange:creds];
    }
}

- (void)processUserAccountSelection
{
    TwitterCredentials * activeAccount = [accountsDisplayMgr selectedAccount];

    NSLog(@"Processing user account selection ('%@')", activeAccount.username);

    if (activeAccount &&
        activeAccount != self.activeCredentials.credentials) {
        [homeNetAwareViewController setCachedDataAvailable:NO];

        [self performSelector:@selector(processAccountChange:)
            withObject:activeAccount afterDelay:0.0];
    }
    
    timelineSelectionController.navigationItem.title = activeAccount.username;
    [mainNavController pushViewController:timelineSelectionController
        animated:YES];
}

- (void)processAccountChange:(TwitterCredentials *)activeAccount
{
    NSLog(@"Switching account to: '%@'.", activeAccount.username);

    [[ErrorState instance] exitErrorState];

    // oldUsername will be nil when the previously active account is
    // deleted
    NSString * oldUsername =
        self.activeCredentials.credentials.username;
    
    [self broadcastActivatedCredentialsChanged:activeAccount];
    [self loadHomeViewWithCachedData:activeAccount];
    [self loadMentionsViewWithCachedData:activeAccount];
    
    [mentionsAcctMgr
        processAccountChangeToUsername:activeAccount.username
        fromUsername:oldUsername];
    
    [listsDisplayMgr resetState];
    
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"credentials.username == %@",
        activeAccount.username];
    NSArray * lists = [UserTwitterList findAll:predicate
                                       context:[self managedObjectContext]];

    [listsDisplayMgr displayLists:lists];
    [listsDisplayMgr refreshLists];
}

#pragma mark TimelineSelectionViewControllerDelegate implementation

- (void)showTimeline
{
    [self showTimelineAnimated:YES];
}

- (void)showTimelineAnimated:(BOOL)animated
{
    if (!timelineDisplayMgr)
        [self initHomeTab];
    if (!timelineDisplayMgr.needsRefresh && timelineDisplayMgr.hasBeenDisplayed)
        [timelineDisplayMgr refreshWithLatest];
    [mainNavController pushViewController:homeNetAwareViewController
        animated:animated];
    uiState.currentlyViewedTimeline = 0;
}

- (void)showMentions
{
    [self showMentionsAnimated:YES];
}

- (void)showMentionsAnimated:(BOOL)animated
{
    if (!mentionDisplayMgr)
        [self initMentionsTab];
    TwitterCredentials * c = self.activeCredentials.credentials;
    if (c)
        [mentionDisplayMgr updateMentionsSinceLastUpdateIds];
    [mainNavController pushViewController:mentionsNetAwareViewController
        animated:animated];
    uiState.currentlyViewedTimeline = 1;
}

- (void)showFavorites
{
    [self showFavoritesAnimated:YES];
}

- (void)showFavoritesAnimated:(BOOL)animated
{
    if (!favoritesDisplayMgr)
        [self initFavoritesTab];
    if (!favoritesDisplayMgr.needsRefresh &&
        favoritesDisplayMgr.hasBeenDisplayed)
        [favoritesDisplayMgr refreshWithLatest];
    [mainNavController pushViewController:favoritesNetAwareViewController
        animated:animated];
    uiState.currentlyViewedTimeline = 2;
}

- (void)showRetweets
{
    [self showRetweetsAnimated:YES];
}

- (void)showRetweetsAnimated:(BOOL)animated
{
    if (!retweetsDisplayMgr)
        [self initRetweetsTab];
    if (!retweetsDisplayMgr.needsRefresh &&
        retweetsDisplayMgr.hasBeenDisplayed)
        [retweetsDisplayMgr refreshWithLatest];
    [mainNavController pushViewController:retweetsNetAwareViewController
        animated:animated];
    uiState.currentlyViewedTimeline = 3;
}

- (void)userDidSelectListWithId:(NSNumber *)identifier
{
    [listsDisplayMgr userDidSelectListWithId:identifier];
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

- (XauthLogInDisplayMgr *)logInDisplayMgr
{
    if (!logInDisplayMgr)
        logInDisplayMgr =
            [[XauthLogInDisplayMgr alloc]
            initWithRootViewController:mainNavController
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
            initWithRootViewController:mainNavController
                        twitterService:service
                               context:[self managedObjectContext]];
        [service release];

        composeTweetDisplayMgr.delegate = self;
    }

    return composeTweetDisplayMgr;
}

- (UIBarButtonItem *)homeSendingTweetProgressView
{
    if (!homeSendingTweetProgressView) {
        NSString * backgroundImageFilename =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            @"NavigationButtonBackgroundDarkTheme.png" :
            @"NavigationButtonBackground.png";
        UIView * view =
            [[UIImageView alloc]
            initWithImage:[UIImage imageNamed:backgroundImageFilename]];
        UIActivityIndicatorView * activityView =
            [[[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]
            autorelease];
        activityView.frame = CGRectMake(7, 5, 20, 20);
        [view addSubview:activityView];

        homeSendingTweetProgressView =
            [[UIBarButtonItem alloc] initWithCustomView:view];

        [activityView startAnimating];

        [view release];
    }

    return homeSendingTweetProgressView;
}

- (UIBarButtonItem *)mentionsSendingTweetProgressView
{
    if (!mentionsSendingTweetProgressView) {
        NSString * backgroundImageFilename =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            @"NavigationButtonBackgroundDarkTheme.png" :
            @"NavigationButtonBackground.png";
        UIView * view =
            [[UIImageView alloc]
            initWithImage:[UIImage imageNamed:backgroundImageFilename]];
        UIActivityIndicatorView * activityView =
            [[[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]
            autorelease];
        activityView.frame = CGRectMake(7, 5, 20, 20);
        [view addSubview:activityView];

        mentionsSendingTweetProgressView =
            [[UIBarButtonItem alloc] initWithCustomView:view];

        [activityView startAnimating];

        [view release];
    }

    return mentionsSendingTweetProgressView;
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

- (InstapaperService *)instapaperService
{
    if (!instapaperService) {
        instapaperService = [[InstapaperService alloc] init];
        instapaperService.delegate = self;
    }

    return instapaperService;
}

- (InstapaperLogInDisplayMgr *)instapaperLogInDisplayMgr
{
    if (!instapaperLogInDisplayMgr) {
        instapaperLogInDisplayMgr =
            [[InstapaperLogInDisplayMgr alloc]
            initWithContext:[self managedObjectContext]];
        instapaperLogInDisplayMgr.delegate = self;
    }

    return instapaperLogInDisplayMgr;
}

- (AnalyticsService *)analyticsService
{
    if (!analyticsService)
        analyticsService = [[AnalyticsService alloc] init];

    return analyticsService;
}

- (IBAction)userWantsToAddAccount:(id)sender
{
    [accountsViewController userWantsToAddAccount:sender];
}

#pragma mark Shake-to-refresh implementation

static BOOL L0AccelerationIsShaking(UIAcceleration* last,
    UIAcceleration* current, double threshold)
{
    double deltaX = fabs(last.x - current.x);
    double deltaY = fabs(last.y - current.y);
    double deltaZ = fabs(last.z - current.z);

    return (deltaX > threshold && deltaY > threshold) ||
        (deltaX > threshold && deltaZ > threshold) ||
        (deltaY > threshold && deltaZ > threshold);
}

- (void)accelerometer:(UIAccelerometer *)accelerometer
    didAccelerate:(UIAcceleration *)acceleration
{
    if (self.lastAcceleration) {
        if (!histeresisExcited &&
            L0AccelerationIsShaking(self.lastAcceleration, acceleration, 0.7)) {
            histeresisExcited = YES;

            NSLog(@"Refreshing due to shake...");
            [timelineDisplayMgr refreshWithLatest];
            [mentionDisplayMgr updateMentionsAfterCredentialChange];
        } else if (histeresisExcited &&
            !L0AccelerationIsShaking(self.lastAcceleration, acceleration, 0.2))
            histeresisExcited = NO;
    }

    self.lastAcceleration = acceleration;
}

#pragma mark Memory warnings

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    NSLog(@"WARNING: application received a memory warning.");
}

@end
