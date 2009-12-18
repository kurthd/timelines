//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitchAppDelegate.h"
#import "DeviceRegistrar.h"
#import "OauthLogInDisplayMgr.h"
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
#import "SearchBarDisplayMgr.h"
#import "AccountsDisplayMgr.h"
#import "ActiveTwitterCredentials.h"
#import "UIStatePersistenceStore.h"
#import "UserTweet.h"
#import "Mention.h"
#import "DirectMessage.h"
#import "NSObject+RuntimeAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "DirectMessageCache.h"  // so persisted objects can be displayed
#import "NewDirectMessagesPersistenceStore.h"
#import "NewDirectMessagesState.h"
#import "RecentSearchMgr.h"
#import "SavedSearchMgr.h"
#import "ArbUserTimelineDataSource.h"
#import "UserListDisplayMgrFactory.h"
#import "TwitchWebBrowserDisplayMgr.h"
#import "PhotoBrowserDisplayMgr.h"
#import "SettingsReader.h"
#import "UIApplication+ConfigurationAdditions.h"
#import "NSArray+IterationAdditions.h"
#import "TwitbitShared.h"
#import "ListsViewController.h"
#import "ErrorState.h"
#import "UserTwitterList.h"
#import "ContactCachePersistenceStore.h"
#import "TrendDisplayMgr.h"
#import "TrendsViewController.h"
#import "Tweet+CoreDataAdditions.h"
#import "DirectMessage+CoreDataAdditions.h"
#import "PushNotificationMessage.h"

@interface TwitchAppDelegate ()

@property (nonatomic, retain) OauthLogInDisplayMgr * logInDisplayMgr;
@property (nonatomic, retain) ComposeTweetDisplayMgr * composeTweetDisplayMgr;
@property (nonatomic, retain) DeviceRegistrar * registrar;
@property (nonatomic, retain) NSMutableArray * credentials;
@property (nonatomic, retain) ActiveTwitterCredentials *
    activeCredentials;

@property (nonatomic, retain) InstapaperService * instapaperService;
@property (nonatomic, copy) NSString * savingInstapaperUrl;
@property (nonatomic, retain) InstapaperLogInDisplayMgr *
    instapaperLogInDisplayMgr;

- (void)initHomeTab;
- (void)initMentionsTab;
- (void)initMessagesTab;
- (void)initFindPeopleTab;
- (void)initProfileTab;
- (void)initAccountsView;
- (void)initSearchTab;
- (void)initListsTab;
- (void)initTrendsTab;
- (UINavigationController *)getNavControllerForController:(UIViewController *)c;

- (UIBarButtonItem *)newTweetButtonItem;
- (UIBarButtonItem *)homeSendingTweetProgressView;
- (UIBarButtonItem *)mentionsSendingTweetProgressView;
- (UIBarButtonItem *)listsSendingTweetProgressView;

- (void)broadcastActivatedCredentialsChanged:(TwitterCredentials *)tc;

- (void)registerDeviceForPushNotifications;
- (NSDictionary *)deviceRegistrationArgsForCredentials:(NSArray *)credentials;

- (BOOL)saveContext;
- (void)prunePersistenceStore;
- (void)loadHomeViewWithCachedData:(TwitterCredentials *)account;
- (void)loadMentionsViewWithCachedData:(TwitterCredentials *)account;
- (void)loadMessagesViewWithCachedData:(TwitterCredentials *)account;
- (void)setUIStateFromPersistenceAndNotification:(NSDictionary *)notification;
- (void)updateUIStateWithNotification:(NSDictionary *)notification
    mentionTabLocation:(NSInteger)mentionTabLocation
    messageTabLocation:(NSInteger)messageTabLocation;
- (void)persistUIState;
- (void)setSelectedTabFromPersistence;
- (NSUInteger)originalTabIndexForIndex:(NSUInteger)index;

- (void)finishInitializationWithTimeInsensitiveOperations;

- (void)showAccountsView;
- (void)setTimelineTitleView;
- (void)processUserAccountSelection;

- (void)initTabForViewController:(UIViewController *)viewController;

- (void)activateAccountWithName:(NSString *)accountName;
- (void)processAccountChange:(TwitterCredentials *)activeAccount;

- (void)popAllTabsToRoot;

+ (NSInteger)mentionsTabBarItemTag;
+ (NSInteger)messagesTabBarItemTag;

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
@synthesize tabBarController;
@synthesize logInDisplayMgr;
@synthesize composeTweetDisplayMgr;
@synthesize registrar;
@synthesize credentials;
@synthesize activeCredentials;
@synthesize instapaperService;
@synthesize savingInstapaperUrl;
@synthesize instapaperLogInDisplayMgr;

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
    [accountSettingsChangedPublisher release];

    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];

    [homeNetAwareViewController release];
    [mentionsNetAwareViewController release];
    [messagesNetAwareViewController release];
    [searchNetAwareViewController release];
    [findPeopleNetAwareViewController release];
    [listsNetAwareViewController release];
    [trendsNetAwareViewController release];
    [profileNetAwareViewController release];

    [contactCache release];
    [contactMgr release];

    [accountsButton release];
    [accountsButtonSetter release];
    [accountsNavController release];
    [accountsViewController release];

    [timelineDisplayMgrFactory release];
    [directMessageDisplayMgrFactory release];
    [timelineDisplayMgr release];
    [directMessageDisplayMgr release];
    [directMessageAcctMgr release];
    [mentionsAcctMgr release];
    [mentionDisplayMgr release];
    [listsDisplayMgr release];
    [trendDisplayMgr release];
    [trendsViewController release];
    [profileDisplayMgr release];

    [composeTweetDisplayMgr release];

    [findPeopleSearchDisplayMgr release];
    [accountsDisplayMgr release];

    [homeSendingTweetProgressView release];
    [mentionsSendingTweetProgressView release];
    [listsSendingTweetProgressView release];

    [findPeopleBookmarkMgr release];

    [instapaperService release];
    [savingInstapaperUrl release];
    [instapaperLogInDisplayMgr release];

    [uiState release];

    [super dealloc];
}

#pragma mark UIApplicationDelegate implementation

