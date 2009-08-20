//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "TwitPicEditPhotoServiceDisplayMgr.h"
#import "TwitterCredentials.h"

@interface TwitPicEditPhotoServiceDisplayMgr ()

@property (nonatomic, retain) TwitPicCredentials * credentials;
@property (nonatomic, retain) NSManagedObjectContext * context;

@property (nonatomic, retain) UINavigationController * navigationController;
@property (nonatomic, retain) TwitPicSettingsViewController * viewController;

@end

@implementation TwitPicEditPhotoServiceDisplayMgr

@synthesize credentials, context;
@synthesize navigationController, viewController;

- (void)dealloc
{
    self.credentials = nil;
    self.context = nil;

    self.navigationController = nil;
    self.viewController = nil;

    [super dealloc];
}

- (id)init
{
    return self = [super init];
}

- (void)editServiceWithCredentials:(PhotoServiceCredentials *)someCredentials
              navigationController:(UINavigationController *)aController
                           context:(NSManagedObjectContext *)aContext
{
    NSAssert1([someCredentials isKindOfClass:[TwitPicCredentials class]],
        @"Expected twitpic credentials, but got: %@", [someCredentials class]);

    self.credentials = (TwitPicCredentials *) someCredentials;
    self.context = aContext;
    self.navigationController = aController;

    self.viewController.credentials = self.credentials;
    [self.navigationController pushViewController:self.viewController
                                         animated:YES];
}

#pragma mark TwitPicSettingsViewControllerDelegate implementation

- (void)deleteServiceWithCredentials:(TwitPicCredentials *)toDelete
{
    [self.navigationController popViewControllerAnimated:YES];
    self.viewController = nil;

    [self.delegate userWillDeleteAccountWithCredentials:toDelete];
    [toDelete.credentials removePhotoServiceCredentialsObject:toDelete];
    [self.context deleteObject:toDelete];
    [self.delegate userDidDeleteAccount];
}

#pragma mark Accessors

- (TwitPicSettingsViewController *)viewController
{
    if (!viewController) {
        viewController =
            [[TwitPicSettingsViewController alloc]
            initWithNibName:@"TwitPicSettingsView" bundle:nil];
        viewController.delegate = self;
    }

    return viewController;
}

@end
