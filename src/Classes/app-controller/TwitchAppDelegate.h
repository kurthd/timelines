//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkAwareViewController.h"
#import "DeviceRegistrarDelegate.h"
#import "TimelineDisplayMgrFactory.h"
#import "DirectMessageDisplayMgrFactory.h"
#import "TwitterServiceDelegate.h"
#import "ComposeTweetDisplayMgrDelegate.h"
#import "PersonalFeedSelectionMgr.h"
#import "DirectMessageAcctMgr.h"
#import "FindPeopleSearchDisplayMgr.h"
#import "TwitchWebBrowserDisplayMgr.h"
#import "InstapaperService.h"
#import "InstapaperLogInDisplayMgr.h"

@class OauthLogInDisplayMgr, ComposeTweetDisplayMgr, AccountsDisplayMgr;
@class SearchBarDisplayMgr;
@class AccountsViewController;
@class DeviceRegistrar;
@class CredentialsActivatedPublisher, CredentialsSetChangedPublisher;
@class AccountSettingsChangedPublisher;
@class ActiveTwitterCredentials;

@interface TwitchAppDelegate : NSObject
    <UIApplicationDelegate, UITabBarControllerDelegate, DeviceRegistrarDelegate,
    TwitterServiceDelegate, ComposeTweetDisplayMgrDelegate,
    TwitchWebBrowserDisplayMgrDelegate, InstapaperServiceDelegate>
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
    IBOutlet NetworkAwareViewController * messagesNetAwareViewController;
    IBOutlet NetworkAwareViewController * profileNetAwareViewController;
    IBOutlet NetworkAwareViewController * searchNetAwareViewController;
    IBOutlet AccountsViewController * accountsViewController;
    IBOutlet NetworkAwareViewController * findPeopleNetAwareViewController;

    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    DirectMessageDisplayMgrFactory * directMessageDisplayMgrFactory;
    DirectMessagesDisplayMgr * directMessageDisplayMgr;
    DirectMessageAcctMgr * directMessageAcctMgr;
    TimelineDisplayMgr * timelineDisplayMgr;
    TimelineDisplayMgr * profileTimelineDisplayMgr;
    PersonalFeedSelectionMgr * personalFeedSelectionMgr;

    ComposeTweetDisplayMgr * composeTweetDisplayMgr;

    SearchBarDisplayMgr * searchBarDisplayMgr;
    FindPeopleSearchDisplayMgr * findPeopleSearchDisplayMgr;
    AccountsDisplayMgr * accountsDisplayMgr;

    UIBarButtonItem * homeSendingTweetProgressView;
    UIBarButtonItem * profileSendingTweetProgressView;

    SavedSearchMgr * findPeopleBookmarkMgr;

    InstapaperService * instapaperService;
    NSString * savingInstapaperUrl;
    InstapaperLogInDisplayMgr * instapaperLogInDisplayMgr;
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