- (void)processApplicationLaunch:(UIApplication *)application
          withRemoteNotification:(NSDictionary *)notification
{
    if ([SettingsReader displayTheme] == kDisplayThemeDark) {
        UINavigationController * moreNavController =
            tabBarController.moreNavigationController;
        moreNavController.navigationBar.barStyle = UIBarStyleBlackOpaque;
        [application setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
    } else
        [application setStatusBarStyle:UIStatusBarStyleDefault animated:NO];

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
    [window addSubview:tabBarController.view];

    contactCache = [[ContactCache alloc] init];
    contactMgr =
        [[ContactMgr alloc]
        initWithTabBarController:tabBarController
        contactCacheSetter:contactCache];

    findPeopleBookmarkMgr =
        [[SavedSearchMgr alloc] initWithAccountName:@"saved.people"
        context:[self managedObjectContext]];
    timelineDisplayMgrFactory =
        [[TimelineDisplayMgrFactory alloc]
        initWithContext:[self managedObjectContext]
        findPeopleBookmarkMgr:findPeopleBookmarkMgr contactCache:contactCache
        contactMgr:contactMgr];
    directMessageDisplayMgrFactory =
        [[DirectMessageDisplayMgrFactory alloc]
        initWithContext:[self managedObjectContext]
        findPeopleBookmarkMgr:findPeopleBookmarkMgr contactCache:contactCache
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
    }

    [self setUIStateFromPersistenceAndNotification:notification];

    [self performSelector:
        @selector(finishInitializationWithTimeInsensitiveOperations)
        withObject:nil
        afterDelay:0.6];

    accountsButton.action = @selector(showAccountsView);

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

    [self processApplicationLaunch:application
            withRemoteNotification:remoteNotification];

    return YES;
}

- (void)finishInitializationWithTimeInsensitiveOperations
{
    [self registerDeviceForPushNotifications];

    TwitchWebBrowserDisplayMgr * webDispMgr =
        [TwitchWebBrowserDisplayMgr instance];
    if (!webDispMgr.delegate) {
        webDispMgr.composeTweetDisplayMgr = self.composeTweetDisplayMgr;
        webDispMgr.hostViewController = tabBarController;
        webDispMgr.delegate = self;
    }

    PhotoBrowserDisplayMgr * photoBrowserDispMgr =
        [PhotoBrowserDisplayMgr instance];
    photoBrowserDispMgr.composeTweetDisplayMgr = self.composeTweetDisplayMgr;
    photoBrowserDispMgr.hostViewController = tabBarController;

    if (!directMessageDisplayMgr)
        [self initMessagesTab];
    if (!mentionDisplayMgr)
        [self initMentionsTab];

    TwitterCredentials * c = self.activeCredentials.credentials;
    if (c) {
        [directMessageDisplayMgr updateDirectMessagesSinceLastUpdateIds];
        [mentionDisplayMgr updateMentionsSinceLastUpdateIds];
    }

    if ([SettingsReader displayTheme] == kDisplayThemeDark)
        window.backgroundColor = [UIColor blackColor];

    // Ensure 'more' tab has all sub-tabs initialized if started on a tab under
    // 'more'
    if (tabBarController.selectedIndex > 3) {
        UINavigationController * moreController =
            tabBarController.moreNavigationController;
        [self initTabForViewController:moreController];
    }

    ContactCachePersistenceStore * contactCachePersistenceStore =
        [[[ContactCachePersistenceStore alloc]
        initWithContactCache:contactCache] autorelease];
    [contactCachePersistenceStore load];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self persistUIState];

    if (managedObjectContext != nil) {
        [self prunePersistenceStore];
        if (![self saveContext]) {
            NSLog(@"Failed to save state on application shutdown.");
            exit(-1);
        }
    }
}

#pragma mark Composing tweets

- (IBAction)composeTweet:(id)sender
{
    [self.composeTweetDisplayMgr composeTweetAnimated:YES];
}

#pragma mark ComposeTweetDisplayMgrDelegate implementation

- (void)userDidCancelComposingTweet
{
}

- (void)userIsSendingTweet:(NSString *)tweet
{
    NSLog(@"User is sending tweet...");
    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self homeSendingTweetProgressView]
        animated:YES];
    [mentionsNetAwareViewController.navigationItem
        setRightBarButtonItem:[self mentionsSendingTweetProgressView]
        animated:YES];
    [listsNetAwareViewController.navigationItem
        setRightBarButtonItem:[self listsSendingTweetProgressView]
        animated:YES];
}

- (void)userDidSendTweet:(Tweet *)tweet
{
    NSLog(@"User did send tweet...");
    [timelineDisplayMgr addTweet:tweet];

    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self newTweetButtonItem]
        animated:YES];
    [mentionsNetAwareViewController.navigationItem
        setRightBarButtonItem:[self newTweetButtonItem]
        animated:YES];
    [listsNetAwareViewController.navigationItem
        setRightBarButtonItem:[self newTweetButtonItem]
        animated:YES];
}

