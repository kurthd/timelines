//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AddPhotoServiceDisplayMgr.h"
#import "PhotoService.h"
#import "PhotoService+ServiceAdditions.h"
#import "NSArray+IterationAdditions.h"

@interface AddPhotoServiceDisplayMgr ()

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
@synthesize navigationController, photoServiceSelectorViewController;
@synthesize photoServiceLogInDisplayMgr;
@synthesize credentials, context;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationController = nil;
    self.photoServiceSelectorViewController = nil;

    self.photoServiceLogInDisplayMgr = nil;

    self.credentials = nil;
    self.context = nil;

    [super dealloc];
}

- (id)initWithNavigationController:(UINavigationController *)aNavController
                           context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.navigationController = aNavController;
        self.context = aContext;
    }

    return self;
}

#pragma mark Public implementaion

- (void)addPhotoService:(TwitterCredentials *)someCredentials
{
    self.credentials = someCredentials;
    [self.navigationController
        pushViewController:self.photoServiceSelectorViewController
                  animated:YES];
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

        if (![serviceName isEqualToString:@"TwitPic"])
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
    }

    return photoServiceSelectorViewController;
}

@end
