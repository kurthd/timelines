//
//  Copyright High Order Bit, Inc. 2010. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XauthLogInViewController.h"
#import "TwitterXauthenticator.h"

@protocol XauthLogInDisplayMgrDelegate;

@interface XauthLogInDisplayMgr :
    NSObject <XauthLogInViewControllerDelegate, TwitterXauthenticatorDelegate>
{
    id<XauthLogInDisplayMgrDelegate> delegate;

    UIViewController * rootViewController;
    UINavigationController * navigationController;
    UINavigationController * logInNavController;
    XauthLogInViewController * logInViewController;

    NSManagedObjectContext * context;

    BOOL allowsCancel;
    BOOL authenticating;
}

@property (nonatomic, assign) id<XauthLogInDisplayMgrDelegate> delegate;
@property (nonatomic, assign) BOOL allowsCancel;
@property (nonatomic, retain) UINavigationController * navigationController;

//
// Maintain the same public interface as OauthLogInDisplayMgr for now
//

- (id)initWithRootViewController:(UIViewController *)aRootViewController
            managedObjectContext:(NSManagedObjectContext *)aContext;

- (void)logIn:(BOOL)animated;

@end


@protocol XauthLogInDisplayMgrDelegate

@end
