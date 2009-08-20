//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServicesDisplayMgr.h"
#import "PhotoService.h"
#import "PhotoService+ServiceAdditions.h"
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

- (BOOL)canSelectPhotoService
{
    return [self availablePhotoServices].count > 0;
}

- (BOOL)canSelectVideoService
{
    return [self availableVideoServices].count > 0;
}

- (void)selectServiceForPhotos
{
    [self.navigationController
        pushViewController:self.photoServiceSelectionViewController
                  animated:YES];
}

- (void)selectServiceForVideos
{
    [self.navigationController
        pushViewController:self.videoServiceSelectionViewController
                  animated:YES];
}

- (BOOL)areMoreServicesAvailable
{
    /*
    return self.credentials.photoServiceCredentials.count <
        [PhotoService photoServiceNamesAndLogos].count;
    */
    return self.credentials.photoServiceCredentials.count != 1;
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

- (void)photoServiceAdded:(PhotoServiceCredentials *)ctls
{
    NSString * serviceName = [ctls serviceName];

    NSString * photoService = [self currentlySelectedPhotoServiceName];
    if (!photoService && [ctls supportsPhotos])
        [self.delegate userDidSelectPhotoServiceWithName:serviceName
                                             credentials:self.credentials];

    NSString * videoService = [self currentlySelectedVideoServiceName];
    if (!videoService && [ctls supportsVideo])
        [self.delegate userDidSelectVideoServiceWithName:serviceName
                                             credentials:self.credentials];

    [self.navigationController
        popToViewController:self.photoServicesViewController animated:NO];
}

- (void)addingPhotoServiceCancelled
{
}

#pragma mark EditPhotoServiceDisplayMgrDelegate implementation

- (void)userWillDeleteAccountWithCredentials:(PhotoServiceCredentials *)ctls
{
    NSString * serviceName = [ctls serviceName];
    NSString * currentPhotoService = [self currentlySelectedPhotoServiceName];
    NSString * currentVideoService = [self currentlySelectedVideoServiceName];

    if ([serviceName isEqualToString:currentPhotoService]) {
        // pick a new default
        BOOL newDefaultSet = NO;
        NSSet * photoServices = self.credentials.photoServiceCredentials;
        for (PhotoServiceCredentials * service in photoServices) {
            if (![service isEqual:ctls] && [service supportsPhotos]) {
                NSString * newServiceName = [service serviceName];
                [self.delegate
                    userDidSelectPhotoServiceWithName:newServiceName
                                          credentials:self.credentials];
                newDefaultSet = YES;
            }
        }

        if (!newDefaultSet)  // no valid options remain
            [self.delegate userDidSelectPhotoServiceWithName:nil
                                                 credentials:self.credentials];
    }

    if ([serviceName isEqualToString:currentVideoService]) {
        // pick a new default
        BOOL newDefaultSet = NO;
        NSSet * photoServices = self.credentials.photoServiceCredentials;
        for (PhotoServiceCredentials * service in photoServices) {
            if (![service isEqual:ctls] && [service supportsVideo]) {
                NSString * newServiceName = [service serviceName];
                [self.delegate
                    userDidSelectVideoServiceWithName:newServiceName
                                          credentials:self.credentials];
                newDefaultSet = YES;
            }
        }

        if (!newDefaultSet)  // no valid service installed
            [self.delegate
                userDidSelectVideoServiceWithName:nil
                                      credentials:self.credentials];
    }
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
    NSArray * allCredentials =
        [self.credentials.photoServiceCredentials allObjects];
    NSPredicate * predicate =
        [NSPredicate predicateWithFormat:@"supportsVideo == YES"];
    NSArray * filtered = [allCredentials filteredArrayUsingPredicate:predicate];

    return filtered;
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
            [[AddPhotoServiceDisplayMgr alloc] initWithContext:self.context];
        [addPhotoServiceDisplayMgr
            displayWithNavigationController:self.navigationController];
        addPhotoServiceDisplayMgr.delegate = self;
    }

    return addPhotoServiceDisplayMgr;
}

@end
