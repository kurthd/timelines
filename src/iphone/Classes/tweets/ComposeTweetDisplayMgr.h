//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ComposeTweetDisplayMgrDelegate.h"
#import "ComposeTweetViewControllerDelegate.h"
#import "TwitterService.h"
#import "TwitterCredentials.h"

@class ComposeTweetViewController;
@class CredentialsUpdatePublisher;

@interface ComposeTweetDisplayMgr :
    NSObject <ComposeTweetViewControllerDelegate, TwitterServiceDelegate>
{
    id<ComposeTweetDisplayMgrDelegate> delegate;

    UIViewController * rootViewController;
    ComposeTweetViewController * composeTweetViewController;

    TwitterService * service;

    CredentialsUpdatePublisher * credentialsUpdatePublisher;
}

@property (nonatomic, assign) id<ComposeTweetDisplayMgrDelegate> delegate;

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService;

- (void)composeTweet;
- (void)composeTweetWithText:(NSString *)tweet;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
