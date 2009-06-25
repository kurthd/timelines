//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ComposeTweetDisplayMgrDelegate.h"
#import "ComposeTweetViewControllerDelegate.h"
#import "TwitterService.h"
#import "TwitPicImageSender.h"
#import "TwitterCredentials.h"

@class ComposeTweetViewController;
@class CredentialsActivatedPublisher;

@interface ComposeTweetDisplayMgr :
    NSObject
    <ComposeTweetViewControllerDelegate, TwitterServiceDelegate,
    TwitPicImageSenderDelegate, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate, UIActionSheetDelegate>
{
    id<ComposeTweetDisplayMgrDelegate> delegate;

    UIViewController * rootViewController;
    ComposeTweetViewController * composeTweetViewController;

    TwitterService * service;
    TwitPicImageSender * imageSender;

    BOOL composingDirectMessage;
    NSString * recipient;

    CredentialsActivatedPublisher * credentialsUpdatePublisher;
}

@property (nonatomic, assign) id<ComposeTweetDisplayMgrDelegate> delegate;

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService
                     imageSender:(TwitPicImageSender *)anImageSender;

- (void)composeTweet;
- (void)composeTweetWithText:(NSString *)tweet;

- (void)composeDirectMessageTo:(NSString *)username;
- (void)composeDirectMessageTo:(NSString *)username withText:(NSString *)tweet;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
