//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "LogInDisplayMgr.h"
#import "LogInViewController.h"
#import "MGTwitterEngine.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "TwitterCredentials.h"

@interface LogInDisplayMgr ()

- (void)broadcastSuccessfulLogInNotification;

@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) LogInViewController * logInViewController;
@property (nonatomic, retain) MGTwitterEngine * twitter;
@property (nonatomic, copy) NSString * logInRequestId;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * password;

@end

@implementation LogInDisplayMgr

@synthesize rootViewController, logInViewController;
@synthesize twitter, logInRequestId;
@synthesize username, password;

- (void)dealloc
{
    self.rootViewController = nil;
    self.logInViewController = nil;

    self.twitter = nil;
    self.logInRequestId = nil;

    self.username = nil;
    self.password = nil;

    [super dealloc];
}

- (id)initWithRootViewController:(UIViewController *)aRootViewController
{
    if (self = [super init])
        self.rootViewController = aRootViewController;

    return self;
}

- (void)logIn
{
    [self.rootViewController presentModalViewController:self.logInViewController
                                               animated:YES];
    [self.logInViewController promptForLogIn];
}

#pragma mark LogInViewControllerDelegate implementation

- (void)userDidProvideUsername:(NSString *)aUsername
                      password:(NSString *)aPassword
{
    self.username = aUsername;
    self.password = aPassword;

    [self.twitter setUsername:self.username password:self.password];
    self.logInRequestId = [self.twitter checkUserCredentials];
    NSLog(@"Attempting log in %@: '%@'.",
        [self.twitter usesSecureConnection] ? @"securely" : @"insecurely",
        self.logInRequestId);
}

- (void)userDidCancel
{
    NSLog(@"User cancelled log in.");
}

#pragma mark MGTwitterEngineDelegate implementation

- (void)requestSucceeded:(NSString *)requestIdentifier
{
    NSLog(@"Request '%@' succeeded.", requestIdentifier);
    [self broadcastSuccessfulLogInNotification];

    [self.rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error
{
    NSLog(@"Request '%@' failed; error: '%@'.", requestIdentifier, error);

    NSString * title = NSLocalizedString(@"login.failed.alert.title", @"");
    NSString * message = error.localizedDescription;

    UIAlertView * alert = [UIAlertView simpleAlertViewWithTitle:title
                                                        message:message];
    [alert show];

    [self.logInViewController promptForLogIn];
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier
{
    NSLog(@"Statuses recieved for request '%@': %@", identifier, statuses);

    if ([self.logInRequestId isEqualToString:identifier])
        [self broadcastSuccessfulLogInNotification];
}

- (void)directMessagesReceived:(NSArray *)messages
                    forRequest:(NSString *)identifier
{
    NSLog(@"Direct messages recieved for request '%@': %@", identifier,
        messages);
}

- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)identifier
{
    NSLog(@"User info received for request '%@': %@", identifier, userInfo);
}

- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)identifier
{
    NSLog(@"Misc. info received for request '%@': %@", identifier, miscInfo);
}

- (void)imageReceived:(UIImage *)image forRequest:(NSString *)identifier
{
    NSLog(@"Image received for request '%@': %@", identifier, image);
}

- (void)broadcastSuccessfulLogInNotification
{
    TwitterCredentials * credentials =
        [TwitterCredentials credentialsWithUsername:self.username
                                           password:self.password];
    NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        credentials, @"credentials",
        nil];

    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"CredentialsChangedNotification"
                      object:self
                    userInfo:userInfo];
}

#pragma mark Accessors

- (LogInViewController *)logInViewController
{
    if (!logInViewController) {
        logInViewController =
            [[LogInViewController alloc] initWithNibName:@"LogInView"
                                                  bundle:nil];
        logInViewController.delegate = self;
    }

    return logInViewController;
}

- (MGTwitterEngine *)twitter
{
    if (!twitter)
        twitter = [[MGTwitterEngine alloc] initWithDelegate:self];

    return twitter;
}

@end
