//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogInViewControllerDelegate.h"
#import "MGTwitterEngineDelegate.h"
#import "OauthLogInViewController.h"

@class MGTwitterEngine, LogInViewController, OAToken;

@protocol LogInDisplayMgrDelegate <NSObject>

@optional

- (BOOL)isUsernameValid:(NSString *)username;

@end

@interface LogInDisplayMgr :
    NSObject <MGTwitterEngineDelegate, OauthLogInViewControllerDelegate>
{
    id<LogInDisplayMgrDelegate> delegate;

    NSManagedObjectContext * context;

    UIViewController * rootViewController;
    LogInViewController * logInViewController;
    OauthLogInViewController * oauthLogInViewController;

    MGTwitterEngine * twitter;
    NSString * logInRequestId;

    OAToken * requestToken;

    NSString * username;
    NSString * password;

    BOOL allowsCancel;
}

@property (nonatomic, assign) id<LogInDisplayMgrDelegate> delegate;
@property (nonatomic, assign) BOOL allowsCancel;

- (id)initWithRootViewController:(UIViewController *)aRootViewController
            managedObjectContext:(NSManagedObjectContext *)aContext;

- (void)logIn:(BOOL)animated;

@end
