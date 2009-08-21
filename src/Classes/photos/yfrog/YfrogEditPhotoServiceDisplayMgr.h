//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditPhotoServiceDisplayMgr.h"
#import "YfrogSettingsViewController.h"
#import "TwitterBasicAuthAuthenticator.h"

@interface YfrogEditPhotoServiceDisplayMgr :
    EditPhotoServiceDisplayMgr
    <YfrogSettingsViewControllerDelegate,
    TwitterBasicAuthAuthenticatorDelegate>
{
    YfrogCredentials * credentials;
    NSManagedObjectContext * context;

    UINavigationController * navigationController;
    YfrogSettingsViewController * viewController;
}

- (id)init;

- (void)editServiceWithCredentials:(PhotoServiceCredentials *)credentials
              navigationController:(UINavigationController *)controller
                           context:(NSManagedObjectContext *)context;

@end
