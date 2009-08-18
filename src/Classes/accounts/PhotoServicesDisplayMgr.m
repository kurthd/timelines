//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "PhotoServicesDisplayMgr.h"

@interface PhotoServicesDisplayMgr ()

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) PhotoServicesViewController *
    photoServicesViewController;

@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation PhotoServicesDisplayMgr

@synthesize delegate;
@synthesize navigationController, photoServicesViewController;
@synthesize context;

- (void)dealloc
{
    self.delegate = nil;

    self.navigationController = nil;
    self.photoServicesViewController = nil;

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

@end
