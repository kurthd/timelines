//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkAwareViewController.h"
#import "DeviceRegistrarDelegate.h"
#import "TimelineDisplayMgrFactory.h"
#import "TwitterServiceDelegate.h"
#import "ComposeTweetDisplayMgrDelegate.h"
#import "PersonalFeedSelectionMgr.h"

@class OauthLogInDisplayMgr, ComposeTweetDisplayMgr, AccountsDisplayMgr;
@class TrendsDisplayMgr, SearchBarDisplayMgr;
@class AccountsViewController;
@class DeviceRegistrar;
@class CredentialsActivatedPublisher, CredentialsSetChangedPublisher;
@class ActiveTwitterCredentials;

@interface TwitchAppDelegate : NSObject
    <UIApplicationDelegate, UITabBarControllerDelegate, DeviceRegistrarDelegate,
    TwitterServiceDelegate, ComposeTweetDisplayMgrDelegate>
{
    UIWindow * window;
    UITabBarController * tabBarController;

    OauthLogInDisplayMgr * logInDisplayMgr;

    BOOL deviceNeedsRegistration;
    DeviceRegistrar * registrar;

    NSMutableArray * credentials;
    ActiveTwitterCredentials * activeCredentials;

    CredentialsActivatedPublisher * credentialsActivatedPublisher;
    CredentialsSetChangedPublisher * credentialsSetChangedPublisher;

    // Core Data classes
    NSManagedObjectModel * managedObjectModel;
    NSManagedObjectContext * managedObjectContext;
    NSPersistentStoreCoordinator * persistentStoreCoordinator;

    // Root view controllers
    IBOutlet NetworkAwareViewController * homeNetAwareViewController;
    IBOutlet NetworkAwareViewController * profileNetAwareViewController;
    IBOutlet NetworkAwareViewController * trendsNetAwareViewController;
    IBOutlet NetworkAwareViewController * searchNetAwareViewController;
    IBOutlet AccountsViewController * accountsViewController;
    
    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    TimelineDisplayMgr * timelineDisplayMgr;
    TimelineDisplayMgr * profileTimelineDisplayMgr;
    PersonalFeedSelectionMgr * personalFeedSelectionMgr;

    ComposeTweetDisplayMgr * composeTweetDisplayMgr;

    TrendsDisplayMgr * trendsDisplayMgr;
    SearchBarDisplayMgr * searchBarDisplayMgr;
    AccountsDisplayMgr * accountsDisplayMgr;

    UIBarButtonItem * homeSendingTweetProgressView;
    UIBarButtonItem * profileSendingTweetProgressView;
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