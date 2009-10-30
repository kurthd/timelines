//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "LogInDisplayMgr.h"
#import "LogInViewController.h"
#import "MGTwitterEngine.h"
#import "TwitterCredentials.h"
#import "TwitterCredentials+KeychainAdditions.h"
#import "TwitPicCredentials.h"
#import "TwitPicCredentials+KeychainAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"

@interface LogInDisplayMgr ()

- (void)displayErrorWithMessage:(NSString *)message;
- (void)broadcastSuccessfulLogInNotification:(TwitterCredentials *)credentials;

- (BOOL)isLoggingIn;
- (void)cancelLogIn;

@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) LogInViewController * logInViewController;
@property (nonatomic, retain) MGTwitterEngine * twitter;
@property (nonatomic, copy) NSString * logInRequestId;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * password;

@end

@implementation LogInDisplayMgr

@synthesize delegate;
@synthesize context;
@synthesize rootViewController, logInViewController;
@synthesize twitter, logInRequestId;
@synthesize username, password;
@synthesize allowsCancel;

- (void)dealloc
{
    self.delegate = nil;

    self.context = nil;

    self.rootViewController = nil;
    self.logInViewController = nil;

    self.twitter = nil;
    self.logInRequestId = nil;

    self.username = nil;
    self.password = nil;

    [super dealloc];
}

- (id)initWithRootViewController:(UIViewController *)aRootViewController
            managedObjectContext:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.rootViewController = aRootViewController;
        self.context = aContext;
    }

    return self;
}

- (void)logIn:(BOOL)animated;
{
    [self.rootViewController presentModalViewController:self.logInViewController
                                               animated:animated];
    [self.logInViewController promptForLogIn];
}

- (void)logInForUser:(NSString *)user animated:(BOOL)animated
{
    [self.rootViewController presentModalViewController:self.logInViewController
                                               animated:animated];
    [self.logInViewController promptForLoginWithUsername:user editable:NO];
}

- (void)setViewTitle:(NSString *)title
{
    self.logInViewController.title = title;
}

- (void)setViewInstructions:(NSString *)instructions
{
    self.logInViewController.footer = instructions;
}

#pragma mark LogInViewControllerDelegate implementation

- (void)userDidProvideUsername:(NSString *)aUsername
                      password:(NSString *)aPassword
{
    self.username = aUsername;
    self.password = aPassword;

    [self.twitter setUsername:self.username password:self.password];
    self.logInRequestId = [self.twitter checkUserCredentials];

    [[UIApplication sharedApplication] networkActivityIsStarting];
    
    NSLog(@"Attempting log in %@: '%@'.",
        [self.twitter usesSecureConnection] ? @"securely" : @"insecurely",
        self.logInRequestId);
}

- (void)userDidCancel
{
    NSAssert(self.allowsCancel, @"User cancelled even though it's forbidden.");

    if ([self isLoggingIn])
        [self cancelLogIn];

    [self.rootViewController dismissModalViewControllerAnimated:YES];
    [self.delegate logInCancelled];
}

- (BOOL)userCanCancel
{
    return self.allowsCancel;
}

#pragma mark LogInDisplayMgrDelegate implementation

- (BOOL)isUsernameValid:(NSString *)aUsername
{
    SEL sel = @selector(isUsernameValid:);
    if (self.delegate && [self.delegate respondsToSelector:sel])
        return [self.delegate isUsernameValid:aUsername];
    else
        return YES;
}

#pragma mark MGTwitterEngineDelegate implementation

- (void)requestSucceeded:(NSString *)requestIdentifier
{
    NSLog(@"Request '%@' succeeded.", requestIdentifier);

    if ([self isLoggingIn]) {
        NSPredicate * predicate =
            [NSPredicate predicateWithFormat:@"username == %@",
            self.twitter.username];
        TwitterCredentials * twitterCredentials =
            [TwitterCredentials findFirst:predicate context:context];

        if (twitterCredentials == nil) {
            NSString * message =
                @"The Twitter login that matches this TwitPic login was not "
                "found.";
            [self displayErrorWithMessage:message];
            // HACK: Hardcoding the call to the username here
            [self.logInViewController promptForLoginWithUsername:self.username
                                                        editable:NO];
        } else {
            [self.rootViewController dismissModalViewControllerAnimated:YES];
            [self.delegate logInCompleted:self.username password:self.password];
        }

        [[UIApplication sharedApplication] networkActivityDidFinish];
        self.logInRequestId = nil;
    }
}

- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error
{
    NSLog(@"Request '%@' failed; error: '%@'.", requestIdentifier, error);

    if ([self isLoggingIn]) {
        [self displayErrorWithMessage:error.localizedDescription];
        // HACK: Hardcoding the call to the username here
        [self.logInViewController promptForLoginWithUsername:self.username
                                                    editable:NO];

        [[UIApplication sharedApplication] networkActivityDidFinish];
        self.logInRequestId = nil;
    }
}

- (void)connectionFinished
{
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier
{
    NSLog(@"Statuses recieved for request '%@': %@", identifier, statuses);
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

- (void)searchResultsReceived:(NSArray *)searchResults
                   forRequest:(NSString *)connectionIdentifier
{
}

- (void)receivedObject:(NSDictionary *)dictionary
            forRequest:(NSString *)connectionIdentifier
{
}

#pragma mark Notify the system of new accounts

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

    NSString * title = NSLocalizedString(@"login.failed.alert.title", @"");

    UIAlertView * alert = [UIAlertView simpleAlertViewWithTitle:title
                                                        message:message];
    [alert show];
}

#pragma mark Private implementation

- (BOOL)isLoggingIn
{
    return !!self.logInRequestId;
}

- (void)cancelLogIn
{
    [self.twitter closeConnection:self.logInRequestId];
    [[UIApplication sharedApplication] networkActivityDidFinish];
    self.logInRequestId = nil;
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
