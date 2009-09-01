//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TwitterCredentials.h"
#import "AccountSettingsViewController.h"
#import "PhotoServicesDisplayMgr.h"
#import "InstapaperLogInDisplayMgr.h"

@protocol AccountSettingsDisplayMgrDelegate
@end

@interface AccountSettingsDisplayMgr :
    NSObject <AccountSettingsViewControllerDelegate,
    PhotoServicesDisplayMgrDelegate, InstapaperLogInDisplayMgrDelegate>
{
    id<AccountSettingsDisplayMgrDelegate> delegate;

    UINavigationController * navigationController;
    AccountSettingsViewController * accountSettingsViewController;

    PhotoServicesDisplayMgr * photoServicesDisplayMgr;
    InstapaperLogInDisplayMgr * instapaperDisplayMgr;

    NSManagedObjectContext * context;
}

@property (nonatomic, assign) id<AccountSettingsDisplayMgrDelegate> delegate;

- (id)initWithNavigationController:(UINavigationController *)aNavController
                           context:(NSManagedObjectContext *)aContext;

- (void)editSettingsForAccount:(TwitterCredentials *)credentials;

@end
