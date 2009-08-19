//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"
#import "PhotoServiceSelectorViewController.h"
#import "PhotoServiceLogInDisplayMgr.h"
#import "PhotoServiceCredentials.h"

@protocol AddPhotoServiceDisplayMgrDelegate

- (void)photoServiceAdded:(PhotoServiceCredentials *)credentials;
- (void)addingPhotoServiceCancelled;

@end

@interface AddPhotoServiceDisplayMgr :
    NSObject
    <PhotoServiceSelectorViewControllerDelegate,
    PhotoServiceLogInDisplayMgrDelegate>
{
    id<AddPhotoServiceDisplayMgrDelegate> delegate;

    UINavigationController * navigationController;
    PhotoServiceSelectorViewController * photoServiceSelectorViewController;

    PhotoServiceLogInDisplayMgr * photoServiceLogInDisplayMgr;

    TwitterCredentials * credentials;
    NSManagedObjectContext * context;
}

@property (nonatomic, assign) id<AddPhotoServiceDisplayMgrDelegate> delegate;

- (id)initWithNavigationController:(UINavigationController *)aNavController
                           context:(NSManagedObjectContext *)aContext;

- (void)addPhotoService:(TwitterCredentials *)someCredentials;

@end