- (void)userFailedToSendTweet:(NSString *)tweet
{
    [homeNetAwareViewController.navigationItem
        setRightBarButtonItem:[self newTweetButtonItem]
        animated:YES];
    [mentionsNetAwareViewController.navigationItem
        setRightBarButtonItem:[self newTweetButtonItem]
        animated:YES];
    [listsNetAwareViewController.navigationItem
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
    [directMessageDisplayMgr updateDisplayForSendingDirectMessage];
}

- (void)userDidSendDirectMessage:(DirectMessage *)dm
{
    NSLog(@"Twitch app delegate: sent direct message");
    [directMessageDisplayMgr addDirectMessage:dm];
}

- (void)userFailedToSendDirectMessage:(NSString *)dm to:(NSString *)username
{
    NSLog(@"Twitch app delegate: failed to send direct message");
    [directMessageDisplayMgr updateDisplayForFailedDirectMessage:username];

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
    NSLog(@"Initializing home tab");

    homeNetAwareViewController.navigationController.navigationBar.barStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIBarStyleBlackOpaque : UIBarStyleDefault;

    UINavigationController * navController =
        [self getNavControllerForController:homeNetAwareViewController];

    NSString * homeTabTitle =
        NSLocalizedString(@"appdelegate.hometabtitle", @"");
    timelineDisplayMgr =
        [[timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        homeNetAwareViewController
        navigationController:navController
        title:homeTabTitle
        composeTweetDisplayMgr:self.composeTweetDisplayMgr]
        retain];
    timelineDisplayMgr.displayAsConversation = YES;
    timelineDisplayMgr.showMentions = YES;

    if ([uiState.tabOrder
        indexOfObject:[NSNumber numberWithInt:kOriginalTabOrderTimeline]] > 3)
        timelineDisplayMgr.refreshButton = nil;
    else {
        UIBarButtonItem * refreshButton =
            homeNetAwareViewController.navigationItem.leftBarButtonItem;
        refreshButton.target = timelineDisplayMgr;
        refreshButton.action = @selector(refreshWithLatest);
        timelineDisplayMgr.refreshButton = refreshButton;
    }

    TwitterCredentials * c = self.activeCredentials.credentials;
    if (c) {
        [timelineDisplayMgr setCredentials:c];
        [self loadHomeViewWithCachedData:c];

        [self setTimelineTitleView];
    }
}

- (void)setTimelineTitleView
{
    if (!accountsButtonSetter) {
        TwitterService * service =
            [[[TwitterService alloc] initWithTwitterCredentials:nil
            context:[self managedObjectContext]]
            autorelease];

        // Don't autorelease
        [[CredentialsActivatedPublisher alloc]
            initWithListener:service action:@selector(setCredentials:)];

        accountsButtonSetter =
            [[AccountsButtonSetter alloc]
            initWithAccountsButton:accountsButton
            twitterService:service
            context:[self managedObjectContext]];
        service.delegate = accountsButtonSetter;
    }

    TwitterCredentials * c = self.activeCredentials.credentials;
    [accountsButtonSetter setButtonWithUsername:c.username];
}

- (void)initMessagesTab
{
    messagesNetAwareViewController.navigationController.navigationBar.barStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIBarStyleBlackOpaque : UIBarStyleDefault;

    directMessageDisplayMgr =
        [[directMessageDisplayMgrFactory
        createDirectMessageDisplayMgrWithWrapperController:
        messagesNetAwareViewController
        composeTweetDisplayMgr:self.composeTweetDisplayMgr
        timelineDisplayMgrFactory:timelineDisplayMgrFactory]
        retain];

    if ([uiState.tabOrder
        indexOfObject:[NSNumber numberWithInt:kOriginalTabOrderMessages]] > 3)
        directMessageDisplayMgr.refreshButton = nil;

    directMessageAcctMgr =
        [[DirectMessageAcctMgr alloc]
        initWithDirectMessagesDisplayMgr:directMessageDisplayMgr];

    TwitterCredentials * c = self.activeCredentials.credentials;
    [directMessageDisplayMgr setCredentials:c];
    [self loadMessagesViewWithCachedData:c];

    NewDirectMessagesPersistenceStore * newDirectMessagesPersistenceStore =
        [[[NewDirectMessagesPersistenceStore alloc] init] autorelease];
    directMessageDisplayMgr.newDirectMessagesState =
        [newDirectMessagesPersistenceStore load];
    [directMessageAcctMgr setWithDirectMessageCountsByAccount:
        [newDirectMessagesPersistenceStore loadNewMessageCountsForAllAccounts]];
}

- (void)initMentionsTab
{
    mentionsNetAwareViewController.navigationController.navigationBar.barStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIBarStyleBlackOpaque : UIBarStyleDefault;

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
        findPeopleBookmarkMgr:findPeopleBookmarkMgr contactCache:contactCache
        contactMgr:contactMgr]
        autorelease];

    UINavigationController * navController =
        [self getNavControllerForController:mentionsNetAwareViewController];

    UITabBarItem * tabBarItem =
        mentionsNetAwareViewController.parentViewController.tabBarItem;
    mentionDisplayMgr =
        [[MentionTimelineDisplayMgr alloc]
        initWithWrapperController:mentionsNetAwareViewController
        navigationController:navController
        timelineController:timelineController
        service:service
        factory:timelineDisplayMgrFactory
        managedObjectContext:[self managedObjectContext]
        composeTweetDisplayMgr:self.composeTweetDisplayMgr
        findPeopleBookmarkMgr:findPeopleBookmarkMgr
        userListDisplayMgrFactory:userListDisplayMgrFactory
        tabBarItem:tabBarItem contactCache:contactCache contactMgr:contactMgr];
    service.delegate = mentionDisplayMgr;
    timelineController.delegate = mentionDisplayMgr;
    mentionsNetAwareViewController.delegate = mentionDisplayMgr;

    mentionsAcctMgr =
        [[MentionsAcctMgr alloc]
        initWithMentionTimelineDisplayMgr:mentionDisplayMgr];

    mentionDisplayMgr.numNewMentions = uiState.numNewMentions;

    if ([uiState.tabOrder
        indexOfObject:[NSNumber numberWithInt:kOriginalTabOrderMentions]] > 3)
        mentionDisplayMgr.refreshButton = nil;
    else {
        UIBarButtonItem * refreshButton =
            mentionsNetAwareViewController.navigationItem.leftBarButtonItem;
        refreshButton.target = mentionDisplayMgr;
        refreshButton.action = @selector(refreshWithLatest);
        mentionDisplayMgr.refreshButton = refreshButton;
    }

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:mentionDisplayMgr action:@selector(setCredentials:)];

    TwitterCredentials * c = self.activeCredentials.credentials;
    if (c) {
        AccountSettings * settings =
            [AccountSettings settingsForKey:c.username];
        mentionDisplayMgr.showBadge = [settings pushMentions];

        [mentionDisplayMgr setCredentials:c];
        [self loadMentionsViewWithCachedData:c];
    }
}

- (void)initFindPeopleTab
{
    findPeopleNetAwareViewController.navigationController.navigationBar.
        barStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIBarStyleBlackOpaque : UIBarStyleDefault;

    UIBarButtonItem * refreshButton =
        findPeopleNetAwareViewController.navigationItem.leftBarButtonItem;
    refreshButton.action = @selector(refreshWithLatest);

    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:[self managedObjectContext]]
        autorelease];

    UserListTableViewController * userListController =
        [[[UserListTableViewController alloc]
        initWithNibName:@"UserListTableView" bundle:nil] autorelease];
    findPeopleNetAwareViewController.targetViewController = userListController;

    UserListDisplayMgrFactory * userListFactory =
        [[[UserListDisplayMgrFactory alloc]
        initWithContext:[self managedObjectContext]
        findPeopleBookmarkMgr:findPeopleBookmarkMgr contactCache:contactCache
        contactMgr:contactMgr]
        autorelease];

    UINavigationController * navController =
        [self getNavControllerForController:findPeopleNetAwareViewController];

    findPeopleSearchDisplayMgr =
        [[FindPeopleSearchDisplayMgr alloc]
        initWithNetAwareController:findPeopleNetAwareViewController
        navigationController:navController
        userListController:userListController
        service:twitterService
        context:[self managedObjectContext]
        savedSearchMgr:findPeopleBookmarkMgr
        composeTweetDisplayMgr:composeTweetDisplayMgr
        timelineFactory:timelineDisplayMgrFactory
        userListFactory:userListFactory
        findPeopleBookmarkMgr:findPeopleBookmarkMgr
        contactCache:contactCache
        contactMgr:contactMgr];

    findPeopleNetAwareViewController.delegate = findPeopleSearchDisplayMgr;
    twitterService.delegate = findPeopleSearchDisplayMgr;
    userListController.delegate = findPeopleSearchDisplayMgr;

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:findPeopleSearchDisplayMgr
        action:@selector(setCredentials:)];

    [findPeopleSearchDisplayMgr
        setCredentials:self.activeCredentials.credentials];

    [findPeopleSearchDisplayMgr
        setSelectedBookmarkSegment:uiState.selectedPeopleBookmarkIndex];

    findPeopleSearchDisplayMgr.currentSearchUsername = uiState.findPeopleText;
}

