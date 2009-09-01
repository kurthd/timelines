//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InstapaperLogInViewController.h"
#import "InstapaperService.h"
#import "TwitterCredentials.h"

@interface InstapaperLogInDisplayMgr :
    NSObject
    <InstapaperLogInViewControllerDelegate,
    InstapaperServiceDelegate>
{
    InstapaperLogInViewController * viewController;
    UINavigationController * navigationController;
    UIViewController * rootViewController;

    InstapaperService * instapaperService;
    BOOL authenticating;

    TwitterCredentials * credentials;
    NSManagedObjectContext * context;
}

- (id)initWithCredentials:(TwitterCredentials *)someCredentials
                  context:(NSManagedObjectContext *)aContext;

- (void)logInModallyForViewController:(UIViewController *)aRootViewController;

@end
