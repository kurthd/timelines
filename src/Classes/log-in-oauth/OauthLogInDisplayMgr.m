//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "OauthLogInDisplayMgr.h"
#import "MGTwitterEngine.h"
#import "YHOAuthTwitterEngine.h"
#import "TwitterCredentials.h"
#import "TwitterCredentials+KeychainAdditions.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"

#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "OAServiceTicket.h"

@interface OauthLogInDisplayMgr ()

- (void)displayErrorWithMessage:(NSString *)message;
- (void)broadcastSuccessfulLogInNotification:(TwitterCredentials *)credentials;
- (void)dismissView;

@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) ExplainOauthViewController *
    explainOauthViewController;
@property (nonatomic, readonly)
    UINavigationController * explainOauthNavController;
@property (nonatomic, retain) OauthLogInViewController *
    oauthLogInViewController;
@property (nonatomic, retain) YHOAuthTwitterEngine * twitter;
@property (nonatomic, retain) OAToken * requestToken;

@end

@implementation OauthLogInDisplayMgr

@synthesize delegate;
@synthesize context;
@synthesize rootViewController;
@synthesize explainOauthViewController, oauthLogInViewController;
@synthesize twitter;
@synthesize requestToken;
@synthesize allowsCancel;
@synthesize navigationController;

- (void)dealloc
{
    self.delegate = nil;

    self.context = nil;

    self.rootViewController = nil;
    self.oauthLogInViewController = nil;
    self.explainOauthViewController = nil;

    self.twitter = nil;
    self.requestToken = nil;

    [navigationController release];

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
    if (self.navigationController)
        [self.navigationController
            pushViewController:self.explainOauthViewController animated:YES];
    else
        [self.rootViewController
            presentModalViewController:self.explainOauthNavController
            animated:animated];
    self.explainOauthViewController.allowsCancel = self.allowsCancel;
}

- (void)presentOauth:(NSTimer *)timer
{
    UINavigationController * navController =
        [[[UINavigationController alloc]
        initWithRootViewController:self.oauthLogInViewController] autorelease];
    [self.explainOauthViewController presentModalViewController:navController
        animated:YES];
}

- (void)dismissOauth:(NSTimer *)timer
{
    [self dismissView];
}

- (void)dismissExplain:(NSTimer *)sender
{
    NSLog(@"Dismissing the oauth explanation modal view.");
    [self.explainOauthViewController showButtonView];
    [self dismissView];
}

#pragma mark YHOAuthTwitterEngineDelegate implementation

