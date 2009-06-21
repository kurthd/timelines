//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitchAppDelegate.h"
#import "DeviceRegistrar.h"
#import "LogInDisplayMgr.h"
#import "CredentialsUpdatePublisher.h"
#import "TwitterCredentials.h"

@interface TwitchAppDelegate ()

@property (nonatomic, retain) LogInDisplayMgr * logInDisplayMgr;
@property (nonatomic, retain) DeviceRegistrar * registrar;

@end

@implementation TwitchAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize logInDisplayMgr;
@synthesize registrar;

- (void)dealloc
{
    [tabBarController release];
    [window release];

    [registrar release];
    [logInDisplayMgr release];

    [credentials release];
    [unregisteredCredentials release];

    [super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    // TEMPORARY
    credentials = [[NSMutableArray alloc] init];
    unregisteredCredentials = [[NSMutableArray alloc] init];

    registeredForPushNotifications = NO;

    /*
    UIRemoteNotificationType notificationTypes =
        (UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert);

    [[UIApplication sharedApplication]
        registerForRemoteNotificationTypes:notificationTypes];
     */

    credentialsUpdatePublisher =
        [[CredentialsUpdatePublisher alloc]
        initWithListener:self action:@selector(credentialsChanged:)];

    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:tabBarController.view];

    if (credentials.count == 0)
        [self.logInDisplayMgr logIn];
}

- (void)registerForPushNotifications
{
    UIRemoteNotificationType notificationTypes =
        (UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert);

    [[UIApplication sharedApplication]
        registerForRemoteNotificationTypes:notificationTypes];
}

#pragma mark Push notification delegate methods

- (void)application:(UIApplication *)app
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
    NSLog(@"Device token: %@.", devToken);

    for (TwitterCredentials * c in unregisteredCredentials) {
        NSDictionary * args = [NSDictionary dictionaryWithObjectsAndKeys:
            c.username, @"username",
            c.password, @"password",
            nil];
        [self.registrar sendProviderDeviceToken:devToken args:args];
    }

    [credentials addObjectsFromArray:unregisteredCredentials];
    [unregisteredCredentials removeAllObjects];

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

#pragma mark Application notifications

- (void)credentialsChanged:(TwitterCredentials *)newCredentials
{
    [unregisteredCredentials addObject:newCredentials];
    [self registerForPushNotifications];
}

#pragma mark Accessors

- (DeviceRegistrar *)registrar
{
    if (!registrar)
        registrar = [[DeviceRegistrar alloc] init];

    return registrar;
}

- (LogInDisplayMgr *)logInDisplayMgr
{
    if (!logInDisplayMgr)
        logInDisplayMgr =
            [[LogInDisplayMgr alloc]
            initWithRootViewController:tabBarController];

    return logInDisplayMgr;
}

@end
