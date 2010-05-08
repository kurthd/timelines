//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkAwareViewController.h"
#import "DeviceRegistrarDelegate.h"
#import "TimelineDisplayMgrFactory.h"
#import "TwitterServiceDelegate.h"
#import "DirectMessageAcctMgr.h"
#import "TwitchWebBrowserDisplayMgr.h"
#import "InstapaperService.h"
#import "InstapaperLogInDisplayMgr.h"
#import "UIState.h"
#import "MentionTimelineDisplayMgr.h"
#import "ToggleViewController.h"
#import "MentionsAcctMgr.h"
#import "AccountsButton.h"
#import "AccountsButtonSetter.h"
#import "TwitterCredentials.h"
#import "ContactCache.h"
#import "ContactMgr.h"
#import "TimelineSelectionViewController.h"
#import "ListsDisplayMgr.h"

@class XauthLogInDisplayMgr, ComposeTweetDisplayMgr, AccountsDisplayMgr;
@class AccountsViewController;
@class DeviceRegistrar;
@class CredentialsActivatedPublisher, CredentialsSetChangedPublisher;
@class AccountSettingsChangedPublisher;
@class ActiveTwitterCredentials;
@class ManagedObjectContextPruner;
@class AnalyticsService;

@interface TwitchAppDelegate : NSObject
    <UIApplicationDelegate, DeviceRegistrarDelegate, TwitterServiceDelegate,
    ComposeTweetDisplayMgrDelegate, TwitchWebBrowserDisplayMgrDelegate,
    InstapaperServiceDelegate, InstapaperLogInDisplayMgrDelegate,
    UIAccelerometerDelegate, TimelineSelectionViewControllerDelegate>
{
    UIWindow * window;

    XauthLogInDisplayMgr * logInDisplayMgr;

    DeviceRegistrar * registrar;

    NSMutableArray * credentials;
    ActiveTwitterCredentials * activeCredentials;

    CredentialsActivatedPublisher * credentialsActivatedPublisher;
    CredentialsSetChangedPublisher * credentialsSetChangedPublisher;
    AccountSettingsChangedPublisher * accountSettingsChangedPublisher;

    // Core Data classes
    NSManagedObjectModel * managedObjectModel;
    NSManagedObjectContext * managedObjectContext;
    NSPersistentStoreCoordinator * persistentStoreCoordinator;
    ManagedObjectContextPruner * managedObjectContextPruner;
    
    IBOutlet NetworkAwareViewController * homeNetAwareViewController;
    IBOutlet UINavigationController * mainNavController;
    IBOutlet AccountsViewController * accountsViewController;
    IBOutlet TimelineSelectionViewController * timelineSelectionController;
    IBOutlet NetworkAwareViewController * mentionsNetAwareViewController;
    IBOutlet NetworkAwareViewController * favoritesNetAwareViewController;
    IBOutlet NetworkAwareViewController * retweetsNetAwareViewController;
    IBOutlet NetworkAwareViewController * listsNetAwareViewController;
    
    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    MentionsAcctMgr * mentionsAcctMgr;
    TimelineDisplayMgr * timelineDisplayMgr;
    TimelineDisplayMgr * favoritesDisplayMgr;
    TimelineDisplayMgr * retweetsDisplayMgr;
    ListsDisplayMgr * listsDisplayMgr;
    ComposeTweetDisplayMgr * composeTweetDisplayMgr;

    AccountsDisplayMgr * accountsDisplayMgr;
    MentionTimelineDisplayMgr * mentionDisplayMgr;

    UIBarButtonItem * homeSendingTweetProgressView;
    UIBarButtonItem * mentionsSendingTweetProgressView;

    InstapaperService * instapaperService;
    NSString * savingInstapaperUrl;
    InstapaperLogInDisplayMgr * instapaperLogInDisplayMgr;

    UIState * uiState;
    
    ContactCache * contactCache;
    ContactMgr * contactMgr;

    BOOL histeresisExcited;
    UIAcceleration * lastAcceleration;
    
    BOOL showHomeTab;
    BOOL loadedContactCache;

    AnalyticsService * analyticsService;
}

@property (nonatomic, retain) IBOutlet UIWindow * window;

@property (nonatomic, retain, readonly) NSManagedObjectModel *
    managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *
    managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *
    persistentStoreCoordinator;

@property (nonatomic, readonly) NSString * applicationDocumentsDirectory;

- (IBAction)composeTweet:(id)sender;
- (IBAction)userWantsToAddAccount:(id)sender;

- (void)setLocation:(CLLocation *)location;

@end
