//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "TimelineViewController.h"
#import "TimelineDataSource.h"
#import "TimelineViewControllerDelegate.h"
#import "TimelineDataSourceDelegate.h"
#import "TweetDetailsViewController.h"
#import "TwitterCredentials.h"
#import "TweetInfo.h"
#import "UserInfoViewController.h"
#import "UserInfoViewControllerDelegate.h"
#import "CredentialsActivatedPublisher.h"
#import "UserListTableViewControllerDelegate.h"
#import "UserListTableViewController.h"
#import "ComposeTweetDisplayMgr.h"
#import "TwitchBrowserViewController.h"

@class TimelineDisplayMgrFactory;

@interface TimelineDisplayMgr :
    NSObject
    <TimelineDataSourceDelegate, TimelineViewControllerDelegate,
    TweetDetailsViewDelegate, NetworkAwareViewControllerDelegate,
    UserInfoViewControllerDelegate, UserListTableViewControllerDelegate>
{
    NetworkAwareViewController * wrapperController;
    TimelineViewController * timelineController;
    NetworkAwareViewController * lastTweetDetailsWrapperController;
    TweetDetailsViewController * lastTweetDetailsController;
    TweetDetailsViewController * tweetDetailsController;
    UserInfoViewController * userInfoController;
    TwitchBrowserViewController * browserController;

    NSObject<TimelineDataSource> * service;

    TweetInfo * selectedTweet;
    User * user;
    NSMutableDictionary * timeline;
    NSNumber * updateId;
    NSUInteger pagesShown;

    NSMutableDictionary * followingUsers;
    NSUInteger followingUsersPagesShown;
    NSMutableDictionary * followers;
    NSUInteger followersPagesShown;
    BOOL showingFollowing;
    NSString * lastFollowingUsername;

    TwitterCredentials * credentials;

    BOOL displayAsConversation;
    BOOL hasBeenDisplayed;
    BOOL needsRefresh;
    BOOL setUserToFirstTweeter;
    BOOL refreshingTweets;
    BOOL showInboxOutbox;

    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    TimelineDisplayMgr * tweetDetailsTimelineDisplayMgr;
    NetworkAwareViewController * tweetDetailsNetAwareViewController;
    CredentialsActivatedPublisher * tweetDetailsCredentialsPublisher;
    NSManagedObjectContext * managedObjectContext;

    NetworkAwareViewController * userListNetAwareViewController;
    UserListTableViewController * userListController;

    ComposeTweetDisplayMgr * composeTweetDisplayMgr;
    
    BOOL failedState;
    
    NSString * currentTweetDetailsUser;
}

@property (readonly) NetworkAwareViewController * wrapperController;
@property (readonly) TimelineViewController * timelineController;
@property (nonatomic, retain)
    NetworkAwareViewController * lastTweetDetailsWrapperController;
@property (nonatomic, retain)
    TweetDetailsViewController * lastTweetDetailsController;
@property (readonly) TweetDetailsViewController * tweetDetailsController;
@property (readonly) UserInfoViewController * userInfoController;
@property (readonly) TwitchBrowserViewController * browserController;

@property (nonatomic, retain) TweetInfo * selectedTweet;
@property (nonatomic, retain) User * user;
@property (nonatomic, copy) NSNumber * updateId;

@property (nonatomic, copy) NSMutableDictionary * timeline;
@property (nonatomic, readonly) NSUInteger pagesShown;
@property (nonatomic, copy) NSString * lastFollowingUsername;

@property (nonatomic, assign) BOOL displayAsConversation;
@property (nonatomic, assign) BOOL setUserToFirstTweeter;

@property (nonatomic, retain)
    TimelineDisplayMgr * tweetDetailsTimelineDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * tweetDetailsNetAwareViewController;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * tweetDetailsCredentialsPublisher;

@property (nonatomic, readonly)
    NetworkAwareViewController * userListNetAwareViewController;
@property (nonatomic, readonly)
    UserListTableViewController * userListController;

@property (nonatomic, copy) NSString * currentTweetDetailsUser;
    
- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    service:(NSObject<TimelineDataSource> *)service title:(NSString *)title
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )managedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr;

- (void)setService:(NSObject<TimelineDataSource> *)aService
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
    forceRefresh:(BOOL)refresh;
- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)replyToTweet;
- (void)refreshWithLatest;
- (void)refreshWithCurrentPages;

- (void)addTweet:(Tweet *)tweet displayImmediately:(BOOL)displayImmediately;

- (void)setShowInboxOutbox:(BOOL)show;

@end
