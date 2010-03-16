//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditPhotoServiceDisplayMgr.h"
#import "PosterousSettingsViewController.h"
#import "TwitterBasicAuthAuthenticator.h"

@interface PosterousEditPhotoServiceDisplayMgr :
    EditPhotoServiceDisplayMgr
    <PosterousSettingsViewControllerDelegate,
    TwitterBasicAuthAuthenticatorDelegate>
{
    PosterousCredentials * credentials;
    NSManagedObjectContext * context;

    UINavigationController * navigationController;
    PosterousSettingsViewController * viewController;
}

- (id)init;

- (void)editServiceWithCredentials:(PhotoServiceCredentials *)credentials
              navigationController:(UINavigationController *)controller
                           context:(NSManagedObjectContext *)context;

@end
