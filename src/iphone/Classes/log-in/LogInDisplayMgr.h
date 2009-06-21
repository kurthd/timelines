//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogInViewControllerDelegate.h"
#import "MGTwitterEngineDelegate.h"

@class MGTwitterEngine, LogInViewController;

@interface LogInDisplayMgr :
    NSObject <LogInViewControllerDelegate, MGTwitterEngineDelegate>
{
    UIViewController * rootViewController;
    LogInViewController * logInViewController;

    MGTwitterEngine * twitter;
    NSString * logInRequestId;

    NSString * username;
    NSString * password;
}

- (id)initWithRootViewController:(UIViewController *)aRootViewController;

- (void)logIn;

@end
