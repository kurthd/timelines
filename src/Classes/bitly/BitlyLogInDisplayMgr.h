//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BitlyLogInViewController.h"
#import "TwitterCredentials.h"

@protocol BitlyLogInDisplayMgrDelegate;

@interface BitlyLogInDisplayMgr : NSObject <BitlyLogInViewControllerDelegate>
{
    id<BitlyLogInDisplayMgrDelegate> delegate;

    BitlyLogInViewController * viewController;
    UINavigationController * navigationController;
    UIViewController * rootViewController;

    BOOL authenticating;

    TwitterCredentials * credentials;
    NSManagedObjectContext * context;
}

@property (nonatomic, assign) id<BitlyLogInDisplayMgrDelegate> delegate;
@property (nonatomic, retain) TwitterCredentials * credentials;

- (id)initWithContext:(NSManagedObjectContext *)aContext;

- (void)logInModallyForViewController:(UIViewController *)aRootViewController;
- (void)configureExistingAccountWithNavigationController:
    (UINavigationController *)aNavigationController;

@end

@protocol BitlyLogInDisplayMgrDelegate

// - (void)accountCreated:(BitlyCredentials *)credentials;
// - (void)accountCreationCancelled;
// 
// - (void)accountEdited:(BitlyCredentials *)credentials;
// - (void)editingAccountCancelled:(BitlyCredentials *)credentials;
// 
// - (void)accountWillBeDeleted:(BitlyCredentials *)credentials;

@end
