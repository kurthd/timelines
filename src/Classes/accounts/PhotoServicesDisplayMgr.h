//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoServicesViewController.h"
#import "AddPhotoServiceDisplayMgr.h"
#import "TwitterCredentials.h"
#import "EditPhotoServiceDisplayMgr.h"

@protocol PhotoServicesDisplayMgrDelegate
@end

@interface PhotoServicesDisplayMgr :
    NSObject
    <PhotoServicesViewControllerDelegate,
    EditPhotoServiceDisplayMgrDelegate, AddPhotoServiceDisplayMgrDelegate>
{
    id<PhotoServicesDisplayMgrDelegate> delegate;

    UINavigationController * navigationController;
    PhotoServicesViewController * photoServicesViewController;

    EditPhotoServiceDisplayMgr * editPhotoServiceDisplayMgr;
    AddPhotoServiceDisplayMgr * addPhotoServiceDisplayMgr;

    NSManagedObjectContext * context;
}

@property (nonatomic, assign) id<PhotoServicesDisplayMgrDelegate> delegate;

- (id)initWithNavigationController:(UINavigationController *)aNavController
                           context:(NSManagedObjectContext *)aContext;

- (void)configurePhotoServicesForAccount:(TwitterCredentials *)credentials;

@end