- (void)initProfileTab
{
    NSLog(@"Initializing profile tab");

    profileNetAwareViewController.navigationController.navigationBar.barStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIBarStyleBlackOpaque : UIBarStyleDefault;

    UserInfoViewController * profileViewController =
        [[[UserInfoViewController alloc]
        initWithNibName:@"UserInfoView" bundle:nil] autorelease];
    profileNetAwareViewController.targetViewController = profileViewController;
    profileViewController.findPeopleBookmarkMgr = findPeopleBookmarkMgr;
    profileViewController.contactCacheReader = contactCache;
    profileViewController.contactMgr = contactMgr;

    TwitterCredentials * creds =
        self.activeCredentials ? self.activeCredentials.credentials : nil;

    TwitterService * service =
        [[[TwitterService alloc]
        initWithTwitterCredentials:creds
        context:[self managedObjectContext]] autorelease];

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:service action:@selector(setCredentials:)];

    UINavigationController * navController =
        [self getNavControllerForController:profileNetAwareViewController];

    UserListDisplayMgrFactory * userListFactory =
        [[[UserListDisplayMgrFactory alloc]
        initWithContext:[self managedObjectContext]
        findPeopleBookmarkMgr:findPeopleBookmarkMgr contactCache:contactCache
        contactMgr:contactMgr]
        autorelease];

    profileDisplayMgr =
        [[ProfileDisplayMgr alloc]
        initWithNetAwareController:profileNetAwareViewController
        userInfoController:profileViewController
        service:service context:[self managedObjectContext]
        composeTweetDisplayMgr:composeTweetDisplayMgr
        timelineFactory:timelineDisplayMgrFactory
        userListFactory:userListFactory
        navigationController:navController];
    service.delegate = profileDisplayMgr;
    profileNetAwareViewController.delegate = profileDisplayMgr;
    profileViewController.delegate = profileDisplayMgr;

    [profileDisplayMgr setCredentials:creds];
    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:profileDisplayMgr action:@selector(setCredentials:)];

    if ([uiState.tabOrder
        indexOfObject:[NSNumber numberWithInt:kOriginalTabOrderProfile]] > 3)
        profileDisplayMgr.refreshButton = nil;
    else {
        UIBarButtonItem * refreshButton =
            profileNetAwareViewController.navigationItem.leftBarButtonItem;
        refreshButton.target = profileDisplayMgr;
        refreshButton.action = @selector(refreshProfile);
        profileDisplayMgr.refreshButton = refreshButton;
    }

    if (creds) {
        User * user =
            [User userWithUsername:creds.username
            context:[self managedObjectContext]];
        [profileDisplayMgr setNewProfileUsername:creds.username user:user];
    }
}

- (void)initSearchTab
{
    searchNetAwareViewController.navigationController.navigationBar.barStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIBarStyleBlackOpaque : UIBarStyleDefault;

    TwitterService * searchService =
        [[[TwitterService alloc]
        initWithTwitterCredentials:nil
                           context:[self managedObjectContext]] autorelease];

    UINavigationController * navController =
        [self getNavControllerForController:searchNetAwareViewController];

     searchBarTimelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        searchNetAwareViewController
        navigationController:navController
        title:@"Search"  // set programmatically later
        composeTweetDisplayMgr:self.composeTweetDisplayMgr];
    searchNetAwareViewController.delegate = searchBarTimelineDisplayMgr;

    searchBarDisplayMgr =
        [[SearchBarDisplayMgr alloc]
        initWithTwitterService:searchService
            netAwareController:searchNetAwareViewController
            timelineDisplayMgr:searchBarTimelineDisplayMgr
                       context:[self managedObjectContext]];
    searchNetAwareViewController.delegate = searchBarDisplayMgr;

    [searchBarDisplayMgr setCredentials:self.activeCredentials.credentials];
    
    [searchBarDisplayMgr
        setSelectedBookmarkSegment:uiState.selectedSearchBookmarkIndex];

    searchBarDisplayMgr.searchQuery = uiState.searchText;
    searchBarDisplayMgr.nearbySearch = uiState.nearbySearch;
    [searchBarDisplayMgr searchBarViewWillAppear:NO];
}

- (void)initListsTab
{
    NSLog(@"Initializing lists tab");

    listsNetAwareViewController.navigationController.navigationBar.barStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIBarStyleBlackOpaque : UIBarStyleDefault;

    ListsViewController * listsViewController =
        [[ListsViewController alloc] init];
    listsNetAwareViewController.targetViewController = listsViewController;

    TwitterCredentials * creds =
        self.activeCredentials ? self.activeCredentials.credentials : nil;

    TwitterService * service =
        [[[TwitterService alloc]
        initWithTwitterCredentials:creds
        context:[self managedObjectContext]] autorelease];

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:service action:@selector(setCredentials:)];

    UINavigationController * navController =
        [self getNavControllerForController:listsNetAwareViewController];

    listsDisplayMgr =
        [[ListsDisplayMgr alloc]
        initWithWrapperController:listsNetAwareViewController
        navigationController:navController
        listsViewController:listsViewController
        service:service
        factory:timelineDisplayMgrFactory
        composeTweetDisplayMgr:self.composeTweetDisplayMgr
        context:[self managedObjectContext]];
    service.delegate = listsDisplayMgr;
    listsNetAwareViewController.delegate = listsDisplayMgr;
    listsViewController.delegate = listsDisplayMgr;

    [listsDisplayMgr setCredentials:creds];
    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:listsDisplayMgr action:@selector(setCredentials:)];

    if ([uiState.tabOrder
        indexOfObject:[NSNumber numberWithInt:kOriginalTabOrderLists]] > 3)
        listsDisplayMgr.refreshButton = nil;
    else {
        UIBarButtonItem * refreshButton =
            listsNetAwareViewController.navigationItem.leftBarButtonItem;
        refreshButton.target = listsDisplayMgr;
        refreshButton.action = @selector(refreshLists);
        listsDisplayMgr.refreshButton = refreshButton;
    }

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

- (void)initTrendsTab
{
    NSLog(@"Initializing trends tab");

    trendsNetAwareViewController.navigationController.navigationBar.barStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIBarStyleBlackOpaque : UIBarStyleDefault;

    trendsViewController =
        [[TrendsViewController alloc] initWithNibName:@"TrendsView" bundle:nil];
    trendsNetAwareViewController.targetViewController = trendsViewController;
    trendsViewController.netController = trendsNetAwareViewController;

    TwitterCredentials * creds = self.activeCredentials.credentials;
    TwitterService * trendService =
        [[[TwitterService alloc] initWithTwitterCredentials:creds
        context:[self managedObjectContext]]
        autorelease];

    SearchDisplayMgr * searchMgr =
        [[SearchDisplayMgr alloc]
        initWithTwitterService:trendService];

    NetworkAwareViewController * navc =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    UINavigationController * nc =
        [self getNavControllerForController:trendsNetAwareViewController];

    TimelineDisplayMgr * timelineMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:navc
        navigationController:nc
        title:@"Trends"  // set programmatically later
        composeTweetDisplayMgr:self.composeTweetDisplayMgr];
    [timelineMgr setCredentials:creds];
    navc.delegate = timelineMgr;

    searchMgr.dataSourceDelegate = timelineMgr;

    // don't release
    [[CredentialsActivatedPublisher alloc]
        initWithListener:timelineMgr action:@selector(setCredentials:)];

    trendDisplayMgr =
        [[TrendDisplayMgr alloc] initWithSearchDisplayMgr:searchMgr
                                    navigationController:nc
                                       timelineDisplayMgr:timelineMgr];

    trendsViewController.selectionTarget = trendDisplayMgr;
    trendsViewController.selectionAction = @selector(displayTrend:);

    trendsViewController.explanationTarget = trendDisplayMgr;
    trendsViewController.explanationAction =
        @selector(displayExplanationForTrend:);
}

