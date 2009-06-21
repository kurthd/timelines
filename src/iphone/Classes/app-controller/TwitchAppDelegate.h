//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LogInDisplayMgr, DeviceRegistrar;
@class CredentialsUpdatePublisher;

@interface TwitchAppDelegate : NSObject
    <UIApplicationDelegate, UITabBarControllerDelegate>
{
    UIWindow *window;
    UITabBarController *tabBarController;

    LogInDisplayMgr * logInDisplayMgr;

    BOOL registeredForPushNotifications;
    DeviceRegistrar * registrar;

    NSMutableArray * credentials;
    NSMutableArray * unregisteredCredentials;

    CredentialsUpdatePublisher * credentialsUpdatePublisher;
}

@property (nonatomic, retain) IBOutlet UIWindow * window;
@property (nonatomic, retain) IBOutlet UITabBarController * tabBarController;

@end
