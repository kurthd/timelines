//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ComposeTweetViewControllerDelegate.h"
#import "TwitterService.h"
#import "TwitterCredentials.h"

@class ComposeTweetViewController;
@class CredentialsUpdatePublisher;

@interface ComposeTweetDisplayMgr :
    NSObject <ComposeTweetViewControllerDelegate, TwitterServiceDelegate>
{
    UIViewController * rootViewController;
    ComposeTweetViewController * composeTweetViewController;

    TwitterService * service;

    CredentialsUpdatePublisher * credentialsUpdatePublisher;
}

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService;

- (void)composeTweet;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