- (UINavigationController *)getNavControllerForController:(UIViewController *)c
{
    BOOL onMoreTab = NO;
    NSArray * viewControllers = tabBarController.viewControllers;
    for (NSInteger i = 4; i < [viewControllers count]; i++) {
        UIViewController * vc = [viewControllers objectAtIndex:i];
        if (vc == c.navigationController) {
            onMoreTab = YES;
            break;
        }
    }
    return onMoreTab ?
        tabBarController.moreNavigationController :
        c.navigationController;
}

- (void)initAccountsView
{
    accountsViewController = [[AccountsViewController alloc] init];

    accountsNavController =
        [[UINavigationController alloc]
        initWithRootViewController:accountsViewController];
    accountsViewController.navigationController.navigationBar.barStyle =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        UIBarStyleBlackOpaque : UIBarStyleDefault;
    accountsViewController.selectedAccountTarget = self;
    accountsViewController.selectedAccountAction =
        @selector(processUserAccountSelection);

    OauthLogInDisplayMgr * displayMgr =
        [[OauthLogInDisplayMgr alloc]
        initWithRootViewController:tabBarController
        managedObjectContext:[self managedObjectContext]];
    displayMgr.navigationController = accountsNavController;

    accountsDisplayMgr =
        [[AccountsDisplayMgr alloc]
        initWithAccountsViewController:accountsViewController
        logInDisplayMgr:displayMgr
        context:[self managedObjectContext]];

    UIBarButtonItem * doneButton =
        [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
        action:@selector(processUserAccountSelection)]
        autorelease];
    accountsViewController.navigationItem.rightBarButtonItem = doneButton;
    accountsViewController.navigationItem.title =
        NSLocalizedString(@"account.title", @"");

    [displayMgr release];
}

#pragma mark UITabBarControllerDelegate implementation

- (BOOL)tabBarController:(UITabBarController *)tbc
    shouldSelectViewController:(UIViewController *)viewController
{
    if (viewController == tbc.selectedViewController)  // not switching tabs
        return YES;

    if (viewController == searchNetAwareViewController.navigationController)
        [searchBarDisplayMgr searchBarViewWillAppear:NO];

    return YES;
}

- (void)tabBarController:(UITabBarController *)tbc
    didSelectViewController:(UIViewController *)viewController
{
    [self initTabForViewController:viewController];
}

- (void)tabBarController:(UITabBarController *)tbc
    didEndCustomizingViewControllers:(NSArray *)viewControllers
    changed:(BOOL)changed
{
    NSLog(@"Tab bar controller finished customizing view controllers");
    if (changed) {
        [self initTabForViewController:
            tabBarController.moreNavigationController];

        [self popAllTabsToRoot];

        timelineDisplayMgr.navigationController =
            [self getNavControllerForController:homeNetAwareViewController];
        mentionDisplayMgr.navigationController =
            [self getNavControllerForController:mentionsNetAwareViewController];
        searchBarTimelineDisplayMgr.navigationController =
            [self getNavControllerForController:searchNetAwareViewController];
        listsDisplayMgr.navigationController =
            [self getNavControllerForController:listsNetAwareViewController];
        profileDisplayMgr.navigationController =
            [self getNavControllerForController:profileNetAwareViewController];
        [findPeopleSearchDisplayMgr setNavigationController:
            [self getNavControllerForController:
            findPeopleNetAwareViewController]];
        trendDisplayMgr.navigationController =
            [self getNavControllerForController:trendsNetAwareViewController];
    }
}

- (void)popAllTabsToRoot
{
    [homeNetAwareViewController.navigationController
        popToRootViewControllerAnimated:NO];
    [mentionsNetAwareViewController.navigationController
        popToRootViewControllerAnimated:NO];
    [messagesNetAwareViewController.navigationController
        popToRootViewControllerAnimated:NO];
    [listsNetAwareViewController.navigationController
        popToRootViewControllerAnimated:NO];
    [searchNetAwareViewController.navigationController
        popToRootViewControllerAnimated:NO];
    [findPeopleNetAwareViewController.navigationController
        popToRootViewControllerAnimated:NO];
    [trendsNetAwareViewController.navigationController
        popToRootViewControllerAnimated:NO];
    [profileNetAwareViewController.navigationController
        popToRootViewControllerAnimated:NO];
}

- (void)initTabForViewController:(UIViewController *)viewController
{
    if (viewController == homeNetAwareViewController.navigationController &&
        !timelineDisplayMgr) {
        NSLog(@"Selected home tab");
        [self initHomeTab];
    } else if (viewController ==
        mentionsNetAwareViewController.navigationController &&
        !mentionDisplayMgr) {
        NSLog(@"Selected mentions tab");
        [self initMentionsTab];
    } else if (viewController ==
        messagesNetAwareViewController.navigationController &&
        !directMessageDisplayMgr) {
        NSLog(@"Selected direct messages tab");
        [self initMessagesTab];
    } else if (viewController ==
        findPeopleNetAwareViewController.navigationController &&
        !findPeopleSearchDisplayMgr) {
        NSLog(@"Selected people tab");
        [self initFindPeopleTab];
    } else if (viewController ==
        searchNetAwareViewController.navigationController &&
        !searchBarDisplayMgr) {
        NSLog(@"Selected search tab");
        [self initSearchTab];
    } else if (viewController ==
        listsNetAwareViewController.navigationController &&
        !listsDisplayMgr) {
        NSLog(@"Selected lists tab");
        [self initListsTab];
    } else if (viewController ==
        trendsNetAwareViewController.navigationController &&
        !trendsViewController) {
        NSLog(@"Selected trends tab");
        [self initTrendsTab];
    } else if (viewController ==
        profileNetAwareViewController.navigationController &&
        !profileDisplayMgr) {
        NSLog(@"Selected profile tab");
        [self initProfileTab];
    } else if (viewController == tabBarController.moreNavigationController) {
        NSLog(@"Selected more tab; initializing everything under 'More'");
        [self performSelector:@selector(initTabsUnderMore) withObject:nil
            afterDelay:0];
    }
}

