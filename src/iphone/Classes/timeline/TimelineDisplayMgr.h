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

@class TimelineDisplayMgrFactory;

@interface TimelineDisplayMgr :
    NSObject
    <TimelineDataSourceDelegate, TimelineViewControllerDelegate,
    TweetDetailsViewDelegate, NetworkAwareViewControllerDelegate,
    UserInfoViewControllerDelegate>
{
    NetworkAwareViewController * wrapperController;
    TimelineViewController * timelineController;
    TweetDetailsViewController * tweetDetailsController;
    UserInfoViewController * userInfoController;

    NSObject<TimelineDataSource> * service;

    TweetInfo * selectedTweet;
    User * user;
    NSMutableDictionary * timeline;
    NSNumber * updateId;
    NSUInteger pagesShown;

    TwitterCredentials * credentials;

    BOOL displayAsConversation;
    BOOL hasBeenDisplayed;
    BOOL needsRefresh;
    BOOL setUserToFirstTweeter;

    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    TimelineDisplayMgr * tweetDetailsTimelineDisplayMgr;
    NetworkAwareViewController * tweetDetailsNetAwareViewController;
    CredentialsActivatedPublisher * tweetDetailsCredentialsPublisher;
    NSManagedObjectContext * managedObjectContext;
}

@property (readonly) NetworkAwareViewController * wrapperController;
@property (readonly) TimelineViewController * timelineController;
@property (readonly) TweetDetailsViewController * tweetDetailsController;
@property (readonly) UserInfoViewController * userInfoController;

@property (nonatomic, retain) TweetInfo * selectedTweet;
@property (nonatomic, retain) User * user;
@property (nonatomic, copy) NSNumber * updateId;

@property (nonatomic, copy) NSMutableDictionary * timeline;
@property (nonatomic, readonly) NSUInteger pagesShown;

@property (nonatomic, assign) BOOL displayAsConversation;
@property (nonatomic, assign) BOOL setUserToFirstTweeter;

@property (nonatomic, retain)
    TimelineDisplayMgr * tweetDetailsTimelineDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * tweetDetailsNetAwareViewController;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * tweetDetailsCredentialsPublisher;

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    service:(NSObject<TimelineDataSource> *)service title:(NSString *)title
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )managedObjectContext;

- (void)setService:(NSObject<TimelineDataSource> *)aService
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
      forceRefresh:(BOOL)refresh;
- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)replyToTweet;
- (void)refresh;

- (void)addTweet:(Tweet *)tweet displayImmediately:(BOOL)displayImmediately;

@end
