//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditPhotoServiceDisplayMgr.h"
#import "FlickrCredentials.h"
#import "FlickrSettingsViewController.h"

@interface FlickrEditPhotoServiceDisplayMgr :
    EditPhotoServiceDisplayMgr <FlickrSettingsViewControllerDelegate>
{
    FlickrCredentials * credentials;
    NSManagedObjectContext * context;

    UINavigationController * navigationController;
    FlickrSettingsViewController * settingsViewController;
}

- (id)init;

- (void)editServiceWithCredentials:(FlickrCredentials *)credentials
              navigationController:(UINavigationController *)controller
                           context:(NSManagedObjectContext *)context;

@end
