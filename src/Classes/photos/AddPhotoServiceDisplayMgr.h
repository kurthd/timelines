//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"
#import "PhotoServiceSelectorViewController.h"

@interface AddPhotoServiceDisplayMgr :
    NSObject <PhotoServiceSelectorViewControllerDelegate>
{
    UINavigationController * navigationController;
    PhotoServiceSelectorViewController * photoServiceSelectorViewController;

    NSManagedObjectContext * context;
}

- (id)initWithNavigationController:(UINavigationController *)aNavController
                           context:(NSManagedObjectContext *)aContext;

- (void)addPhotoService:(TwitterCredentials *)credentials;

@end