- (void)initTabsUnderMore
{
    NSArray * viewControllers = tabBarController.viewControllers;
    for (NSInteger i = 4; i < [viewControllers count]; i++) {
        UIViewController * vc = [viewControllers objectAtIndex:i];
        [self initTabForViewController:vc];
    }
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

    [directMessageDisplayMgr updateDirectMessagesSinceLastUpdateIds];
    [mentionDisplayMgr updateMentionsSinceLastUpdateIds];
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

        [args setObject:c.username forKey:usernameKey];
        [args setObject:c.key forKey:keyKey];
        [args setObject:c.secret forKey:secretKey];
        [args setObject:[settings pushSettings] forKey:configKey];
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

#pragma mark Push notification helpers

- (void)registerDeviceForPushNotifications
{
    if (![[UIApplication sharedApplication] isLiteVersion]) {
        UIRemoteNotificationType notificationTypes =
        (UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeSound |
        UIRemoteNotificationTypeAlert);

        [[UIApplication sharedApplication]
            registerForRemoteNotificationTypes:notificationTypes];
    }
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

- (void)credentialsSetChanged:(TwitterCredentials *)changedCredentials
                        added:(NSNumber *)added
{
    if ([added boolValue]) {
        if (self.credentials.count == 0) { // first credentials -- active them
            NSLog(@"Setting first credentials");
            [self broadcastActivatedCredentialsChanged:changedCredentials];

            [directMessageAcctMgr
                processAccountChangeToUsername:changedCredentials.username
                fromUsername:nil];
            [mentionsAcctMgr
                processAccountChangeToUsername:changedCredentials.username
                fromUsername:nil];

            // spread these calls out a bit
            [mentionDisplayMgr
                performSelector:
                @selector(updateMentionsAfterCredentialChange)
                withObject:nil
                afterDelay:2.0];
            [directMessageDisplayMgr
                performSelector:
                @selector(updateDirectMessagesAfterCredentialChange)
                withObject:nil
                afterDelay:4.0];

            [self setTimelineTitleView];
        }
        [self.credentials addObject:changedCredentials];
    } else {
        [TwitterCredentials
            deleteKeyAndSecretForUsername:changedCredentials.username];
        [self.credentials removeObject:changedCredentials];
        [directMessageAcctMgr
            processAccountRemovedForUsername:changedCredentials.username];
        [mentionsAcctMgr
            processAccountRemovedForUsername:changedCredentials.username];

        // remove bookmarks and recent searches
        RecentSearchMgr * recentSearches =
            [[RecentSearchMgr alloc]
            initWithAccountName:changedCredentials.username
                        context:[self managedObjectContext]];
        [recentSearches clear];
        [recentSearches release];

        SavedSearchMgr * savedSearches =
            [[SavedSearchMgr alloc]
            initWithAccountName:changedCredentials.username
                        context:[self managedObjectContext]];
        [savedSearches clear];
        [savedSearches release];
    }

    [self registerDeviceForPushNotifications];

    NSLog(@"Active credentials after account switch: '%@'.",
        self.activeCredentials.credentials.username);
    [self saveContext];
}

- (void)accountSettingsChanged:(AccountSettings *)settings
                    forAccount:(NSString *)account
{
    NSLog(@"Handling account settings change");
    [self registerDeviceForPushNotifications];
    if ([account isEqual:self.activeCredentials.credentials.username]) {
        NSLog(@"Setting 'show badge' value for mentions");
        mentionDisplayMgr.showBadge = [settings pushMentions];
    }
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

+ (NSInteger)messagesTabBarItemTag
{
    return 2;
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

    // all users bound to credentials will be spared
    for (TwitterCredentials * c in credentials)
        if (c.user)
            [sparedUsers addObject:c.user];

    // all users that own lists will be spared
    NSArray * allLists = [UserTwitterList findAll:context];
    for (UserTwitterList * list in allLists)
        [sparedUsers addObject:list.user];

    NSMutableDictionary * living =
        [NSMutableDictionary dictionaryWithCapacity:self.credentials.count];
    NSMutableSet * hitList =
        [NSMutableSet setWithCapacity:allTweets.count];

    // delete all 'un-owned' tweets -- everything that's not in the user's
    // timeline, a mention, or a dm
    for (Tweet * tweet in allTweets) {
        BOOL isOwned =
            [tweet isKindOfClass:[UserTweet class]] ||
            [tweet isKindOfClass:[Mention class]];
        if (!isOwned)
            [hitList addObject:tweet];
    }

    // only keep the last n tweets, mentions, and dms for each account
    const NSUInteger NUM_TWEETS_TO_KEEP = [SettingsReader fetchQuantity];
    static const NSUInteger NUM_DIRECT_MESSAGES_TO_KEEP = 500;

    // won't include deleted tweets
    allTweets =
        [[[Tweet findAll:context] sortedArrayUsingSelector:@selector(compare:)]
        arrayByReversingContents];

    NSMutableSet * sparedRetweets =
        [NSMutableSet setWithCapacity:allTweets.count];
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
        } else if ([t.retweets count] > 0) {
            c = nil;
            key = nil;
        }

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
            if (perTweetType.count < NUM_TWEETS_TO_KEEP) {
                [perTweetType addObject:t];  // it lives
                [sparedUsers addObject:t.user];

                if (t.retweet) {
                    [sparedRetweets addObject:t.retweet];
                    [sparedUsers addObject:t.retweet.user];
                }
            } else
                [hitList addObject:t];  // it dies
        }
    }

    // delete all unneeded tweets
    for (Tweet * tweet in hitList) {
        if (![sparedRetweets containsObject:tweet]) {
            NSLog(@"Deleting tweet: '%@': '%@'", tweet.user.username,
                tweet.text);
            [context deleteObject:tweet];
        }
    }

    // now do a similar routine for dms

    // all users involved in a direct message must be spared
    [living removeAllObjects];
    [hitList removeAllObjects];

    NSArray * allDms =
        [[[DirectMessage findAll:context]
        sortedArrayUsingSelector:@selector(compare:)] arrayByReversingContents];

    for (DirectMessage * dm in allDms) {
        TwitterCredentials * c = dm.credentials;

        NSMutableArray * perCredentials = [living objectForKey:c.username];
        if (!perCredentials) {
            perCredentials = [NSMutableArray array];
            [living setObject:perCredentials forKey:c.username];
        }

        if (perCredentials.count < NUM_DIRECT_MESSAGES_TO_KEEP) {
            [perCredentials addObject:dm];
            [sparedUsers addObject:dm.recipient];
            [sparedUsers addObject:dm.sender];
        } else
            [context deleteObject:dm];

    }

    // delete all unneeded users
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

    NSArray * paths = [NSArray arrayWithObjects:@"user", @"user.avatar", nil];
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

- (void)loadMessagesViewWithCachedData:(TwitterCredentials *)account
{
    NSLog(@"Loading cached direct messages for: '%@'.", account.username);

    // important to access the context via the accessor
    NSManagedObjectContext * context = [self managedObjectContext];

    NSPredicate * predicate = 
        [NSPredicate predicateWithFormat:@"credentials.username == %@",
        account.username];

    NSArray * allDms = [DirectMessage findAll:predicate context:context];
    NSNumber * largestSentId = [NSNumber numberWithLongLong:0];
    NSNumber * largestRecvdId = [NSNumber numberWithLongLong:0];

    NSMutableArray * recvdDms = [NSMutableArray arrayWithCapacity:allDms.count];
    NSMutableArray * sentDms = [NSMutableArray arrayWithCapacity:allDms.count];

    for (DirectMessage * dm in allDms) {
        if ([account.username isEqualToString:dm.recipient.username]) {
            [recvdDms addObject:dm];

            if ([largestRecvdId longLongValue] < [dm.identifier longLongValue])
                largestRecvdId =
                    [NSNumber numberWithLongLong:[dm.identifier longLongValue]];
        } else if ([account.username isEqualToString:dm.sender.username]) {
            [sentDms addObject:dm];

            if ([largestSentId longLongValue] < [dm.identifier longLongValue])
                largestSentId =
                    [NSNumber numberWithLongLong:[dm.identifier longLongValue]];
        } else
            NSLog(@"Warning: this direct message doesn't belong to '%@': '%@'.",
                account, dm);
    }

    NSLog(@"Loading direct messages from persistence:");
    NSLog(@"\tSent up to %@:", largestSentId);
    NSLog(@"\tReceived up to %@:", largestRecvdId);

    DirectMessageCache * cache = [[DirectMessageCache alloc] init];

    if ([largestRecvdId longLongValue] == 0)
        cache.receivedUpdateId = nil;
    else
        cache.receivedUpdateId = largestRecvdId;

    if ([largestSentId longLongValue] == 0)
        cache.sentUpdateId = nil;
    else
        cache.sentUpdateId = largestSentId;

    [cache addReceivedDirectMessages:recvdDms];
    [cache addSentDirectMessages:sentDms];

    directMessageDisplayMgr.directMessageCache = cache;

    [cache release];
}

- (void)setUIStateFromPersistenceAndNotification:(NSDictionary *)notification
{
    UIStatePersistenceStore * uiStatePersistenceStore =
        [[[UIStatePersistenceStore alloc] init] autorelease];
    uiState = [[uiStatePersistenceStore load] retain];

    NSMutableArray * viewControllers = [NSMutableArray array];
    [viewControllers addObjectsFromArray:tabBarController.viewControllers];

    // HACK: Fixing a bug when upgrading from Twitbit 2.2 to 2.3 where we added
    // a tab. The tab order set in MainWindow.xib is not honored because the tab
    // order read from persistence, which is the 2.2 default since tabs could
    // not be reordered in that version, does not include the new lists tab. At
    // least when upgrading from 2.2 to 2.3, let's preserve the default order as
    // set in MainWindow. We may have to do something more intelligent in future
    // versions if we continue to add tabs.
    NSInteger mentionTabLocation = kOriginalTabOrderMentions;
    NSInteger messageTabLocation = kOriginalTabOrderMessages;
    if (uiState.tabOrder.count == viewControllers.count) {
        NSArray * tabOrder = uiState.tabOrder;
        if (tabOrder) {
            for (int i = [tabOrder count] - 1; i >= 0; i--) {
                NSNumber * tabNumber = [tabOrder objectAtIndex:i];
                NSInteger tabNumberAsInt = [tabNumber intValue];
                if (tabNumberAsInt == kOriginalTabOrderMentions)
                    mentionTabLocation = i;
                else if (tabNumberAsInt == kOriginalTabOrderMessages)
                    messageTabLocation = i;

                for (UIViewController * vc in tabBarController.viewControllers)
                    if (vc.tabBarItem.tag == tabNumberAsInt) {
                        [viewControllers removeObject:vc];
                        [viewControllers insertObject:vc atIndex:0];
                        break;
                    }
            }
        }
        tabBarController.viewControllers = viewControllers;
    }

    if (notification)
        [self updateUIStateWithNotification:notification
        mentionTabLocation:mentionTabLocation
        messageTabLocation:messageTabLocation];

    // HACK: see method for details
    [self performSelector:@selector(setSelectedTabFromPersistence)
        withObject:nil afterDelay:0.0];

    tabBarController.selectedIndex = uiState.selectedTab;

    if (uiState.composingTweet)
        [self.composeTweetDisplayMgr composeTweetAnimated:NO];
    else if (uiState.directMessageRecipient)
        [self.composeTweetDisplayMgr
            composeDirectMessageTo:uiState.directMessageRecipient animated:NO];

    if (uiState.viewingUrl) {
        TwitchWebBrowserDisplayMgr * webDispMgr =
            [TwitchWebBrowserDisplayMgr instance];
        webDispMgr.composeTweetDisplayMgr = self.composeTweetDisplayMgr;
        webDispMgr.hostViewController = tabBarController;
        webDispMgr.delegate = self;

        [webDispMgr visitWebpage:uiState.viewingUrl withHtml:nil animated:NO];
    }

    NSUInteger originalTabIndex =
        [self originalTabIndexForIndex:uiState.selectedTab];

    switch (originalTabIndex) {
        case kOriginalTabOrderTimeline:
            [self initHomeTab];
            if (uiState.currentlyViewedTweetId) {
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
            break;
        case kOriginalTabOrderMentions:
            [self initMentionsTab];
            if (uiState.currentlyViewedMentionId) {
                Tweet * mention =
                    [Tweet tweetWithId:uiState.currentlyViewedMentionId
                    context:[self managedObjectContext]];
                if (mention)
                    [mentionDisplayMgr pushTweetWithoutAnimation:mention];
                else
                    [mentionDisplayMgr
                        loadNewTweetWithId:uiState.currentlyViewedMentionId
                        username:nil animated:NO];
            }
            break;
        case kOriginalTabOrderMessages:
            [self initMessagesTab];
            if (uiState.currentlyViewedMessageId) {
                DirectMessage * dm =
                    [DirectMessage
                    directMessageWithId:uiState.currentlyViewedMessageId
                    context:[self managedObjectContext]];
                if (dm)
                    [directMessageDisplayMgr pushMessageWithoutAnimation:dm];
                else
                    [directMessageDisplayMgr
                        loadNewMessageWithId:uiState.currentlyViewedMessageId];
            }
            break;
        case kOriginalTabOrderLists:
            [self initListsTab];
            break;
        case kOriginalTabOrderSearch:
            [self initSearchTab];
            break;
        case kOriginalTabOrderPeople:
            [self initFindPeopleTab];
            break;
        case kOriginalTabOrderProfile:
            [self initProfileTab];
            break;
        case kOriginalTabOrderTrends:
            [self initTrendsTab];
            break;
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
            uiState.selectedTab = mentionTabLocation;
            uiState.currentlyViewedMentionId = pnm.messageId;
        } else {
            uiState.selectedTab = messageTabLocation;
            uiState.currentlyViewedMessageId = pnm.messageId;
        }

        NSString * account = pnm.accountUsername;
        NSPredicate * pred =
            [NSPredicate predicateWithFormat:@"SELF.username == %@", account];
        NSArray * creds =
            [credentials filteredArrayUsingPredicate:pred];

        if ([creds count] == 1) {
            NSString * currentUser = activeCredentials.credentials.username;
            if (![currentUser isEqualToString:account])
                [self activateAccountWithName:account];
        }
    }
}

- (NSUInteger)originalTabIndexForIndex:(NSUInteger)index
{
    UIViewController * viewController =
        [tabBarController.viewControllers objectAtIndex:index];

    return viewController.tabBarItem.tag;
}

// HACK: this forces tabs greater than 4 to be set properly (with a 'more' back
// button and without any noticable animation quirks)
- (void)setSelectedTabFromPersistence
{
    tabBarController.selectedIndex = 0;
    tabBarController.selectedIndex = uiState.selectedTab;
}

- (void)persistUIState
{
    UIStatePersistenceStore * uiStatePersistenceStore =
        [[[UIStatePersistenceStore alloc] init] autorelease];
    if (tabBarController.selectedIndex <= kOriginalTabOrderTrends)
        uiState.selectedTab = tabBarController.selectedIndex;
    else
        uiState.selectedTab = 0;

    NSMutableArray * tabOrder = [NSMutableArray array];
    for (UIViewController * viewController in tabBarController.viewControllers)
    {
        NSNumber * tagNumber =
            [NSNumber numberWithInt:viewController.tabBarItem.tag];
        [tabOrder addObject:tagNumber];
    }
    uiState.tabOrder = tabOrder;

    if (findPeopleSearchDisplayMgr) {
        uiState.findPeopleText =
            findPeopleSearchDisplayMgr.currentSearchUsername;
        uiState.selectedPeopleBookmarkIndex =
            [findPeopleSearchDisplayMgr selectedBookmarkSegment];
    }

    if (searchBarDisplayMgr) {
        uiState.searchText = searchBarDisplayMgr.searchQuery;
        uiState.nearbySearch = searchBarDisplayMgr.nearbySearch;
        uiState.selectedSearchBookmarkIndex =
            [searchBarDisplayMgr selectedBookmarkSegment];
    }

    NSUInteger numUnreadMentions = 0;
    if (mentionDisplayMgr) {
        numUnreadMentions = mentionDisplayMgr.numNewMentions;
        uiState.numNewMentions = numUnreadMentions;
    }

    uiState.composingTweet = self.composeTweetDisplayMgr.composingTweet;
    uiState.directMessageRecipient =
        self.composeTweetDisplayMgr.directMessageRecipient;

    TwitchWebBrowserDisplayMgr * webDispMgr =
        [TwitchWebBrowserDisplayMgr instance];
    uiState.viewingUrl = webDispMgr.currentUrl;

    uiState.currentlyViewedTweetId = timelineDisplayMgr.currentlyViewedTweetId;
    uiState.currentlyViewedMentionId = mentionDisplayMgr.currentlyViewedTweetId;
    uiState.currentlyViewedMessageId =
        directMessageDisplayMgr.currentlyViewedMessageId;

    [uiStatePersistenceStore save:uiState];

    NSUInteger numUnreadMessages = 0;
    if (directMessageDisplayMgr) {
        NewDirectMessagesPersistenceStore * newDirectMessagesPersistenceStore =
            [[[NewDirectMessagesPersistenceStore alloc] init] autorelease];
        [newDirectMessagesPersistenceStore
            save:directMessageDisplayMgr.newDirectMessagesState];

        [newDirectMessagesPersistenceStore
            saveNewMessageCountsForAllAccounts:
            [directMessageAcctMgr directMessageCountsByAccount]];

        numUnreadMessages =
            directMessageDisplayMgr.newDirectMessagesState.numNewMessages; 
    }

    NSUInteger numTotalMessages = numUnreadMessages + numUnreadMentions;
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
        [accountsButtonSetter setButtonWithUsername:creds.username];
        [homeNetAwareViewController setCachedDataAvailable:NO];
        [self processAccountChange:creds];
    }
}

