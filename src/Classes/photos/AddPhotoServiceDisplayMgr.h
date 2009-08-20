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

    UIViewController * rootViewController;
    UINavigationController * navigationController;
    PhotoServiceSelectorViewController * photoServiceSelectorViewController;

    PhotoServiceLogInDisplayMgr * photoServiceLogInDisplayMgr;

    TwitterCredentials * credentials;
    NSManagedObjectContext * context;

    BOOL displayModally;
}

@property (nonatomic, assign) id<AddPhotoServiceDisplayMgrDelegate> delegate;

- (id)initWithContext:(NSManagedObjectContext *)aContext;

- (void)displayWithNavigationController:(UINavigationController *)aController;
- (void)displayModally:(UIViewController *)aController;

- (void)addPhotoService:(TwitterCredentials *)someCredentials;

// default is no
- (void)selectorAllowsCancel:(BOOL)allow;

@end
