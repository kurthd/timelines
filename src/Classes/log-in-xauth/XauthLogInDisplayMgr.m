//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import "XauthLogInDisplayMgr.h"
#import "TwitbitShared.h"

@interface XauthLogInDisplayMgr ()
@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) XauthLogInViewController * logInViewController;
@property (nonatomic, retain) UINavigationController * logInNavController;
@property (nonatomic, retain) NSManagedObjectContext * context;

- (void)authenticateUsername:(NSString *)username password:(NSString *)password;
- (TwitterCredentials *)addAccountWithUsername:(NSString *)username
                                         token:(NSString *)token
                                        secret:(NSString *)secret;
- (void)addPhotoAccountsForCredentials:(TwitterCredentials *)creds
                              password:(NSString *)password;

- (void)broadcastSuccessfulLogInNotification:(TwitterCredentials *)credentials;
- (void)displayErrorWithMessage:(NSString *)message;
- (void)dismissView;
@end

@implementation XauthLogInDisplayMgr

@synthesize delegate;
@synthesize rootViewController, navigationController;
@synthesize logInNavController, logInViewController;
@synthesize context;
@synthesize allowsCancel;

- (void)dealloc
{
    self.delegate = nil;

    self.rootViewController = nil;
    self.navigationController = nil;
    self.logInNavController = nil;
    self.logInViewController = nil;

    self.context = nil;

    [super dealloc];
}

#pragma mark Public implementation

- (id)initWithRootViewController:(UIViewController *)aRootViewController
            managedObjectContext:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.rootViewController = aRootViewController;
        self.context = aContext;

        authenticating = NO;
    }

    return self;
}

- (void)logIn:(BOOL)animated
{
    self.logInViewController.allowsCancel = self.allowsCancel;
    if (self.navigationController)
        [self.navigationController
            pushViewController:self.logInViewController animated:YES];
    else
        [self.rootViewController
            presentModalViewController:self.logInNavController
                              animated:animated];
}

#pragma mark XauthLogInViewControllerDelegate implementation

- (void)userDidSaveUsername:(NSString *)username password:(NSString *)password
{
    [self.logInViewController displayActivity:YES];
    [self authenticateUsername:username password:password];

    authenticating = YES;
}

- (void)userDidCancel
{
    self.logInNavController = nil;
    self.logInViewController = nil;

    if (authenticating) {
        [[UIApplication sharedApplication] networkActivityDidFinish];
        authenticating = NO;
    }

    [self dismissView];
}

- (BOOL)isUsernameValid:(NSString *)username
{
    NSArray * accounts = [TwitterCredentials findAll:self.context];
    for (TwitterCredentials * account in accounts)
        if ([account.username isEqualToString:username])
            return NO;

    return YES;
}

#pragma mark TwitterXauthenticatorDelegate implementation

- (void)xauthenticator:(TwitterXauthenticator *)xauthenticator
       didReceiveToken:(NSString *)token
             andSecret:(NSString *)secret
           forUsername:(NSString *)username
           andPassword:(NSString *)password
{
    if (authenticating) {
        TwitterCredentials * creds =
            [self addAccountWithUsername:username token:token secret:secret];
        if (creds) {
            NSString * password = [xauthenticator password];
            [self addPhotoAccountsForCredentials:creds password:password];

            [self dismissView];

            self.logInNavController = nil;
            self.logInViewController = nil;
        } else
            [self.logInViewController displayActivity:NO];

        [[UIApplication sharedApplication] networkActivityDidFinish];
    }

    authenticating = NO;
    [xauthenticator autorelease];
}

- (void)xauthenticator:(TwitterXauthenticator *)xauthenticator
  failedToAuthUsername:(NSString *)username
           andPassword:(NSString *)password
                 error:(NSError *)error
{
    if (authenticating) {
        [self.logInViewController displayActivity:NO];
        [self displayErrorWithMessage:error.localizedDescription];
        [[UIApplication sharedApplication] networkActivityDidFinish];
    }

    authenticating = NO;
    [xauthenticator autorelease];
}

#pragma mark Private implementation

- (void)authenticateUsername:(NSString *)username password:(NSString *)password
{
    TwitterXauthenticator * authenticator =
        [[TwitterXauthenticator twitbitForIphoneXauthenticator] retain];
    [authenticator setDelegate:self];
    [authenticator authWithUsername:username password:password];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (TwitterCredentials *)addAccountWithUsername:(NSString *)username
                                         token:(NSString *)token
                                        secret:(NSString *)secret
{
    TwitterCredentials * credentials = (TwitterCredentials *)
        [NSEntityDescription
        insertNewObjectForEntityForName:@"TwitterCredentials"
                 inManagedObjectContext:self.context];
    credentials.username = username;
    [credentials setKey:token andSecret:secret];

    NSError * error;
    BOOL didSave = [context save:&error];
    if (didSave)
        [self broadcastSuccessfulLogInNotification:credentials];
    else  // handle the error
        [self displayErrorWithMessage:error.localizedDescription];

    return didSave ? credentials : nil;
}

- (void)addPhotoAccountsForCredentials:(TwitterCredentials *)credentials
                              password:(NSString *)password
{
    TwitPicCredentials * twitPicCredentials = (TwitPicCredentials *)
        [NSEntityDescription
        insertNewObjectForEntityForName:@"TwitPicCredentials"
                 inManagedObjectContext:self.context];
    twitPicCredentials.username = credentials.username;
    [twitPicCredentials setPassword:password];
    twitPicCredentials.credentials = credentials;
    [self.context save:NULL];

    TwitVidCredentials * twitVidCredentials = (TwitVidCredentials *)
        [NSEntityDescription
        insertNewObjectForEntityForName:@"TwitVidCredentials"
                 inManagedObjectContext:self.context];
    twitVidCredentials.username = credentials.username;
    [twitVidCredentials setPassword:password];
    twitVidCredentials.credentials = credentials;
    [self.context save:NULL];

    YfrogCredentials * yfrogCredentials = (YfrogCredentials *)
        [NSEntityDescription insertNewObjectForEntityForName:@"YfrogCredentials"
                                      inManagedObjectContext:self.context];
    yfrogCredentials.username = credentials.username;
    [yfrogCredentials setPassword:password];
    yfrogCredentials.credentials = credentials;
    [self.context save:NULL];

    // configure the defaults -- set both to yfrog
    AccountSettings * settings =
        [AccountSettings settingsForKey:credentials.username];
    [settings setPhotoServiceName:yfrogCredentials.serviceName];
    [settings setVideoServiceName:yfrogCredentials.serviceName];
    [AccountSettings setSettings:settings forKey:credentials.username];
}

- (void)broadcastSuccessfulLogInNotification:(TwitterCredentials *)credentials
{
    NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        credentials, @"credentials",
        [NSNumber numberWithInteger:1], @"added",
        nil];

    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"CredentialsSetChangedNotification"
                      object:self
                    userInfo:userInfo];
}

- (void)displayErrorWithMessage:(NSString *)message
{
    NSString * title = LS(@"xauth.auth.failed");
    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
}

- (void)dismissView
{
    if (self.navigationController)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self.logInViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark Accessoors

- (XauthLogInViewController *)logInViewController
{
    if (!logInViewController) {
        logInViewController =
            [[XauthLogInViewController alloc] initWithNibName:@"XauthLogInView"
                                                       bundle:nil];
        logInViewController.delegate = self;
    }

    return logInViewController;
}

- (UINavigationController *)logInNavController
{
    if (!logInNavController)
        logInNavController = 
            [[UINavigationController alloc]
            initWithRootViewController:self.logInViewController];

    return logInNavController;
}

@end
