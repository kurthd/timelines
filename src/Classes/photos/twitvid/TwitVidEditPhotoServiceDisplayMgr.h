//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditPhotoServiceDisplayMgr.h"
#import "TwitVidSettingsViewController.h"
#import "TwitterBasicAuthAuthenticator.h"

@interface TwitVidEditPhotoServiceDisplayMgr :
    EditPhotoServiceDisplayMgr
    <TwitVidSettingsViewControllerDelegate,
    TwitterBasicAuthAuthenticatorDelegate>
{
    TwitVidCredentials * credentials;
    NSManagedObjectContext * context;

    UINavigationController * navigationController;
    TwitVidSettingsViewController * viewController;
}

- (id)init;

- (void)editServiceWithCredentials:(PhotoServiceCredentials *)credentials
              navigationController:(UINavigationController *)controller
                           context:(NSManagedObjectContext *)context;

@end
