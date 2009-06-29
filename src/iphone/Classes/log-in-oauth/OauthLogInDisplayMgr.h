//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGTwitterEngineDelegate.h"
#import "OauthLogInViewController.h"
#import "ExplainOauthViewController.h"

@class MGTwitterEngine, OAToken;
@class YHOAuthTwitterEngine;

@protocol OathLogInDisplayMgrDelegate <NSObject>

@optional

- (BOOL)isUsernameValid:(NSString *)username;

@end

@interface OauthLogInDisplayMgr :
    NSObject
    <OauthLogInViewControllerDelegate, ExplainOauthViewControllerDelegate>
{
    id<OathLogInDisplayMgrDelegate> delegate;

    NSManagedObjectContext * context;

    UIViewController * rootViewController;
    ExplainOauthViewController * explainOauthViewController;
    OauthLogInViewController * oauthLogInViewController;

    YHOAuthTwitterEngine * twitter;
    OAToken * requestToken;

    BOOL allowsCancel;
}

@property (nonatomic, assign) id<OathLogInDisplayMgrDelegate> delegate;
@property (nonatomic, assign) BOOL allowsCancel;

- (id)initWithRootViewController:(UIViewController *)aRootViewController
            managedObjectContext:(NSManagedObjectContext *)aContext;

- (void)logIn:(BOOL)animated;

@end
