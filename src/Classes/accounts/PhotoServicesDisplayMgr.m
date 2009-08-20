//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServicesDisplayMgr.h"
#import "NSArray+IterationAdditions.h"

@interface PhotoServicesDisplayMgr ()

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) PhotoServicesViewController *
    photoServicesViewController;

@property (nonatomic, retain) EditPhotoServiceDisplayMgr *
    editPhotoServiceDisplayMgr;
@property (nonatomic, retain) AddPhotoServiceDisplayMgr *
    addPhotoServiceDisplayMgr;
@property (nonatomic, retain) SelectionViewController *
    photoServiceSelectionViewController;
@property (nonatomic, retain) SelectionViewController *
    videoServiceSelectionViewController;

@property (nonatomic, retain) TwitterCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;

- (NSArray *)availablePhotoServices;
- (NSArray *)availableVideoServices;

@end

@implementation PhotoServicesDisplayMgr

@synthesize delegate;
@synthesize navigationController, photoServicesViewController;
@synthesize photoServiceSelectionViewController;
@synthesize videoServiceSelectionViewController;
@synthesize editPhotoServiceDisplayMgr, addPhotoServiceDisplayMgr;
@synthesize credentials, context;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationController = nil;
    self.photoServicesViewController = nil;
    self.photoServiceSelectionViewController = nil;
    self.videoServiceSelectionViewController = nil;

    self.editPhotoServiceDisplayMgr = nil;
    self.addPhotoServiceDisplayMgr = nil;

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

#pragma mark Public implementation

- (void)configurePhotoServicesForAccount:(TwitterCredentials *)someCredentials
{
    self.credentials = someCredentials;
    self.photoServicesViewController.credentials = self.credentials;
    [self.navigationController
        pushViewController:self.photoServicesViewController animated:YES];
}

#pragma mark PhotoServicesViewControllerDelegate implementation

- (NSString *)currentlySelectedPhotoServiceName
{
    return [self.delegate currentlySelectedPhotoServiceName:self.credentials];
}

- (NSString *)currentlySelectedVideoServiceName
{
    return [self.delegate currentlySelectedVideoServiceName:self.credentials];
}

- (void)selectServiceForPhotos
{
    [self.navigationController
        pushViewController:self.photoServiceSelectionViewController
                  animated:YES];
}

- (void)selectServiceForVideos
{
}

- (NSArray *)servicesForAccount:(TwitterCredentials *)someCredentials
{
    return [someCredentials.photoServiceCredentials allObjects];
}

- (void)userWantsToEditAccountAtIndex:(NSUInteger)index
                          credentials:(TwitterCredentials *)someCredentials
{
    NSArray * services = [self servicesForAccount:someCredentials];
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

- (void)userWantsToAddNewPhotoService:(TwitterCredentials *)someCredentials
{
    NSLog(@"'%@': adding a new photo service.", someCredentials.username);
    [self.addPhotoServiceDisplayMgr addPhotoService:someCredentials];
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

#pragma mark SelectionViewControllerDelegate implementation

- (NSArray *)allChoices:(SelectionViewController *)controller
{
    NSArray * photoCredentials = nil;

    if (controller == self.photoServiceSelectionViewController)
        photoCredentials = [self availablePhotoServices];
    else if (controller == self.videoServiceSelectionViewController)
        photoCredentials = [self availableVideoServices];

    SEL sel = @selector(serviceName);
    return [photoCredentials arrayByTransformingObjectsUsingSelector:sel];
}

- (NSInteger)initialSelectedIndex:(SelectionViewController *)controller
{
    NSString * selection = [self currentlySelectedPhotoServiceName];
    NSArray * choices = [self allChoices:controller];

    return [choices indexOfObject:selection];
}

- (void)selectionViewController:(SelectionViewController *)controller
       userDidSelectItemAtIndex:(NSInteger)index
{
    NSArray * choices = [self allChoices:controller];

    if (controller == self.photoServiceSelectionViewController) {
        NSString * name = [choices objectAtIndex:index];
        [self.delegate userDidSelectPhotoServiceWithName:name
                                             credentials:self.credentials];
    } else if (controller == self.videoServiceSelectionViewController) {
        NSString * name = [choices objectAtIndex:index];
        [self.delegate userDidSelectVideoServiceWithName:name
                                             credentials:self.credentials];
    }
}

#pragma mark Private implementation

- (NSArray *)availablePhotoServices
{
    NSArray * allCredentials =
        [self.credentials.photoServiceCredentials allObjects];
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"supportsPhotos == YES"];
    NSArray * filtered = [allCredentials filteredArrayUsingPredicate:predicate];

    return filtered;
}

- (NSArray *)availableVideoServices
{
    return [NSArray array];
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

- (SelectionViewController *)photoServiceSelectionViewController
{
    if (!photoServiceSelectionViewController) {
        photoServiceSelectionViewController =
            [[SelectionViewController alloc]
            initWithNibName:@"SelectionView" bundle:nil];
        photoServiceSelectionViewController.delegate = self;
        photoServiceSelectionViewController.viewTitle =
            NSLocalizedString(@"selectphotoserviceview.view.title", @"");
    }

    return photoServiceSelectionViewController;
}

- (SelectionViewController *)videoServiceSelectionViewController
{
    if (!videoServiceSelectionViewController) {
        videoServiceSelectionViewController =
            [[SelectionViewController alloc]
            initWithNibName:@"SelectionView" bundle:nil];
        videoServiceSelectionViewController.delegate = self;
        videoServiceSelectionViewController.viewTitle =
            NSLocalizedString(@"selectvideoserviceview.view.title", @"");
    }

    return videoServiceSelectionViewController;
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
