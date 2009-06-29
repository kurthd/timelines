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

@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) ExplainOauthViewController *
    explainOauthViewController;
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

- (void)dealloc
{
    self.delegate = nil;

    self.context = nil;

    self.rootViewController = nil;
    self.oauthLogInViewController = nil;
    self.explainOauthViewController = nil;

    self.twitter = nil;
    self.requestToken = nil;

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
    [self.rootViewController
        presentModalViewController:self.explainOauthViewController
                          animated:YES];
    //self.explainOauthViewController.allowsCancel = self.allowsCancel;
    //[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(presentOauth:) userInfo:nil repeats:NO];
    //[NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(dismissOauth:) userInfo:nil repeats:NO];
    //[NSTimer scheduledTimerWithTimeInterval:9 target:self selector:@selector(dismissExplain:) userInfo:nil repeats:NO];
}

- (void)presentOauth:(NSTimer *)timer
{
    [self.explainOauthViewController presentModalViewController:self.oauthLogInViewController animated:YES];
}

- (void)dismissOauth:(NSTimer *)timer
{
    [self.explainOauthViewController dismissModalViewControllerAnimated:YES];
}

- (void)dismissExplain:(NSTimer *)sender
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];
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

    [self.explainOauthViewController
        presentModalViewController:self.oauthLogInViewController
                          animated:YES];
    [self.oauthLogInViewController loadAuthRequest:req];

    //[[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)receivedAccessToken:(id)sender
{
    NSLog(@"got something: '%@'.", self.twitter.accessToken);
    NSLog(@"Logged in user: '%@'.", self.twitter.username);

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
        if (newAccount) {
            [self broadcastSuccessfulLogInNotification:credentials];
        }
    } else {  // handle the error
        [self displayErrorWithMessage:error.localizedDescription];
    
        // TODO: Start the login process again on error
        //[self.logInViewController promptForLogIn];
    }

    NSLog(@"my modal view: '%@'.", self.rootViewController.modalViewController);
    NSLog(@"my explain view: '%@'.", self.explainOauthViewController);
    NSLog(@"my root view's retain count: %d.", [self.rootViewController retainCount]);
    NSLog(@"my modal view's retain count: %d.", [self.rootViewController.modalViewController retainCount]);
    //[self.rootViewController dismissModalViewControllerAnimated:YES];
    //[[UIApplication sharedApplication] networkActivityDidFinish];
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(dismissExplain:) userInfo:nil repeats:NO];
}

#pragma mark ExplainOauthViewControllerDelegate

- (void)beginAuthorization
{
    [self.twitter requestRequestToken];
    //[self.explainOauthViewController showActivityView];
}

- (void)userDidCancelExplanation
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark OauthLogInViewControllerDelegate implementation

- (void)userIsDone:(NSString *)pin
{
    //[self.explainOauthViewController showAuthorizingView];
    [self.explainOauthViewController dismissModalViewControllerAnimated:YES];
    //[self.rootViewController dismissModalViewControllerAnimated:YES];

    [self.twitter requestAccessToken:pin];
    //[[UIApplication sharedApplication] networkActivityIsStarting];
}

- (void)userDidCancel
{
    //[self.explainOauthViewController showButtonView];
    [self.explainOauthViewController dismissModalViewControllerAnimated:YES];
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

#pragma mark Accessors

- (OauthLogInViewController *)oauthLogInViewController
{
    if (!oauthLogInViewController) {
        oauthLogInViewController =
            [[OauthLogInViewController alloc]
            initWithNibName:@"OauthLogInView" bundle:nil];
        oauthLogInViewController.delegate = self;
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
    }

    return explainOauthViewController;
}

- (YHOAuthTwitterEngine *)twitter
{
    if (!twitter)
        twitter = [[YHOAuthTwitterEngine alloc] initOAuthWithDelegate:self];

    return twitter;
}

@end