- (void)receivedRequestToken:(id)sender
{
    NSLog(@"Received request token:: '%@'.", self.twitter.requestToken);

    self.requestToken = self.twitter.requestToken;

    NSURL * url = [NSURL URLWithString:
        [NSString stringWithFormat:@"http://twitter.com/oauth/"
        "authorize?oauth_token=%@&oauth_callback=oob", self.requestToken.key]];
    NSURLRequest * req = [NSURLRequest requestWithURL:url];

    if (self.navigationController)
        [self.navigationController
            pushViewController:self.oauthLogInViewController animated:YES];
    else {
        UINavigationController * navController =
            [[[UINavigationController alloc]
            initWithRootViewController:self.oauthLogInViewController]
            autorelease];
        [self.explainOauthViewController presentModalViewController:navController
            animated:YES];
    }

    [self.oauthLogInViewController performSelector:@selector(loadAuthRequest:)
        withObject:req afterDelay:0.2];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)failedToReceiveRequestToken:(id)sender error:(NSError *)error
{
    [self displayErrorWithMessage:error.localizedDescription];
    [self.explainOauthViewController showButtonView];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)receivedAccessToken:(id)sender
{
    NSLog(@"Received access token: '%@'.", self.twitter.accessToken);
    NSLog(@"Logged in user: '%@'.", self.twitter.username);

    self.explainOauthViewController.cancelButton.enabled = YES;

    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"username == %@",
        self.twitter.username];

    TwitterCredentials * credentials =
        [TwitterCredentials findFirst:predicate
                              context:context];

    BOOL newAccount = !credentials;
    if (newAccount) {
        credentials = (TwitterCredentials *)
            [NSEntityDescription
            insertNewObjectForEntityForName:@"TwitterCredentials"
            inManagedObjectContext:context];
        credentials.username = self.twitter.username;
        [credentials setKey:self.twitter.accessToken.key
                  andSecret:self.twitter.accessToken.secret];
    } else
        // save the new key and token
        [credentials setKey:self.twitter.accessToken.key
                  andSecret:self.twitter.accessToken.secret];

    NSError * error;
    if ([context save:&error]) {
        if (newAccount)
            [self broadcastSuccessfulLogInNotification:credentials];
    } else {  // handle the error
        [self displayErrorWithMessage:error.localizedDescription];

        // TODO: Start the login process again on error
        //[self.logInViewController promptForLogIn];
    }

    [[UIApplication sharedApplication] networkActivityDidFinish];

    // HACK: Firing this on a timer because doing it here causes the app to
    // crash in an infinite loop somewhere deep in the UIView code and I have no
    // idea why. I will revisit in the future.
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(dismissExplain:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)failedToReceiveAccessToken:(id)sender error:(NSError *)error
{
    self.explainOauthViewController.cancelButton.enabled = YES;

    [self displayErrorWithMessage:error.localizedDescription];
    [self.explainOauthViewController showButtonView];

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

#pragma mark ExplainOauthViewControllerDelegate

- (void)beginAuthorization
{
    [self.twitter requestRequestToken];
    [self.explainOauthViewController showActivityView];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)userDidCancelExplanation
{
    [self dismissView];
}

#pragma mark OauthLogInViewControllerDelegate implementation

- (void)userIsDone:(NSString *)pin
{
    self.explainOauthViewController.cancelButton.enabled = NO;
    [self dismissView];
    [self.explainOauthViewController showAuthorizingView];

    [self.twitter requestAccessToken:pin];

    [[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)userDidCancel
{
    [self.explainOauthViewController showButtonView];
    [self dismissView];
}

- (void)dismissView
{
    if (!self.navigationController)
        [self.explainOauthViewController
            dismissModalViewControllerAnimated:YES];
    else
        [self.navigationController popViewControllerAnimated:YES];
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
    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
}

#pragma mark Accessors

- (OauthLogInViewController *)oauthLogInViewController
{
    if (!oauthLogInViewController) {
        oauthLogInViewController =
            [[OauthLogInViewController alloc]
            initWithNibName:@"OauthLogInView" bundle:nil];
        oauthLogInViewController.delegate = self;
        oauthLogInViewController.navigationItem.title =
            NSLocalizedString(@"login.title", @"");
        
        NSString * cancelButtonTitle =
            NSLocalizedString(@"login.cancel", @"");
        UIBarButtonItem * cancelButton =
            [[[UIBarButtonItem alloc]
            initWithTitle:cancelButtonTitle style:UIBarButtonItemStyleBordered
            target:oauthLogInViewController action:@selector(userDidCancel)]
            autorelease];
        oauthLogInViewController.navigationItem.leftBarButtonItem =
            cancelButton;
        oauthLogInViewController.cancelButton = cancelButton;

        NSString * doneButtonTitle =
            NSLocalizedString(@"login.done", @"");
        UIBarButtonItem * doneButton =
            [[[UIBarButtonItem alloc]
            initWithTitle:doneButtonTitle style:UIBarButtonItemStyleDone
            target:oauthLogInViewController action:@selector(userIsDone)]
            autorelease];
        oauthLogInViewController.navigationItem.rightBarButtonItem = doneButton;
        oauthLogInViewController.doneButton = doneButton;
    }

    return oauthLogInViewController;
}

- (ExplainOauthViewController *)explainOauthViewController
{
    if (!explainOauthViewController) {
        explainOauthViewController =
            [[ExplainOauthViewController alloc]
            initWithNibName:@"ExplainOauthView" bundle:nil];
        explainOauthViewController.delegate = self;
        explainOauthViewController.navigationItem.title =
            NSLocalizedString(@"account.addaccount", @"");
        UIBarButtonItem * cancelButton =
            [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
            target:self action:@selector(userDidCancel)]
            autorelease];
        if (allowsCancel)
            explainOauthViewController.navigationItem.leftBarButtonItem =
                cancelButton;
        explainOauthViewController.cancelButton = cancelButton;
    }

    return explainOauthViewController;
}

- (UINavigationController *)explainOauthNavController
{
    if (!explainOauthNavController)
        explainOauthNavController =
            [[UINavigationController alloc]
            initWithRootViewController:self.explainOauthViewController];

    return explainOauthNavController;
}

- (YHOAuthTwitterEngine *)twitter
{
    if (!twitter)
        twitter = [[YHOAuthTwitterEngine alloc] initOAuthWithDelegate:self];

    return twitter;
}

@end
