//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditPhotoServiceDisplayMgr.h"
#import "TwitPicSettingsViewController.h"

@interface TwitPicEditPhotoServiceDisplayMgr :
    EditPhotoServiceDisplayMgr <TwitPicSettingsViewControllerDelegate>
{
    TwitPicCredentials * credentials;
    NSManagedObjectContext * context;

    UINavigationController * navigationController;
    TwitPicSettingsViewController * viewController;
}

- (id)init;

- (void)editServiceWithCredentials:(PhotoServiceCredentials *)credentials
              navigationController:(UINavigationController *)controller
                           context:(NSManagedObjectContext *)context;

@end
