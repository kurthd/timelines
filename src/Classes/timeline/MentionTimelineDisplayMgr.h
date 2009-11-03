//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkAwareViewController.h"
#import "TwitterService.h"
#import "TwitterServiceDelegate.h"
#import "TimelineViewController.h"
#import "TimelineViewControllerDelegate.h"
#import "TweetViewController.h"
#import "DisplayMgrHelper.h"
#import "TweetInfo.h"
#import "TwitterCredentials.h"
#import "NetworkAwareViewControllerDelegate.h"

@interface MentionTimelineDisplayMgr :
    NSObject
    <TwitterServiceDelegate, TimelineViewControllerDelegate,
    TweetViewControllerDelegate, ConversationDisplayMgrDelegate,
    NetworkAwareViewControllerDelegate>
{
    NetworkAwareViewController * wrapperController;
    UINavigationController * navigationController;
    TimelineViewController * timelineController;
    TweetViewController * tweetDetailsController;
    NetworkAwareViewController * lastTweetDetailsWrapperController;
    TweetViewController * lastTweetDetailsController;
    TwitterService * service;
    UITabBarItem * tabBarItem;
    UISegmentedControl * segmentedControl;
    ComposeTweetDisplayMgr * composeTweetDisplayMgr;
    NSManagedObjectContext * managedObjectContext;

    DisplayMgrHelper * displayMgrHelper;

    NSNumber * lastUpdateId;
    NSMutableDictionary * mentions;
    NSString * activeAcctUsername;
    NSString * mentionIdToShow;
    NSInteger numNewMentions;
    TweetInfo * selectedTweet;
    TwitterCredentials * credentials;

    BOOL refreshingMessages;
    BOOL alreadyBeenDisplayedAfterCredentialChange;
    BOOL receivedQueryResponse;
    BOOL displayed;
    NSInteger outstandingRequests;
    NSInteger pagesShown;
    BOOL showBadge;

    NSMutableDictionary * tweetIdToIndexDict;
    NSMutableDictionary * tweetIndexToIdDict;

    // A new conversation display mgr instance is created for every
    // conversation that is viewed. Indeed, we must create a new one, as we
    // must push a unique view controller instance onto the nav stack for
    // each one, and the display mgr owns the view controller.
    //
    // Every conversation display mgr is added to this array. When the
    // timeline view is displayed, the array is emptied.
    NSMutableArray * conversationDisplayMgrs;
}

@property (nonatomic, assign) NSInteger numNewMentions;
@property (nonatomic, assign) BOOL showBadge;
@property (nonatomic, copy) NSString * mentionIdToShow;

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    navigationController:(UINavigationController *)aNavigationController
    timelineController:(TimelineViewController *)timelineController
    service:(TwitterService *)aService
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )managedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr
    userListDisplayMgrFactory:(UserListDisplayMgrFactory *)userListDispMgrFctry
    tabBarItem:(UITabBarItem *)tabBarItem
    segmentedControl:(UISegmentedControl *)segmentedControl;

- (void)refreshWithLatest;
- (void)updateMentionsSinceLastUpdateIds;
- (void)updateWithABunchOfRecentMentions;
- (void)loadAnotherPageOfMentions;
- (void)updateMentionsAfterCredentialChange;

- (void)setTimeline:(NSDictionary *)mentions updateId:(NSNumber *)updateId;

- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)clearState;

@end