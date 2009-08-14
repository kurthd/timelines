//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "TimelineViewController.h"
#import "TimelineDataSource.h"
#import "TimelineViewControllerDelegate.h"
#import "TimelineDataSourceDelegate.h"
#import "TweetViewControllerDelegate.h"
#import "TwitterCredentials.h"
#import "TweetInfo.h"
#import "UserInfoViewController.h"
#import "UserInfoViewControllerDelegate.h"
#import "CredentialsActivatedPublisher.h"
#import "UserListTableViewControllerDelegate.h"
#import "UserListTableViewController.h"
#import "ComposeTweetDisplayMgr.h"
#import "TwitchBrowserViewController.h"
#import "PhotoBrowser.h"
#import "TwitchBrowserViewControllerDelegate.h"
#import "TwitterService.h"
#import "TwitterServiceDelegate.h"
#import "SavedSearchMgr.h"
#import "UserInfoRequestAdapter.h"

@class TimelineDisplayMgrFactory;
@class TweetViewController;
@class TweetDetailsViewLoader;
@class UserListDisplayMgrFactory;
@class UserListDisplayMgr;

@interface TimelineDisplayMgr :
    NSObject
    <TimelineDataSourceDelegate, TimelineViewControllerDelegate,
    TweetViewControllerDelegate, NetworkAwareViewControllerDelegate,
    UserInfoViewControllerDelegate, TwitchBrowserViewControllerDelegate,
    TwitterServiceDelegate, UIWebViewDelegate>
{
    NetworkAwareViewController * wrapperController;
    TimelineViewController * timelineController;
    NetworkAwareViewController * lastTweetDetailsWrapperController;
    TweetViewController * lastTweetDetailsController;
    TweetViewController * tweetDetailsController;
    NetworkAwareViewController * userInfoControllerWrapper;
    UserInfoRequestAdapter * userInfoRequestAdapter;
    TwitterService * userInfoTwitterService;
    UserInfoViewController * userInfoController;
    SavedSearchMgr * findPeopleBookmarkMgr;
    UserListDisplayMgrFactory * userListDisplayMgrFactory;

    NSObject<TimelineDataSource> * timelineSource;
    TwitterService * service;

    TweetInfo * selectedTweet;
    NSString * currentUsername;
    User * user;
    NSMutableDictionary * timeline;
    NSNumber * updateId;
    NSUInteger pagesShown;
    BOOL allPagesLoaded;

    TwitterCredentials * credentials;

    BOOL displayAsConversation;
    BOOL hasBeenDisplayed;
    BOOL needsRefresh;
    BOOL setUserToFirstTweeter;
    BOOL refreshingTweets;
    BOOL setUserToAuthenticatedUser;
    BOOL firstFetchReceived;

    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    TimelineDisplayMgr * tweetDetailsTimelineDisplayMgr;
    NetworkAwareViewController * tweetDetailsNetAwareViewController;
    CredentialsActivatedPublisher * tweetDetailsCredentialsPublisher;
    NSManagedObjectContext * managedObjectContext;

    UserListDisplayMgr * userListDisplayMgr;
    NetworkAwareViewController * userListNetAwareViewController;

    ComposeTweetDisplayMgr * composeTweetDisplayMgr;

    NSString * tweetIdToShow;

    BOOL suppressTimelineFailures;

    SavedSearchMgr * savedSearchMgr;
    NSString * currentSearch;
}

@property (readonly) NetworkAwareViewController * wrapperController;
@property (readonly) TimelineViewController * timelineController;
@property (nonatomic, retain)
    NetworkAwareViewController * lastTweetDetailsWrapperController;
@property (nonatomic, retain) TweetViewController * lastTweetDetailsController;
@property (readonly) TweetViewController * tweetDetailsController;
@property (readonly) UserInfoViewController * userInfoController;
@property (readonly) NetworkAwareViewController * userInfoControllerWrapper;
@property (readonly) UserInfoRequestAdapter * userInfoRequestAdapter;
@property (readonly) TwitterService * userInfoTwitterService;

@property (nonatomic, retain) TweetInfo * selectedTweet;
@property (nonatomic, retain) NSString * currentUsername;
@property (nonatomic, retain) User * user;
@property (nonatomic, copy) NSNumber * updateId;

@property (nonatomic, readonly) NSMutableDictionary * timeline;
@property (nonatomic, readonly) NSUInteger pagesShown;
@property (nonatomic, readonly) BOOL allPagesLoaded;
// @property (nonatomic, copy) NSString * lastFollowingUsername;

@property (nonatomic, assign) BOOL displayAsConversation;
@property (nonatomic, assign) BOOL setUserToFirstTweeter;
@property (nonatomic, assign) BOOL setUserToAuthenticatedUser;
@property (nonatomic, assign) BOOL firstFetchReceived;

@property (nonatomic, retain)
    TimelineDisplayMgr * tweetDetailsTimelineDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * tweetDetailsNetAwareViewController;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * tweetDetailsCredentialsPublisher;

@property (nonatomic, retain) UserListDisplayMgr * userListDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * userListNetAwareViewController;

@property (nonatomic, copy) NSString * tweetIdToShow;

@property (nonatomic, assign) BOOL suppressTimelineFailures;

@property (nonatomic, readonly) TwitterCredentials * credentials;
    
- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    timelineSource:(NSObject<TimelineDataSource> *)timelineSource
    service:(TwitterService *)service title:(NSString *)title
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )managedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr
    userListDisplayMgrFactory:(UserListDisplayMgrFactory *)userListDispMgrFctry;

- (void)setService:(NSObject<TimelineDataSource> *)aService
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
    forceRefresh:(BOOL)refresh allPagesLoaded:(BOOL)allPagesLoaded;
- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)replyToTweet;
- (void)refreshWithLatest;
- (void)refreshWithCurrentPages;

- (void)addTweet:(Tweet *)tweet;

- (NSString *)mostRecentTweetId;

// HACK: Added to get "Save Search" button in header view.
- (void)setTimelineHeaderView:(UIView *)view;

@end
