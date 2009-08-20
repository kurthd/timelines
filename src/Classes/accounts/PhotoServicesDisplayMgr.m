//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServicesDisplayMgr.h"

@interface PhotoServicesDisplayMgr ()

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) PhotoServicesViewController *
    photoServicesViewController;

@property (nonatomic, retain) EditPhotoServiceDisplayMgr *
    editPhotoServiceDisplayMgr;
@property (nonatomic, retain) AddPhotoServiceDisplayMgr *
    addPhotoServiceDisplayMgr;

@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation PhotoServicesDisplayMgr

@synthesize delegate;
@synthesize navigationController, photoServicesViewController;
@synthesize editPhotoServiceDisplayMgr, addPhotoServiceDisplayMgr;
@synthesize context;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationController = nil;
    self.photoServicesViewController = nil;

    self.editPhotoServiceDisplayMgr = nil;
    self.addPhotoServiceDisplayMgr = nil;

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

#pragma mark Public implementation

- (void)configurePhotoServicesForAccount:(TwitterCredentials *)credentials
{
    self.photoServicesViewController.credentials = credentials;
    [self.navigationController
        pushViewController:self.photoServicesViewController animated:YES];
}

#pragma mark PhotoServicesViewControllerDelegate implementation

- (NSArray *)servicesForAccount:(TwitterCredentials *)credentials
{
    return [credentials.photoServiceCredentials allObjects];
}

- (void)userWantsToEditAccountAtIndex:(NSUInteger)index
                          credentials:(TwitterCredentials *)credentials
{
    NSArray * services = [self servicesForAccount:credentials];
    PhotoServiceCredentials * service = [services objectAtIndex:index];

    EditPhotoServiceDisplayMgr * mgr =
        [EditPhotoServiceDisplayMgr
        editServiceDisplayMgrWithServiceName:[service serviceName]];
    mgr.delegate = self;

    [mgr editServiceWithCredentials:service
               navigationController:self.navigationController
                            context:self.context];

    self.editPhotoServiceDisplayMgr = mgr;
}

- (void)userWantsToAddNewPhotoService:(TwitterCredentials *)credentials
{
    NSLog(@"'%@': adding a new photo service.", credentials.username);
    [self.addPhotoServiceDisplayMgr addPhotoService:credentials];
}

#pragma mark AddPhotoServiceDisplayMgrDelegate implementation

- (void)photoServiceAdded:(PhotoServiceCredentials *)credentials
{
    [self.navigationController
        popToViewController:self.photoServicesViewController animated:NO];
}

- (void)addingPhotoServiceCancelled
{
}

#pragma mark EditPhotoServiceDisplayMgrDelegate implementation

- (void)userWillDeleteAccountWithCredentials:(PhotoServiceCredentials *)ctls
{
}

- (void)userDidDeleteAccount
{
    [self.photoServicesViewController reloadDisplay];
}

#pragma mark Accessors

- (PhotoServicesViewController *)photoServicesViewController
{
    if (!photoServicesViewController) {
        photoServicesViewController =
            [[PhotoServicesViewController alloc]
            initWithNibName:@"PhotoServicesView" bundle:nil];
        photoServicesViewController.delegate = self;
    }

    return photoServicesViewController;
}

- (AddPhotoServiceDisplayMgr *)addPhotoServiceDisplayMgr
{
    if (!addPhotoServiceDisplayMgr) {
        addPhotoServiceDisplayMgr =
            [[AddPhotoServiceDisplayMgr alloc]
            initWithNavigationController:self.navigationController
                                 context:context];
        addPhotoServiceDisplayMgr.delegate = self;
    }

    return addPhotoServiceDisplayMgr;
}

@end
