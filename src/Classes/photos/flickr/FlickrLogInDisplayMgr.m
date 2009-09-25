//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrLogInDisplayMgr.h"
#import "FlickrCredentials.h"
#import "NSManagedObject+TediousCodeAdditions.h"
#import "FlickrPhotoService.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface FlickrLogInDisplayMgr ()

@property (nonatomic, retain) UINavigationController *
    explainNavigationController;
@property (nonatomic, retain) ExplainFlickrAuthViewController *
    explainViewController;

@property (nonatomic, retain) UINavigationController *
    flickrLogInNavigationController;
@property (nonatomic, retain) FlickrLogInViewController *
    flickrLogInViewController;

@property (nonatomic, retain) OFFlickrAPIContext * flickrContext;
@property (nonatomic, retain) OFFlickrAPIRequest * getFrobRequest;
@property (nonatomic, retain) OFFlickrAPIRequest * getTokenRequest;

@property (nonatomic, copy) NSURL * flickrLogInUrl;
@property (nonatomic, copy) NSString * frob;

@end

@implementation FlickrLogInDisplayMgr

@synthesize explainNavigationController, explainViewController;
@synthesize flickrLogInNavigationController, flickrLogInViewController;
@synthesize flickrContext, getFrobRequest, getTokenRequest;
@synthesize flickrLogInUrl, frob;

- (void)dealloc
{
    self.explainNavigationController = nil;
    self.explainViewController = nil;

    self.flickrLogInNavigationController = nil;
    self.flickrLogInViewController = nil;

    self.flickrContext = nil;
    self.getFrobRequest = nil;
    self.getTokenRequest = nil;

    self.flickrLogInUrl = nil;
    self.frob = nil;

    [super dealloc];
}

- (id)init
{
    if (self = [super init]) {
        NSString * apiKey = [FlickrPhotoService apiKey];
        NSString * secret = [FlickrPhotoService sharedSecret];
        flickrContext =
            [[OFFlickrAPIContext alloc] initWithAPIKey:apiKey
                                          sharedSecret:secret];
    }

    return self;
}

- (void)logInWithRootViewController:(UIViewController *)aController
                        credentials:(TwitterCredentials *)someCredentials
                            context:(NSManagedObjectContext *)aContext
{
    [super logInWithRootViewController:aController
                           credentials:someCredentials
                               context:aContext];

    [self.rootViewController
        presentModalViewController:self.explainNavigationController
                          animated:YES];
}

#pragma mark ExplainFlickrAuthViewControllerDelegate implementation

- (void)beginAuthorization
{
    [self.explainViewController showActivityView];

    self.getFrobRequest =
        [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
    [self.getFrobRequest setDelegate:self];

    NSString * apiKey = [FlickrPhotoService apiKey];
    NSDictionary * args =
        [NSDictionary dictionaryWithObject:apiKey forKey:@"api_key"];
    [self.getFrobRequest
        callAPIMethodWithGET:@"flickr.auth.getFrob" arguments:args];
}

- (void)userDidCancelExplanation
{
    [self.rootViewController dismissModalViewControllerAnimated:YES];
    [self.delegate logInCancelled];
}

#pragma mark FlickrLogInViewControllerDelegate implementation

- (NSURL *)flickrLogInUrl
{
    return flickrLogInUrl;
}

- (void)userDidAuthorizeFlickr
{
    self.getTokenRequest =
        [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
    [self.getTokenRequest setDelegate:self];

    NSDictionary * args =
        [NSDictionary dictionaryWithObjectsAndKeys:
        [FlickrPhotoService apiKey], @"api_key", self.frob, @"frob", nil];
    [self.getTokenRequest
        callAPIMethodWithGET:@"flickr.auth.getToken" arguments:args];

    [self.explainViewController showAuthorizingView];
    [self.explainViewController dismissModalViewControllerAnimated:YES];
}

- (void)userDidCancelFlickrLogIn
{
    self.flickrLogInUrl = nil;
    [self.explainViewController showButtonView];
    [self.explainViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark OFFlickrAPIRequestDelegate implementation

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request
 didCompleteWithResponse:(NSDictionary *)response
{
    if (request == self.getFrobRequest) {
        self.frob = [[response objectForKey:@"frob"] objectForKey:@"_text"];
        self.flickrLogInUrl =
            [self.flickrContext loginURLFromFrobDictionary:response
                                       requestedPermission:@"write"];

        [self.explainViewController
            presentModalViewController:self.flickrLogInNavigationController
                              animated:YES];

        [self.getFrobRequest autorelease];
        getFrobRequest = nil;
    } else if (request == self.getTokenRequest) {
        NSString * token =
            [[[response objectForKey:@"auth"]
                        objectForKey:@"token"]
                        objectForKey:@"_text"];
        NSDictionary * userAttrs =
            [[response objectForKey:@"auth"] objectForKey:@"user"];

        FlickrCredentials * ctls =
            [FlickrCredentials createInstance:self.context];
        ctls.username = [userAttrs objectForKey:@"username"];
        ctls.fullName = [userAttrs objectForKey:@"fullname"];
        ctls.userId = [userAttrs objectForKey:@"nsid"];
        ctls.token = token;
        ctls.credentials = self.credentials;

        [self.context save:NULL];

        [self performSelector:@selector(dismissModalViewController:)
                   withObject:[NSNumber numberWithBool:YES]
                   afterDelay:0.2];

        [self.delegate logInCompleted:ctls];
    }
}

- (void)dismissModalViewController:(NSNumber *)shouldAnimate
{
    BOOL animated = [shouldAnimate boolValue];
    [self.rootViewController dismissModalViewControllerAnimated:animated];
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest
        didFailWithError:(NSError *)inError
{
    NSLog(@"Request failed with error: %@", inError);

    NSString * title =
        NSLocalizedString(@"flickr.login.failed.alert.title", @"");
    NSString * message = inError.localizedDescription;
    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];

    [self.explainViewController showButtonView];

    [inRequest autorelease];
}

#pragma mark Accessors

- (UINavigationController *)explainNavigationController
{
    if (!explainNavigationController)
        explainNavigationController =
            [[UINavigationController alloc]
            initWithRootViewController:self.explainViewController];

    return explainNavigationController;
}

- (ExplainFlickrAuthViewController *)explainViewController
{
    if (!explainViewController)
        explainViewController =
            [[ExplainFlickrAuthViewController alloc] initWithDelegate:self];

    return explainViewController;
}

- (UINavigationController *)flickrLogInNavigationController
{
    if (!flickrLogInNavigationController)
        flickrLogInNavigationController =
            [[UINavigationController alloc]
            initWithRootViewController:self.flickrLogInViewController];

    return flickrLogInNavigationController;
}

- (FlickrLogInViewController *)flickrLogInViewController
{
    if (!flickrLogInViewController)
        flickrLogInViewController =
            [[FlickrLogInViewController alloc] initWithDelegate:self];

    return flickrLogInViewController;
}

@end
