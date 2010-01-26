//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "TimelineViewController.h"
#import "TimelineDataSource.h"
#import "TimelineDataSourceDelegate.h"
#import "TweetViewControllerDelegate.h"
#import "TwitterCredentials.h"
#import "Tweet.h"
#import "UserInfoViewController.h"
#import "UserInfoViewControllerDelegate.h"
#import "CredentialsActivatedPublisher.h"
#import "ComposeTweetDisplayMgr.h"
#import "TwitchBrowserViewController.h"
#import "TwitchBrowserViewControllerDelegate.h"
#import "TwitterService.h"
#import "TwitterServiceDelegate.h"
#import "ConversationDisplayMgr.h"
#import "ContactCache.h"
#import "ContactMgr.h"
#import "SoundPlayer.h"

@class TimelineDisplayMgrFactory;
@class TweetViewController;
@class TweetDetailsViewLoader;
@class UserListDisplayMgrFactory;
@class DisplayMgrHelper;

@interface TimelineDisplayMgr :
    NSObject
    <TimelineDataSourceDelegate, TimelineViewControllerDelegate,
    TweetViewControllerDelegate, NetworkAwareViewControllerDelegate,
    TwitterServiceDelegate, UIWebViewDelegate, ConversationDisplayMgrDelegate>
{
    UINavigationController * navigationController;
    NetworkAwareViewController * wrapperController;
    TimelineViewController * timelineController;
    NetworkAwareViewController * lastTweetDetailsWrapperController;
    TweetViewController * lastTweetDetailsController;
    TweetViewController * tweetDetailsController;

    DisplayMgrHelper * displayMgrHelper;

    NSObject<TimelineDataSource> * timelineSource;
    TwitterService * service;

    Tweet * selectedTweet;
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
    BOOL showMentions;
    BOOL displayedATweet;

    NSManagedObjectContext * managedObjectContext;

    ComposeTweetDisplayMgr * composeTweetDisplayMgr;

    NSNumber * tweetIdToShow;

    BOOL suppressTimelineFailures;

    // A new conversation display mgr instance is created for every
    // conversation that is viewed. Indeed, we must create a new one, as we
    // must push a unique view controller instance onto the nav stack for
    // each one, and the display mgr owns the view controller.
    //
    // Every conversation display mgr is added to this array. When the
    // timeline view is displayed, the array is emptied.
    NSMutableArray * conversationDisplayMgrs;

    NSMutableDictionary * tweetIdToIndexDict;
    NSMutableDictionary * tweetIndexToIdDict;

    UIBarButtonItem * updatingTimelineActivityView;
    UIBarButtonItem * refreshButton;

    SoundPlayer * soundPlayer;
}

@property (readonly) NetworkAwareViewController * wrapperController;
@property (readonly) TimelineViewController * timelineController;
@property (nonatomic, retain)
    NetworkAwareViewController * lastTweetDetailsWrapperController;
@property (nonatomic, retain) TweetViewController * lastTweetDetailsController;
@property (readonly) TweetViewController * tweetDetailsController;
@property (nonatomic, retain) UINavigationController * navigationController;

@property (nonatomic, retain) Tweet * selectedTweet;
@property (nonatomic, retain) NSString * currentUsername;
@property (nonatomic, retain) User * user;
@property (nonatomic, copy) NSNumber * updateId;

@property (nonatomic, readonly) NSMutableDictionary * timeline;
@property (nonatomic, readonly) NSUInteger pagesShown;
@property (nonatomic, readonly) BOOL allPagesLoaded;

@property (nonatomic, assign) BOOL displayAsConversation;
@property (nonatomic, assign) BOOL setUserToFirstTweeter;
@property (nonatomic, assign) BOOL setUserToAuthenticatedUser;
@property (nonatomic, assign) BOOL firstFetchReceived;

@property (nonatomic, copy) NSNumber * tweetIdToShow;

@property (nonatomic, assign) BOOL suppressTimelineFailures;

@property (nonatomic, readonly) TwitterCredentials * credentials;

@property (nonatomic, assign) BOOL showMentions;

@property (nonatomic, retain) UIBarButtonItem * refreshButton;

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    navigationController:(UINavigationController *)navigationController
    timelineController:(TimelineViewController *)aTimelineController
    timelineSource:(NSObject<TimelineDataSource> *)timelineSource
    service:(TwitterService *)service title:(NSString *)title
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )managedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr
    userListDisplayMgrFactory:(UserListDisplayMgrFactory *)userListDispMgrFctry
    contactCache:(ContactCache *)aContactCache
    contactMgr:(ContactMgr *)aContactMgr;

- (void)setService:(NSObject<TimelineDataSource> *)aService
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
    forceRefresh:(BOOL)refresh allPagesLoaded:(BOOL)allPagesLoaded;
- (void)setService:(NSObject<TimelineDataSource> *)aTimelineSource
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
    forceRefresh:(BOOL)refresh allPagesLoaded:(BOOL)newAllPagesLoaded
    verticalOffset:(CGFloat)verticalOffset;
- (void)setTweets:(NSDictionary *)someTweets;
- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)replyToTweet;
- (void)refreshWithLatest;
- (void)refreshWithCurrentPages;

- (CGFloat)tableViewContentOffset;
- (void)setTableViewContentOffset:(CGFloat)offset;
- (CGFloat)timelineContentHeight;

- (void)addTweet:(Tweet *)tweet;

- (NSNumber *)mostRecentTweetId;
- (NSNumber *)currentlyViewedTweetId;

// HACK: Added to get "Save Search" button in header view.
- (void)setTimelineHeaderView:(UIView *)view;

- (void)pushTweetWithoutAnimation:(Tweet *)tweet;

@end
