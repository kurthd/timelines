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
    NSManagedObjectContext * context;

    UIViewController * rootViewController;
    LogInViewController * logInViewController;

    MGTwitterEngine * twitter;
    NSString * logInRequestId;

    NSString * username;
    NSString * password;

    BOOL allowsCancel;
}

@property (nonatomic, assign) BOOL allowsCancel;

- (id)initWithRootViewController:(UIViewController *)aRootViewController
            managedObjectContext:(NSManagedObjectContext *)aContext;

- (void)logIn;

@end
