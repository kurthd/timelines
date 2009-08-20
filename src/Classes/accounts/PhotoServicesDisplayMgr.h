//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoServicesViewController.h"
#import "AddPhotoServiceDisplayMgr.h"
#import "TwitterCredentials.h"
#import "EditPhotoServiceDisplayMgr.h"
#import "SelectionViewController.h"

@protocol PhotoServicesDisplayMgrDelegate

- (NSString *)currentlySelectedPhotoServiceName:(TwitterCredentials *)ctls;
- (NSString *)currentlySelectedVideoServiceName:(TwitterCredentials *)ctls;

- (void)userDidSelectPhotoServiceWithName:(NSString *)name
                              credentials:(TwitterCredentials *)ctls;
- (void)userDidSelectVideoServiceWithName:(NSString *)name
                              credentials:(TwitterCredentials *)ctls;

@end

@interface PhotoServicesDisplayMgr :
    NSObject
    <PhotoServicesViewControllerDelegate,
    EditPhotoServiceDisplayMgrDelegate,
    AddPhotoServiceDisplayMgrDelegate,
    SelectionViewControllerDelegate>
{
    id<PhotoServicesDisplayMgrDelegate> delegate;

    UINavigationController * navigationController;
    PhotoServicesViewController * photoServicesViewController;

    SelectionViewController * photoServiceSelectionViewController;
    SelectionViewController * videoServiceSelectionViewController;

    EditPhotoServiceDisplayMgr * editPhotoServiceDisplayMgr;
    AddPhotoServiceDisplayMgr * addPhotoServiceDisplayMgr;

    TwitterCredentials * credentials;
    NSManagedObjectContext * context;
}

@property (nonatomic, assign) id<PhotoServicesDisplayMgrDelegate> delegate;

- (id)initWithNavigationController:(UINavigationController *)aNavController
                           context:(NSManagedObjectContext *)aContext;

- (void)configurePhotoServicesForAccount:(TwitterCredentials *)credentials;

@end
