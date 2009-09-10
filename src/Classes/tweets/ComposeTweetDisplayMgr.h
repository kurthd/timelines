//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ComposeTweetDisplayMgrDelegate.h"
#import "ComposeTweetViewControllerDelegate.h"
#import "TwitterService.h"
#import "PhotoService.h"
#import "TwitterCredentials.h"
#import "LogInDisplayMgr.h"
#import "AddPhotoServiceDisplayMgr.h"
#import "AsynchronousNetworkFetcherDelegate.h"

@class ComposeTweetViewController;
@class CredentialsActivatedPublisher, CredentialsSetChangedPublisher;
@class TweetDraft, DirectMessageDraft;
@class TweetDraftMgr;

@interface ComposeTweetDisplayMgr :
    NSObject
    <ComposeTweetViewControllerDelegate, TwitterServiceDelegate,
    PhotoServiceDelegate, LogInDisplayMgrDelegate,
    UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    UIActionSheetDelegate, AddPhotoServiceDisplayMgrDelegate,
    AsynchronousNetworkFetcherDelegate>
{
    id<ComposeTweetDisplayMgrDelegate> delegate;

    UIViewController * rootViewController;
    UIViewController * navController;
    ComposeTweetViewController * composeTweetViewController;

    TwitterService * service;
    LogInDisplayMgr * logInDisplayMgr;

    BOOL fromHomeScreen;  // HACK: restore the correct draft from the "root"
                          // direct messages view

    NSString * origTweetId;  // non-nil if composing a reply
    NSString * origUsername;

    TweetDraftMgr * draftMgr;

    NSManagedObjectContext * context;

    CredentialsActivatedPublisher * credentialsUpdatePublisher;
    CredentialsSetChangedPublisher * credentialsSetChangedPublisher;

    AddPhotoServiceDisplayMgr * addPhotoServiceDisplayMgr;

    NSMutableArray * attachedPhotos;
    NSMutableArray * attachedVideos;

    UIView * linkShorteningView;
    BOOL canceledLinkShortening;
    NSString * shorteningUrl;
}

@property (nonatomic, assign) id<ComposeTweetDisplayMgrDelegate> delegate;

- (id)initWithRootViewController:(UIViewController *)aRootViewController
                  twitterService:(TwitterService *)aService
                         context:(NSManagedObjectContext *)aContext;

- (void)composeTweet;
- (void)composeTweetWithText:(NSString *)tweet;
- (void)composeTweetWithLink:(NSString *)link;

- (void)composeReplyToTweet:(NSString *)tweetId
                   fromUser:(NSString *)user;
- (void)composeReplyToTweet:(NSString *)tweetId
                   fromUser:(NSString *)user
                   withText:(NSString *)text;

- (void)composeDirectMessage;
- (void)composeDirectMessageTo:(NSString *)username;
- (void)composeDirectMessageTo:(NSString *)username withText:(NSString *)tweet;

- (void)setCredentials:(TwitterCredentials *)credentials;

@end
