//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoServicesViewController.h"
#import "TwitterCredentials.h"

@protocol PhotoServicesDisplayMgrDelegate
@end

@interface PhotoServicesDisplayMgr :
    NSObject <PhotoServicesViewControllerDelegate>
{
    id<PhotoServicesDisplayMgrDelegate> delegate;

    UINavigationController * navigationController;
    PhotoServicesViewController * photoServicesViewController;

    NSManagedObjectContext * context;
}

@property (nonatomic, assign) id<PhotoServicesDisplayMgrDelegate> delegate;

- (id)initWithNavigationController:(UINavigationController *)aNavController
                           context:(NSManagedObjectContext *)aContext;

- (void)configurePhotoServicesForAccount:(TwitterCredentials *)credentials;

@end
