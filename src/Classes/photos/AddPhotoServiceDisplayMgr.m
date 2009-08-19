//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "AddPhotoServiceDisplayMgr.h"
#import "PhotoService.h"
#import "PhotoService+ServiceAdditions.h"

@interface AddPhotoServiceDisplayMgr ()

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) PhotoServiceSelectorViewController *
    photoServiceSelectorViewController;

@property (nonatomic, retain) NSManagedObjectContext * context;

@end

@implementation AddPhotoServiceDisplayMgr

@synthesize navigationController, photoServiceSelectorViewController;
@synthesize context;

- (void)dealloc
{
    self.navigationController = nil;
    self.photoServiceSelectorViewController = nil;

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

- (void)addPhotoService:(TwitterCredentials *)credentials
{
    [self.navigationController
        pushViewController:self.photoServiceSelectorViewController
                  animated:YES];
}

#pragma mark PhotoServiceSelectorViewControllerDelegate implementation

- (NSDictionary *)photoServices
{
    return [PhotoService photoServiceNamesAndLogos];
}

- (void)userDidSelectServiceNamed:(NSString *)serviceName
{
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