- (void)showAccountsView
{
    NSLog(@"Showing accounts view");
    [tabBarController presentModalViewController:accountsNavController
        animated:YES];
}

- (void)processUserAccountSelection
{
    TwitterCredentials * activeAccount = [accountsDisplayMgr selectedAccount];

    NSLog(@"Processing user account selection ('%@')", activeAccount.username);

    if (activeAccount &&
        activeAccount != self.activeCredentials.credentials) {
        [accountsButtonSetter setButtonWithUsername:activeAccount.username];
        [homeNetAwareViewController setCachedDataAvailable:NO];

        [self popAllTabsToRoot];

        [self performSelector:@selector(processAccountChange:)
            withObject:activeAccount afterDelay:0.0];
    }
    [accountsNavController dismissModalViewControllerAnimated:YES];
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
    [self loadMessagesViewWithCachedData:activeAccount];

    [directMessageAcctMgr
        processAccountChangeToUsername:activeAccount.username
        fromUsername:oldUsername];
    [mentionsAcctMgr
        processAccountChangeToUsername:activeAccount.username
        fromUsername:oldUsername];

    [directMessageDisplayMgr updateDirectMessagesAfterCredentialChange];
    [mentionDisplayMgr updateMentionsAfterCredentialChange];

    TwitterCredentials * c = self.activeCredentials.credentials;
    AccountSettings * settings =
        [AccountSettings settingsForKey:c.username];
    mentionDisplayMgr.showBadge = [settings pushMentions];

    // This isn't called automatically, so force call here
    [homeNetAwareViewController viewWillAppear:YES];

    [listsDisplayMgr resetState];

    User * user =
        [User userWithUsername:activeAccount.username
        context:[self managedObjectContext]];
    [profileDisplayMgr setNewProfileUsername:activeAccount.username user:user];
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

- (OauthLogInDisplayMgr *)logInDisplayMgr
{
    if (!logInDisplayMgr)
        logInDisplayMgr =
            [[OauthLogInDisplayMgr alloc]
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

- (UIBarButtonItem *)listsSendingTweetProgressView
{
    if (!listsSendingTweetProgressView) {
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

        listsSendingTweetProgressView =
            [[UIBarButtonItem alloc] initWithCustomView:view];

        [activityView startAnimating];

        [view release];
    }

    return listsSendingTweetProgressView;
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

@end
