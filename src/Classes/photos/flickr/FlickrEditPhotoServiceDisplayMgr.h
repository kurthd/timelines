//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EditPhotoServiceDisplayMgr.h"
#import "FlickrCredentials.h"
#import "FlickrSettingsViewController.h"
#import "NetworkAwareViewController.h"
#import "FlickrTagsViewController.h"
#import "FlickrDataFetcher.h"

@interface FlickrEditPhotoServiceDisplayMgr :
    EditPhotoServiceDisplayMgr
    <FlickrSettingsViewControllerDelegate, NetworkAwareViewControllerDelegate,
    FlickrTagsViewControllerDelegate, FlickrDataFetcherDelegate>
{
    FlickrCredentials * credentials;
    NSManagedObjectContext * context;

    UINavigationController * navigationController;
    FlickrSettingsViewController * settingsViewController;

    NetworkAwareViewController * tagsNetViewController;
    FlickrTagsViewController * tagsViewController;

    NSArray * tags;

    FlickrDataFetcher * flickrDataFetcher;
}

- (id)init;

- (void)editServiceWithCredentials:(FlickrCredentials *)credentials
              navigationController:(UINavigationController *)controller
                           context:(NSManagedObjectContext *)context;

@end
