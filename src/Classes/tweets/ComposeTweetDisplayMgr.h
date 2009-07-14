//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ComposeTweetDisplayMgrDelegate.h"
#import "ComposeTweetViewControllerDelegate.h"
#import "TwitterService.h"
#import "TwitPicImageSender.h"
#import "TwitterCredentials.h"
#import "LogInDisplayMgr.h"

@class ComposeTweetViewController;
@class CredentialsActivatedPublisher, CredentialsSetChangedPublisher;
@class TweetDraft, DirectMessageDraft;
@class TweetDraftMgr;

@interface ComposeTweetDisplayMgr :
    NSObject
    <ComposeTweetViewControllerDelegate, TwitterServiceDelegate,
    TwitPicImageSenderDelegate, LogInDisplayMgrDelegate,
    UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    UIActionSheetDelegate>
{
    id<ComposeTweetDisplayMgrDelegate> delegate;

    UIViewController * rootViewController;
    ComposeTweetViewController * composeTweetViewController;

    TwitterService * service;
    TwitPicImageSender * imageSender;
    LogInDisplayMgr * logInDisplayMgr;

    NSString * recipient;  // non-nil if composing a direct message

    NSString * origTweetId;  // non-nil if composing a reply
    NSString * origUsername;

    TweetDraftMgr * draftMgr;

    NSManagedObjectContext * context;

    CredentialsActivatedPublisher * credentialsUpdatePublisher;
    CredentialsSetChangedPublisher * credentialsSetChangedPublisher;
}

@property (nonatomic, assign) id<ComposeTweetDisplayMgrDelegate> delegate;

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService
                     imageSender:(TwitPicImageSender *)anImageSender
                         context:(NSManagedObjectContext *)aContext;

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
