//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "FlickrEditPhotoServiceDisplayMgr.h"
#import "TwitterCredentials.h"

@interface FlickrEditPhotoServiceDisplayMgr ()

@property (nonatomic, retain) FlickrCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) FlickrSettingsViewController *
    settingsViewController;

@end

@implementation FlickrEditPhotoServiceDisplayMgr

@synthesize credentials, context;
@synthesize navigationController, settingsViewController;

- (void)dealloc
{
    self.credentials = nil;
    self.context = nil;

    self.navigationController = nil;
    self.settingsViewController = nil;

    [super dealloc];
}

- (id)init
{
    return self = [super init];
}

#pragma mark Public implemetation

- (void)editServiceWithCredentials:(FlickrCredentials *)someCredentials
              navigationController:(UINavigationController *)aController
                           context:(NSManagedObjectContext *)aContext
{
    NSAssert1([someCredentials isKindOfClass:[FlickrCredentials class]],
        @"Expected flickr credentials, but got: %@", [someCredentials class]);

    self.credentials = someCredentials;
    self.context = aContext;
    self.navigationController = aController;

    self.settingsViewController.credentials = self.credentials;
    [self.navigationController pushViewController:self.settingsViewController
                                         animated:YES];
}

#pragma mark FlickrSettingsViewControllerDelegate implementation

- (void)deleteServiceWithCredentials:(FlickrCredentials *)toDelete
{
    [self.navigationController popViewControllerAnimated:YES];
    self.settingsViewController = nil;

    [self.delegate userWillDeleteAccountWithCredentials:toDelete];
    [toDelete.credentials removePhotoServiceCredentialsObject:toDelete];
    [self.context deleteObject:toDelete];
    [self.delegate userDidDeleteAccount];
}

#pragma mark Accessors

- (FlickrSettingsViewController *)settingsViewController
{
    if (!settingsViewController)
        settingsViewController =
            [[FlickrSettingsViewController alloc] initWithDelegate:self];

    return settingsViewController;
}

@end
