//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ComposeTweetViewController.h"
#import "TwitterService.h"
#import "PhotoService.h"
#import "TwitterCredentials.h"
#import "LogInDisplayMgr.h"
#import "AddPhotoServiceDisplayMgr.h"
#import "UIPersonSelector.h"
#import "BitlyUrlShorteningService.h"

@class CredentialsActivatedPublisher, CredentialsSetChangedPublisher;
@class TweetDraft, DirectMessageDraft;
@class TweetDraftMgr;
@class BitlyUrlShorteningService;
@protocol ComposeTweetDisplayMgrDelegate;

@interface ComposeTweetDisplayMgr :
    NSObject
    <ComposeTweetViewControllerDelegate, TwitterServiceDelegate,
    PhotoServiceDelegate, LogInDisplayMgrDelegate,
    UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    UIActionSheetDelegate, AddPhotoServiceDisplayMgrDelegate,
    UIPersonSelectorDelegate, BitlyUrlShorteningServiceDelegate,
    UIAlertViewDelegate>
{
    id<ComposeTweetDisplayMgrDelegate> delegate;

    UIViewController * rootViewController;
    UIViewController * navController;
    ComposeTweetViewController * composeTweetViewController;

    TwitterService * service;
    LogInDisplayMgr * logInDisplayMgr;

    BOOL fromHomeScreen;  // HACK: restore the correct draft from the "root"
                          // direct messages view

    NSNumber * origTweetId;  // non-nil if composing a reply
    NSString * origUsername;

    TweetDraftMgr * draftMgr;

    NSManagedObjectContext * context;

    CredentialsActivatedPublisher * credentialsUpdatePublisher;
    CredentialsSetChangedPublisher * credentialsSetChangedPublisher;

    AddPhotoServiceDisplayMgr * addPhotoServiceDisplayMgr;
    PhotoService * photoService;

    NSMutableArray * attachedPhotos;
    NSMutableArray * attachedVideos;

    BitlyUrlShorteningService * urlShorteningService;
    NSMutableSet * urlsToShorten;

    UIPersonSelector * personSelector;
    BOOL selectingRecipient;

    BOOL composingTweet;
    NSString * directMessageRecipient;
}

@property (nonatomic, assign) id<ComposeTweetDisplayMgrDelegate> delegate;

@property (nonatomic, assign) BOOL composingTweet;
@property (nonatomic, copy) NSString * directMessageRecipient;

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService
                         context:(NSManagedObjectContext *)aContext;

- (void)composeTweetAnimated:(BOOL)animated;
- (void)composeTweetWithText:(NSString *)tweet animated:(BOOL)animated;

- (void)composeReplyToTweet:(NSNumber *)tweetId
                   fromUser:(NSString *)user;
- (void)composeReplyToTweet:(NSNumber *)tweetId
                   fromUser:(NSString *)user
                   withText:(NSString *)text;

- (void)composeDirectMessage;
- (void)composeDirectMessageTo:(NSString *)username animated:(BOOL)animated;
- (void)composeDirectMessageTo:(NSString *)username withText:(NSString *)tweet
    animated:(BOOL)animated;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end


@protocol ComposeTweetDisplayMgrDelegate

- (void)userDidCancelComposingTweet;

- (void)userIsSendingTweet:(NSString *)tweet;
- (void)userDidSendTweet:(Tweet *)tweet;
- (void)userFailedToSendTweet:(NSString *)tweet;

- (void)userIsReplyingToTweet:(NSNumber *)origTweetId
                     fromUser:(NSString *)origUsername
                     withText:(NSString *)text;
- (void)userDidReplyToTweet:(NSNumber *)origTweetId
                   fromUser:(NSString *)origUsername
                  withTweet:(Tweet *)reply;
- (void)userFailedToReplyToTweet:(NSNumber *)origTweetId
                        fromUser:(NSString *)origUsername
                        withText:(NSString *)text;

- (void)userIsSendingDirectMessage:(NSString *)dm to:(NSString *)username;
- (void)userDidSendDirectMessage:(DirectMessage *)dm;
- (void)userFailedToSendDirectMessage:(NSString *)dm to:(NSString *)username;

@end