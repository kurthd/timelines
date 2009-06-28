//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "LogInDisplayMgr.h"
#import "LogInViewController.h"
#import "MGTwitterEngine.h"
#import "TwitterCredentials.h"
#import "TwitterCredentials+KeychainAdditions.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "UIApplication+NetworkActivityIndicatorAdditions.h"

#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "OAServiceTicket.h"

static NSString * OATH_KEY = @"YSfdtPCIvkvMkItCrc3OsQ";
static NSString * OATH_SECRET = @"M2mHASraAGv9kRu1KnyAXYb1snEbmRVrqneuHTCeY";

@interface LogInDisplayMgr ()

- (void)displayErrorWithMessage:(NSString *)message;
- (void)broadcastSuccessfulLogInNotification:(TwitterCredentials *)credentials;

@property (nonatomic, retain) NSManagedObjectContext * context;
@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) LogInViewController * logInViewController;
@property (nonatomic, retain) OauthLogInViewController * oauthLogInViewController;
@property (nonatomic, retain) MGTwitterEngine * twitter;
@property (nonatomic, copy) NSString * logInRequestId;
@property (nonatomic, retain) OAToken * requestToken;
@property (nonatomic, copy) NSString * username;
@property (nonatomic, copy) NSString * password;

@end

@implementation LogInDisplayMgr

@synthesize delegate;
@synthesize context;
@synthesize rootViewController, logInViewController, oauthLogInViewController;
@synthesize twitter, logInRequestId;
@synthesize requestToken;
@synthesize username, password;
@synthesize allowsCancel;

- (void)dealloc
{
    self.delegate = nil;

    self.context = nil;

    self.rootViewController = nil;
    self.logInViewController = nil;
    self.oauthLogInViewController = nil;

    self.twitter = nil;
    self.logInRequestId = nil;

    self.requestToken = nil;

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
    //[self.rootViewController presentModalViewController:self.logInViewController
    //                                           animated:animated];
    //[self.logInViewController promptForLogIn];

    OAConsumer * consumer = [[OAConsumer alloc] initWithKey:OATH_KEY
                                                     secret:OATH_SECRET];

    NSURL * url =
        [NSURL URLWithString:@"http://twitter.com/oauth/request_token"];
    OAMutableURLRequest * request =
        [[OAMutableURLRequest alloc] initWithURL:url
                                        consumer:consumer
                                           token:nil
                                           realm:nil
                               signatureProvider:nil];
    [request setHTTPMethod:@"POST"];

    OADataFetcher * fetcher = [[OADataFetcher alloc] init];

    SEL didFinishSelector = @selector(requestTokenTicket:didFinishWithData:);
    SEL didFailSelector = @selector(requestTokenTicket:didFailWithError:);
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:didFinishSelector
                  didFailSelector:didFailSelector];
}

#pragma mark OADataFetcher delegate implementation

- (void)requestTokenTicket:(OAServiceTicket *)ticket
         didFinishWithData:(NSData *)data
{
    if (ticket.didSucceed) {
        NSString * responseBody =
            [[NSString alloc] initWithData:data
                                  encoding:NSUTF8StringEncoding];
        self.requestToken =
            [[[OAToken alloc] initWithHTTPResponseBody:responseBody]
            autorelease];
        NSLog(@"My token key is: '%@', secret is: '%@'.", requestToken.key,
            requestToken.secret);

        NSURL * url = [NSURL URLWithString:
            [NSString stringWithFormat:@"http://twitter.com/oauth/"
            "authorize?oauth_token=%@&oauth_callback=oob", requestToken.key]];
        NSURLRequest * req = [NSURLRequest requestWithURL:url];
        [self.oauthLogInViewController loadRequest:req];

        [self.rootViewController presentModalViewController:self.oauthLogInViewController
                                                   animated:YES];
    }
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket
          didFailWithError:(NSError *)error
{
    [self displayErrorWithMessage:error.localizedDescription];
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

- (void)userIsDone:(NSString *)pin
{
    OAConsumer * consumer = [[OAConsumer alloc] initWithKey:OATH_KEY
                                                     secret:OATH_SECRET];

    NSURL * url =
        [NSURL URLWithString:@"http://twitter.com/oauth/access_token"];
    OAMutableURLRequest * request =
        [[OAMutableURLRequest alloc] initWithURL:url
                                        consumer:consumer
                                           token:self.requestToken
                                           realm:nil
                               signatureProvider:nil];
    [request setHTTPMethod:@"POST"];

    OADataFetcher * fetcher = [[OADataFetcher alloc] init];

    SEL didFinishSelector = @selector(accessTokenTicket:didFinishWithData:);
    SEL didFailSelector = @selector(accessTokenTicket:didFailWithError:);
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:didFinishSelector
                  didFailSelector:didFailSelector];
}

- (void)userDidCancel
{
    NSAssert(self.allowsCancel, @"User cancelled even though it's forbidden.");
    [self.rootViewController dismissModalViewControllerAnimated:YES];
}

- (BOOL)userCanCancel
{
    return self.allowsCancel;
}

#pragma mark Access token step of OAuth

- (void)accessTokenTicket:(OAServiceTicket *)ticket
        didFinishWithData:(NSData *)data
{
    if (ticket.didSucceed) {
        NSString * responseBody =
            [[NSString alloc] initWithData:data
                                  encoding:NSUTF8StringEncoding];
        self.requestToken =
            [[[OAToken alloc] initWithHTTPResponseBody:responseBody]
            autorelease];
        NSLog(@"My token key is: '%@', secret is: '%@'.", requestToken.key,
            requestToken.secret);
    }
}

- (void)accessTokenTicket:(OAServiceTicket *)ticket
         didFailWithError:(NSError *)error
{
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

    TwitterCredentials * credentials =
        (TwitterCredentials *) [NSEntityDescription
        insertNewObjectForEntityForName:@"TwitterCredentials"
                 inManagedObjectContext:context];

    credentials.username = self.username;
    credentials.password = self.password;

    NSError * error;
    if ([context save:&error]) {
        [self broadcastSuccessfulLogInNotification:credentials];
        [self.rootViewController dismissModalViewControllerAnimated:YES];
    } else {  // handle the error
        [self displayErrorWithMessage:error.localizedDescription];
        [self.logInViewController promptForLogIn];
    }

    [[UIApplication sharedApplication] networkActivityDidFinish];
}

- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error
{
    NSLog(@"Request '%@' failed; error: '%@'.", requestIdentifier, error);

    [self displayErrorWithMessage:error.localizedDescription];
    [self.logInViewController promptForLogIn];

    [[UIApplication sharedApplication] networkActivityDidFinish];
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

#pragma mark Accessors

- (LogInViewController *)logInViewController
{
    if (!logInViewController) {
        logInViewController =
            [[LogInViewController alloc] initWithNibName:@"LogInView"
                                                  bundle:nil];
        //logInViewController.delegate = self;
    }

    return logInViewController;
}

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

- (MGTwitterEngine *)twitter
{
    if (!twitter)
        twitter = [[MGTwitterEngine alloc] initWithDelegate:self];

    return twitter;
}

@end
