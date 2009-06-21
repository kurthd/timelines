//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitchAppDelegate.h"
#import "DeviceRegistrar.h"

@interface TwitchAppDelegate ()

@property (nonatomic, retain) DeviceRegistrar * registrar;

@end

@implementation TwitchAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize registrar;

- (void)dealloc
{
    [tabBarController release];
    [window release];
    [registrar release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    UIRemoteNotificationType notificationTypes =
        (UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert);

    [[UIApplication sharedApplication]
        registerForRemoteNotificationTypes:notificationTypes];

    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:tabBarController.view];
}

#pragma mark Notification delegate methods

- (void)application:(UIApplication *)app
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    NSLog(@"Device token: %@.", devToken);

    [self.registrar sendProviderDeviceToken:devToken];

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

/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
}
*/

/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/

#pragma mark Accessors

- (DeviceRegistrar *)registrar
{
    if (!registrar)
        registrar = [[DeviceRegistrar alloc] init];

    return registrar;
}

@end

