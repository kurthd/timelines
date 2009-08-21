//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AddPhotoServiceDisplayMgr.h"
#import "PhotoService.h"
#import "PhotoService+ServiceAdditions.h"
#import "NSArray+IterationAdditions.h"

@interface AddPhotoServiceDisplayMgr ()

@property (nonatomic, retain) UIViewController * rootViewController;
@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) PhotoServiceSelectorViewController *
    photoServiceSelectorViewController;

@property (nonatomic, retain) PhotoServiceLogInDisplayMgr *
    photoServiceLogInDisplayMgr;

@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation AddPhotoServiceDisplayMgr

@synthesize delegate;
@synthesize rootViewController, navigationController;
@synthesize photoServiceSelectorViewController;
@synthesize photoServiceLogInDisplayMgr;
@synthesize credentials, context;

- (void)dealloc
{
    self.delegate = nil;

    self.rootViewController = nil;
    self.navigationController = nil;
    self.photoServiceSelectorViewController = nil;

    self.photoServiceLogInDisplayMgr = nil;

    self.credentials = nil;
    self.context = nil;

    [super dealloc];
}

- (id)initWithContext:(NSManagedObjectContext *)aContext
{
    if (self = [super init])
        self.context = aContext;

    return self;
}

#pragma mark Public implementaion

- (void)displayWithNavigationController:(UINavigationController *)aController
{
    self.navigationController = aController;
    self.rootViewController = nil;
    displayModally = NO;
}

- (void)displayModally:(UIViewController *)aController
{
    self.navigationController = nil;
    self.rootViewController = aController;
    displayModally = YES;
}

- (void)addPhotoService:(TwitterCredentials *)someCredentials
{
    self.credentials = someCredentials;

    if (displayModally) {
        UINavigationController * navController =
            [[UINavigationController alloc]
            initWithRootViewController:self.photoServiceSelectorViewController];
        self.navigationController = navController;
        [navController release];

        [self.rootViewController
            presentModalViewController:self.navigationController
                              animated:YES];
    } else
        [self.navigationController
            pushViewController:self.photoServiceSelectorViewController
                      animated:YES];
}

- (void)selectorAllowsCancel:(BOOL)allow
{
    self.photoServiceSelectorViewController.allowCancel = allow;
}

#pragma mark PhotoServiceSelectorViewControllerDelegate implementation

- (NSDictionary *)photoServices
{
    // Supply the list of services, with the user's currently installed
    // services removed.

    NSMutableDictionary * remainingServices =
        [[PhotoService photoServiceNamesAndLogos] mutableCopy];

    NSSet * userServices = self.credentials.photoServiceCredentials;
    NSSet * userServiceNames =
        [NSSet setWithArray:
        [[userServices allObjects]
        arrayByTransformingObjectsUsingSelector:@selector(serviceName)]];

    for (NSString * serviceName in [remainingServices allKeys]) {
        if ([userServiceNames containsObject:serviceName])
            [remainingServices removeObjectForKey:serviceName];

        NSSet * tempFilter =
            [NSSet setWithObjects:@"TwitPic", @"Yfrog", @"TwitVid", nil];
        if (![tempFilter containsObject:serviceName])
            [remainingServices removeObjectForKey:serviceName];
    }

    return remainingServices;
}

- (void)userSelectedServiceNamed:(NSString *)serviceName
{
    self.photoServiceLogInDisplayMgr =
        [PhotoServiceLogInDisplayMgr
        logInDisplayMgrWithServiceName:serviceName];
    self.photoServiceLogInDisplayMgr.delegate = self;

    [self.photoServiceLogInDisplayMgr
        logInWithRootViewController:self.navigationController
                        credentials:self.credentials
                            context:self.context];
}

- (void)userDidCancel
{
    [self.delegate addingPhotoServiceCancelled];
    if (displayModally)
        [self.rootViewController dismissModalViewControllerAnimated:YES];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark PhotoServiceLogInDisplayMgrDelegate implementation

- (void)logInCompleted:(PhotoServiceCredentials *)newCredentials
{
    [self.delegate photoServiceAdded:newCredentials];
}

- (void)logInCancelled
{
    [self.delegate addingPhotoServiceCancelled];
}

#pragma mark Accessors

- (PhotoServiceSelectorViewController *)photoServiceSelectorViewController
{
    if (!photoServiceSelectorViewController) {
        photoServiceSelectorViewController =
            [[PhotoServiceSelectorViewController alloc]
            initWithNibName:@"PhotoServiceSelectorView" bundle:nil];
        photoServiceSelectorViewController.delegate = self;
        photoServiceSelectorViewController.allowCancel = NO;
    }

    return photoServiceSelectorViewController;
}

@end
