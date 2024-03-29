//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LogInViewControllerDelegate.h"
#import "MGTwitterEngineDelegate.h"

@class MGTwitterEngine, LogInViewController;

@protocol LogInDisplayMgrDelegate <NSObject>

@optional

- (BOOL)isUsernameValid:(NSString *)username;

- (void)logInCompleted:(NSString *)username password:(NSString *)password;
- (void)logInCancelled;

@end

@interface LogInDisplayMgr :
    NSObject <LogInViewControllerDelegate, MGTwitterEngineDelegate>
{
    id<LogInDisplayMgrDelegate> delegate;

    NSManagedObjectContext * context;

    UIViewController * rootViewController;
    LogInViewController * logInViewController;

    MGTwitterEngine * twitter;
    NSString * logInRequestId;

    NSString * username;
    NSString * password;

    BOOL allowsCancel;
}

@property (nonatomic, assign) id<LogInDisplayMgrDelegate> delegate;
@property (nonatomic, assign) BOOL allowsCancel;

- (id)initWithRootViewController:(UIViewController *)aRootViewController
            managedObjectContext:(NSManagedObjectContext *)aContext;

- (void)logIn:(BOOL)animated;
- (void)logInForUser:(NSString *)username animated:(BOOL)animated;

#pragma mark Configuring the view

- (void)setViewTitle:(NSString *)title;
- (void)setViewInstructions:(NSString *)instructions;

@end
