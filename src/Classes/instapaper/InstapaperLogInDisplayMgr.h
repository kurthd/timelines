//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InstapaperLogInViewController.h"
#import "InstapaperService.h"
#import "TwitterCredentials.h"

@protocol InstapaperLogInDisplayMgrDelegate;

@interface InstapaperLogInDisplayMgr :
    NSObject
    <InstapaperLogInViewControllerDelegate,
    InstapaperServiceDelegate>
{
    id<InstapaperLogInDisplayMgrDelegate> delegate;

    InstapaperLogInViewController * viewController;
    UINavigationController * navigationController;
    UIViewController * rootViewController;

    InstapaperService * instapaperService;
    BOOL authenticating;

    TwitterCredentials * credentials;
    NSManagedObjectContext * context;
}

@property (nonatomic, assign) id<InstapaperLogInDisplayMgrDelegate> delegate;
@property (nonatomic, retain) TwitterCredentials * credentials;

- (id)initWithContext:(NSManagedObjectContext *)aContext;

- (void)logInModallyForViewController:(UIViewController *)aRootViewController;
- (void)configureExistingAccountWithNavigationController:
    (UINavigationController *)aNavigationController;

@end

@protocol InstapaperLogInDisplayMgrDelegate

- (void)accountCreated:(InstapaperCredentials *)credentials;
- (void)accountCreationCancelled;

- (void)accountWillBeDeleted:(InstapaperCredentials *)credentials;

@end
