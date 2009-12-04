//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkAwareViewController.h"
#import "DeviceRegistrarDelegate.h"
#import "TimelineDisplayMgrFactory.h"
#import "DirectMessageDisplayMgrFactory.h"
#import "TwitterServiceDelegate.h"
#import "DirectMessageAcctMgr.h"
#import "FindPeopleSearchDisplayMgr.h"
#import "TwitchWebBrowserDisplayMgr.h"
#import "InstapaperService.h"
#import "InstapaperLogInDisplayMgr.h"
#import "UIState.h"
#import "MentionTimelineDisplayMgr.h"
#import "ToggleViewController.h"
#import "MentionsAcctMgr.h"
#import "AccountsButton.h"
#import "AccountsButtonSetter.h"
#import "ListsDisplayMgr.h"
#import "TwitterCredentials.h"
#import "ContactCache.h"
#import "ContactMgr.h"
#import "ProfileDisplayMgr.h"

@class OauthLogInDisplayMgr, ComposeTweetDisplayMgr, AccountsDisplayMgr;
@class SearchBarDisplayMgr;
@class AccountsViewController;
@class DeviceRegistrar;
@class CredentialsActivatedPublisher, CredentialsSetChangedPublisher;
@class AccountSettingsChangedPublisher;
@class ActiveTwitterCredentials;
@class TrendDisplayMgr;
@class TrendsViewController;

@interface TwitchAppDelegate : NSObject
    <UIApplicationDelegate, UITabBarControllerDelegate, DeviceRegistrarDelegate,
    TwitterServiceDelegate, ComposeTweetDisplayMgrDelegate,
    TwitchWebBrowserDisplayMgrDelegate, InstapaperServiceDelegate,
    InstapaperLogInDisplayMgrDelegate>
{
    UIWindow * window;
    UITabBarController * tabBarController;

    OauthLogInDisplayMgr * logInDisplayMgr;

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

    // Root view controllers
    IBOutlet NetworkAwareViewController * homeNetAwareViewController;
    IBOutlet NetworkAwareViewController * mentionsNetAwareViewController;
    IBOutlet NetworkAwareViewController * messagesNetAwareViewController;
    IBOutlet NetworkAwareViewController * searchNetAwareViewController;
    IBOutlet NetworkAwareViewController * findPeopleNetAwareViewController;
    IBOutlet NetworkAwareViewController * listsNetAwareViewController;
    IBOutlet NetworkAwareViewController * trendsNetAwareViewController;
    IBOutlet NetworkAwareViewController * profileNetAwareViewController;

    IBOutlet AccountsButton * accountsButton;
    AccountsButtonSetter * accountsButtonSetter;
    UINavigationController * accountsNavController;
    AccountsViewController * accountsViewController;

    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    DirectMessageDisplayMgrFactory * directMessageDisplayMgrFactory;
    DirectMessagesDisplayMgr * directMessageDisplayMgr;
    DirectMessageAcctMgr * directMessageAcctMgr;
    MentionsAcctMgr * mentionsAcctMgr;
    TimelineDisplayMgr * timelineDisplayMgr;
    TimelineDisplayMgr * searchBarTimelineDisplayMgr;

    ComposeTweetDisplayMgr * composeTweetDisplayMgr;

    SearchBarDisplayMgr * searchBarDisplayMgr;
    FindPeopleSearchDisplayMgr * findPeopleSearchDisplayMgr;
    ProfileDisplayMgr * profileDisplayMgr;
    AccountsDisplayMgr * accountsDisplayMgr;
    MentionTimelineDisplayMgr * mentionDisplayMgr;
    ListsDisplayMgr * listsDisplayMgr;
    TrendDisplayMgr * trendDisplayMgr;
    TrendsViewController * trendsViewController;

    UIBarButtonItem * homeSendingTweetProgressView;

    SavedSearchMgr * findPeopleBookmarkMgr;

    InstapaperService * instapaperService;
    NSString * savingInstapaperUrl;
    InstapaperLogInDisplayMgr * instapaperLogInDisplayMgr;

    UIState * uiState;
    
    ContactCache * contactCache;
    ContactMgr * contactMgr;
}

@property (nonatomic, retain) IBOutlet UIWindow * window;
@property (nonatomic, retain) IBOutlet UITabBarController * tabBarController;

@property (nonatomic, retain, readonly) NSManagedObjectModel *
    managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *
    managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *
    persistentStoreCoordinator;

@property (nonatomic, readonly) NSString * applicationDocumentsDirectory;

- (IBAction)composeTweet:(id)sender;

@end
