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

    NSString * recipient;  // non-nil if composing a direct message

    NSString * origTweetId;  // non-nil if composing a reply
    NSString * origUsername;

    NSString * tweetDraft;
    NSString * dmDraft;

    CredentialsActivatedPublisher * credentialsUpdatePublisher;
}

@property (nonatomic, assign) id<ComposeTweetDisplayMgrDelegate> delegate;

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService
                     imageSender:(TwitPicImageSender *)anImageSender;

- (void)composeTweet;
- (void)composeTweetWithText:(NSString *)tweet;

- (void)composeReplyToTweet:(NSString *)tweetId
                   fromUser:(NSString *)user;
- (void)composeReplyToTweet:(NSString *)tweetId
                   fromUser:(NSString *)user
                   withText:(NSString *)text;

- (void)composeDirectMessageTo:(NSString *)username;
- (void)composeDirectMessageTo:(NSString *)username withText:(NSString *)tweet;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
