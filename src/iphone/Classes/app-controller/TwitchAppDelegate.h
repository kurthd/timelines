//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkAwareViewController.h"
#import "DeviceRegistrarDelegate.h"
#import "TimelineDisplayMgrFactory.h"
#import "TwitterServiceDelegate.h"

@class LogInDisplayMgr, DeviceRegistrar;
@class CredentialsUpdatePublisher;

@interface TwitchAppDelegate : NSObject
    <UIApplicationDelegate, UITabBarControllerDelegate, DeviceRegistrarDelegate,
    TwitterServiceDelegate>
{
    UIWindow *window;
    UITabBarController *tabBarController;

    LogInDisplayMgr * logInDisplayMgr;

    BOOL registeredForPushNotifications;
    DeviceRegistrar * registrar;

    NSMutableArray * credentials;
    NSMutableArray * unregisteredCredentials;

    CredentialsUpdatePublisher * credentialsUpdatePublisher;

    // Core Data classes
    NSManagedObjectModel * managedObjectModel;
    NSManagedObjectContext * managedObjectContext;
    NSPersistentStoreCoordinator * persistentStoreCoordinator;

    // Root view controllers
    IBOutlet NetworkAwareViewController * homeNetAwareViewController;
    IBOutlet NetworkAwareViewController * profileNetAwareViewController;
    IBOutlet NetworkAwareViewController * trendsNetAwareViewController;
    IBOutlet NetworkAwareViewController * searchNetAwareViewController;
    IBOutlet NetworkAwareViewController * accountsNetAwareViewController;
    
    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    TimelineDisplayMgr * timelineDisplayMgr;
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

@end
