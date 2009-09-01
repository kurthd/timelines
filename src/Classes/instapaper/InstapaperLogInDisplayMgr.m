//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "InstapaperLogInDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "InstapaperCredentials.h"
#import "InstapaperCredentials+KeychainAdditions.h"

@interface InstapaperLogInDisplayMgr ()

@property (nonatomic, retain) InstapaperLogInViewController * viewController;
@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) InstapaperService * instapaperService;

@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation InstapaperLogInDisplayMgr

@synthesize viewController, navigationController, rootViewController;
@synthesize instapaperService;
@synthesize credentials, context;

- (void)dealloc
{
    self.viewController = nil;
    self.rootViewController = nil;
    self.navigationController = nil;

    self.instapaperService = nil;

    self.credentials = nil;
    self.context = nil;

    [super dealloc];
}

- (id)initWithCredentials:(TwitterCredentials *)someCredentials
                  context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.credentials = someCredentials;
        self.context = aContext;
        authenticating = NO;
    }

    return self;
}

- (void)logInModallyForViewController:(UIViewController *)aRootViewController
{
    self.viewController = nil;
    self.rootViewController = aRootViewController;

    UINavigationController * navController =
        [[UINavigationController alloc]
        initWithRootViewController:self.viewController];
    self.navigationController = navController;
    [navController release];

    [self.rootViewController
        presentModalViewController:self.navigationController animated:YES];
}

#pragma mark InstapaperLogInViewControllerDelegate implementation

- (void)userDidSave:(NSString *)username password:(NSString *)password
{
    [self.viewController displayActivity];

    NSLog(@"Authenticating Instapaper username: '%@'.", username);
    [self.instapaperService authenticateUsername:username password:password];
    authenticating = YES;
}

- (void)userDidCancel
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];
    if (authenticating)
        [self.instapaperService cancelAuthentication];
}

#pragma mark InstapaperServiceDelegate implementation

-(void)authenticatedUsername:(NSString *)username
                    password:(NSString *)password
{
    NSLog(@"'%@': Successfully authenticated Instapaper account.", username);

    InstapaperCredentials * instapaperCredentials =
        [InstapaperCredentials createInstance:self.context];
    instapaperCredentials.username = username;
    [instapaperCredentials setPassword:password];
    instapaperCredentials.credentials = self.credentials;
    [self.context save:NULL];

    [self.viewController hideActivity];
    [self.rootViewController dismissModalViewControllerAnimated:YES];
    authenticating = NO;
}

- (void)failedToAuthenticateUsername:(NSString *)username
                            password:(NSString *)password
                               error:(NSError *)error
{
    NSString * title =
        NSLocalizedString(@"instapaper.login.failed.alert.title", @"");
    NSString * message = error.localizedDescription;

    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];

    [self.viewController hideActivity];
    authenticating = NO;
}

- (void)postedUrl:(NSString *)url
{
}

- (void)failedToPostUrl:(NSString *)url error:(NSError *)error
{
}

#pragma mark Accessors

- (InstapaperLogInViewController *)viewController
{
    if (!viewController)
        viewController =
            [[InstapaperLogInViewController alloc] initWithDelegate:self];

    return viewController;
}

- (InstapaperService *)instapaperService
{
    if (!instapaperService) {
        instapaperService = [[InstapaperService alloc] init];
        instapaperService.delegate = self;
    }

    return instapaperService;
}

@end
