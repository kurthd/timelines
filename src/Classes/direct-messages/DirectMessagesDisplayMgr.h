//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "NetworkAwareViewController.h"
#import "DirectMessageInboxViewController.h"
#import "DirectMessageConversationViewController.h"
#import "TwitterServiceDelegate.h"
#import "TwitterService.h"
#import "NetworkAwareViewControllerDelegate.h"
#import "DirectMessageInboxViewControllerDelegate.h"
#import "DirectMessageCache.h"
#import "ComposeTweetDisplayMgr.h"
#import "DirectMessageViewController.h"
#import "DirectMessageViewControllerDelegate.h"
#import "TwitchBrowserViewController.h"
#import "PhotoBrowser.h"
#import "TwitchBrowserViewControllerDelegate.h"
#import "TimelineDisplayMgrFactory.h"
#import "TimelineDisplayMgr.h"
#import "NetworkAwareViewController.h"
#import "CredentialsActivatedPublisher.h"
#import "UserListTableViewController.h"
#import "NewDirectMessagesState.h"
#import "ComposeTweetDisplayMgrDelegate.h"
#import "SavedSearchMgr.h"
#import "UserInfoRequestAdapter.h"
#import "LocationMapViewController.h"
#import "LocationMapViewControllerDelegate.h"
#import "LocationInfoViewController.h"
#import "LocationInfoViewControllerDelegate.h"

/*  This class is responsible for managing the display of the direct messages
    tab.  It will function very similarly to the timeline display, re-using many
    timeline display components, but it will differ in a few key respects.  The
    "inbox view" is the root view and summarizes all conversations with other
    individuals, much like the Apple SMS app inbox view.  This is unique to
    direct messages.  Selecting a conversation between two individuals will also
    be somewhat unique in that cell display will be customized for the two
    individuals in the conversation (one being the user).  Some options will
    be different from public tweets, but otherwise functionality will be similar
    between this tab and a timeline view.  Specifically, this will support
    drilling into DMs just like tweets, opening links, seing a user's recent
    tweets, etc.

    Data is refreshed differently for this view as compared to the timeline
    display manager.  Rather than refreshing with the 20 (or whatever) most
    recent tweets, it will track the update id and attempt to load all tweets
    since then.  If no update id is available a relatively large amount of
    messages may be requested when compared to a timeline view (100 or 200?).
    Push notifications will prompt a refresh (not the user).  When new messages
    are discovered the user will be notified much in the same way the SMS app
    notifies the user of new messages (Buzz, badge, blue dot and preview in
    inbox, etc.).  If new direct messages are available (determined by push),
    a refresh will start when the app opens.
    
    Cache size:
    The cache will never be trimmed during runtime.  All results will simply be
    merged with the existing cache.  The persistence manager may, however, trim
    the cache and load a (most recent) subset of what was previously stored.
*/
@interface DirectMessagesDisplayMgr :
    NSObject <TwitterServiceDelegate, NetworkAwareViewControllerDelegate,
    DirectMessageInboxViewControllerDelegate,
    DirectMessageConversationViewControllerDelegate,
    DirectMessageViewControllerDelegate, MFMailComposeViewControllerDelegate,
    UIActionSheetDelegate, UserInfoViewControllerDelegate,
    LocationMapViewControllerDelegate, LocationInfoViewControllerDelegate>
{
    NetworkAwareViewController * wrapperController;
    DirectMessageInboxViewController * inboxController;
    DirectMessageConversationViewController * conversationController;
    DirectMessageViewController * directMessageViewController;
    SavedSearchMgr * findPeopleBookmarkMgr;
    UserListDisplayMgrFactory * userListDisplayMgrFactory;

    TwitterService * service;

    DirectMessageCache * directMessageCache;
    NSMutableDictionary * conversations;
    NSMutableDictionary * sortedConversations;

    BOOL alreadyBeenDisplayedAfterCredentialChange;

    NSUInteger outstandingReceivedRequests;
    NSUInteger outstandingSentRequests;

    NSString * activeAcctUsername;
    NSString * userInfoUsername;
    User * otherUserInConversation;
    DirectMessage * selectedMessage;

    ComposeTweetDisplayMgr * composeTweetDisplayMgr;

    TimelineDisplayMgrFactory * timelineDisplayMgrFactory;
    TimelineDisplayMgr * tweetDetailsTimelineDisplayMgr;
    NetworkAwareViewController * tweetDetailsNetAwareViewController;
    CredentialsActivatedPublisher * tweetDetailsCredentialsPublisher;
    NSManagedObjectContext * managedObjectContext;

    UserListDisplayMgr * userListDisplayMgr;
    NetworkAwareViewController * userListNetAwareViewController;

    TwitterCredentials * credentials;

    BOOL refreshingMessages;
    BOOL receivedQueryResponse;
    NSArray * newDirectMessages;
    NewDirectMessagesState * newDirectMessagesState;

    NSUInteger loadMoreSentNextPage;
    NSUInteger loadMoreReceivedNextPage;

    UIBarButtonItem * inboxViewComposeTweetButton;
    UIBarButtonItem * sendingTweetProgressView;

    NSNumber * currentConversationUserId;

    SavedSearchMgr * savedSearchMgr;
    NSString * currentSearch;

    UserInfoViewController * userInfoController;

    NetworkAwareViewController * userInfoControllerWrapper;
    UserInfoRequestAdapter * userInfoRequestAdapter;
    TwitterService * userInfoTwitterService;

    LocationMapViewController * locationMapViewController;
    LocationInfoViewController * locationInfoViewController;
}

@property (nonatomic, retain) DirectMessageCache * directMessageCache;

@property (readonly)
    DirectMessageConversationViewController * conversationController;
@property (readonly) DirectMessageViewController * directMessageViewController;

@property (nonatomic, copy) NSString * activeAcctUsername;
@property (nonatomic, retain) User * otherUserInConversation;
@property (nonatomic, retain) DirectMessage * selectedMessage;

@property (nonatomic, retain)
    TimelineDisplayMgr * tweetDetailsTimelineDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * tweetDetailsNetAwareViewController;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * tweetDetailsCredentialsPublisher;

@property (nonatomic, readonly) UITabBarItem * tabBarItem;

@property (nonatomic, copy) NSArray * newDirectMessages;
@property (nonatomic, retain) NewDirectMessagesState * newDirectMessagesState;

@property (nonatomic, readonly) UIBarButtonItem * sendingTweetProgressView;
@property (nonatomic, readonly) UIBarButtonItem * newMessageButtonItem;

@property (nonatomic, copy) NSNumber * currentConversationUserId;

@property (readonly) NetworkAwareViewController * userInfoControllerWrapper;
@property (readonly) UserInfoRequestAdapter * userInfoRequestAdapter;
@property (readonly) TwitterService * userInfoTwitterService;

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    inboxController:(DirectMessageInboxViewController *)anInboxController
    service:(TwitterService *)aService
    initialCache:(DirectMessageCache *)initialCache
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )managedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr
    userListDisplayMgrFactory:(UserListDisplayMgrFactory *)userListDispMgrFctry;

- (void)setCredentials:(TwitterCredentials *)credentials;
- (void)clearState;

- (void)refreshWithLatest;
- (void)updateDirectMessagesSinceLastUpdateIds;
- (void)updateWithABunchOfRecentMessages;
- (void)loadAnotherPageOfMessages;

- (void)viewAppearedForFirstTimeAfterCredentialChange;

- (void)updateDisplayForSendingDirectMessage;
- (void)updateDisplayForFailedDirectMessage:(NSString *)recipient;
- (void)addDirectMessage:(DirectMessage *)dm;

@end
