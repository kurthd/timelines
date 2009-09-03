
//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessagesDisplayMgr.h"
#import "ConversationPreview.h"
#import "DirectMessage.h"
#import "TweetInfo.h"
#import "ArbUserTimelineDataSource.h"
#import "UIAlertView+InstantiationAdditions.h"
#include <AudioToolbox/AudioToolbox.h>
#import "InfoPlistConfigReader.h"
#import "SearchDataSource.h"
#import "RegexKitLite.h"
#import "FavoritesTimelineDataSource.h"
#import "UserListDisplayMgrFactory.h"
#import "ErrorState.h"

@interface DirectMessagesDisplayMgr ()

- (void)fetchDirectMessagesSinceId:(NSNumber *)updateId page:(NSNumber *)page
    numMessages:(NSNumber *)numMessages;
- (void)fetchSentDirectMessagesSinceId:(NSNumber *)updateId
    page:(NSNumber *)page numMessages:(NSNumber *)numMessages;
- (void)setUpdatingState;
- (void)updateViewsWithNewMessages;
- (void)constructConversationsFromMessages;
- (NSArray *)constructConversationPreviewsFromMessages;
- (void)composeNewDirectMessage;
- (void)sendDirectMessageToOtherUserInConversation;
- (void)deallocateTweetDetailsNode;
- (void)updateBadge;
- (void)presentFailedDirectMessageOnTimer:(NSTimer *)timer;

- (void)removeSearch:(NSString *)search;
- (void)saveSearch:(NSString *)search;

- (UIView *)saveSearchView;
- (UIView *)removeSearchView;
- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title
    action:(SEL)action;

- (void)displayComposerMailSheet;

- (void)sendDirectMessageToCurrentUser;

+ (BOOL)displayWithUsername;

@property (nonatomic, retain) SavedSearchMgr * savedSearchMgr;
@property (nonatomic, retain) NSString * currentSearch;

@property (readonly) UserInfoViewController * userInfoController;

@property (nonatomic, retain) UserListDisplayMgr * userListDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * userListNetAwareViewController;

@property (nonatomic, readonly)
    LocationMapViewController * locationMapViewController;
@property (nonatomic, readonly)
    LocationInfoViewController * locationInfoViewController;

@end

@implementation DirectMessagesDisplayMgr

static BOOL displayWithUsername;
static BOOL alreadyReadDisplayWithUsernameValue;

@synthesize activeAcctUsername, otherUserInConversation, selectedMessage,
    tweetDetailsTimelineDisplayMgr, tweetDetailsNetAwareViewController,
    tweetDetailsCredentialsPublisher, userListNetAwareViewController,
    userListDisplayMgr, directMessageCache, newDirectMessages,
    newDirectMessagesState, currentConversationUserId, currentSearch,
    savedSearchMgr, userInfoController;

- (void)dealloc
{
    [wrapperController release];
    [inboxController release];
    [tweetViewController release];
    [service release];
    [directMessageCache release];
    [conversations release];
    [sortedConversations release];
    [managedObjectContext release];
    [composeTweetDisplayMgr release];
    [composeMessageDisplayMgr release];
    [credentials release];
    [newDirectMessages release];
    [newDirectMessagesState release];
    [sendingTweetProgressView release];
    [findPeopleBookmarkMgr release];
    [userListDisplayMgr release];
    [userListNetAwareViewController release];
    [userListDisplayMgrFactory release];
    [userInfoControllerWrapper release];
    [userInfoRequestAdapter release];
    [userInfoTwitterService release];
    [locationMapViewController release];
    [locationInfoViewController release];
    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    inboxController:(DirectMessageInboxViewController *)anInboxController
    service:(TwitterService *)aService
    initialCache:(DirectMessageCache *)initialCache
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )aManagedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr
    userListDisplayMgrFactory:(UserListDisplayMgrFactory *)userListDispMgrFctry
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        inboxController = [anInboxController retain];
        service = [aService retain];
        timelineDisplayMgrFactory = [factory retain];
        managedObjectContext = [aManagedObjectContext retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        findPeopleBookmarkMgr = [aFindPeopleBookmarkMgr retain];
        userListDisplayMgrFactory = [userListDispMgrFctry retain];

        if (initialCache) {
            directMessageCache = [initialCache retain];
            [wrapperController setCachedDataAvailable:YES];
        } else {
            directMessageCache = [[DirectMessageCache alloc] init];
            [wrapperController setCachedDataAvailable:NO];
        }

        conversations = [[NSMutableDictionary dictionary] retain];
        sortedConversations = [[NSMutableDictionary dictionary] retain];

        UIBarButtonItem * composeDirectMessageButton =
            wrapperController.navigationItem.rightBarButtonItem;
        composeDirectMessageButton.target = self;
        composeDirectMessageButton.action = @selector(composeNewDirectMessage);

        UIBarButtonItem * refreshButton =
            wrapperController.navigationItem.leftBarButtonItem;
        refreshButton.target = self;
        refreshButton.action = @selector(refreshWithLatest);

        newDirectMessagesState = [[NewDirectMessagesState alloc] init];
        
        loadMoreSentNextPage = 1;
        loadMoreReceivedNextPage = 1;
    }

    return self;
}

#pragma mark TwitterServiceDelegate implementation

- (void)directMessages:(NSArray *)directMessages
    fetchedSinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
    count:(NSNumber *)count
{
    NSLog(@"Messages Display Manager: Received direct messages (%d)...",
        [directMessages count]);
    [directMessageCache addReceivedDirectMessages:directMessages];
    outstandingReceivedRequests--;
    receivedQueryResponse = YES;

    if ([directMessages count] > 0) {
        NSArray * sortedDirectMessages =
            [directMessages sortedArrayUsingSelector:@selector(compare:)];
        DirectMessage * mostRecentMessage =
            [sortedDirectMessages objectAtIndex:0];
        long long updateIdAsLongLong =
            [mostRecentMessage.identifier longLongValue];
        directMessageCache.receivedUpdateId =
            [NSNumber numberWithLongLong:updateIdAsLongLong];
    }

    if (refreshingMessages) {
        if ([directMessages count] > 0) {
            [newDirectMessagesState incrementCountBy:[directMessages count]];
            [self updateBadge];
            self.newDirectMessages = directMessages;

            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        }
    } else
        loadMoreReceivedNextPage = [page intValue] + 1;

    [self updateViewsWithNewMessages];
    [[ErrorState instance] exitErrorState];
}

- (void)failedToFetchDirectMessagesSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
{
    NSLog(@"Message Display Manager: failed to fetch timeline since %@",
        updateId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchmessages", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error
        retryTarget:self retryAction:@selector(refreshWithLatest)];
    [wrapperController setUpdatingState:kDisconnected];

    outstandingReceivedRequests--;
}

- (void)sentDirectMessages:(NSArray *)directMessages
    fetchedSinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
    count:(NSNumber *)count
{
    NSLog(@"Messages Display Manager: Received sent direct messages (%d)...",
        [directMessages count]);
    [directMessageCache addSentDirectMessages:directMessages];

    outstandingSentRequests--;
    receivedQueryResponse = YES;

    if ([directMessages count] > 0) {
        NSArray * sortedDirectMessages =
            [directMessages sortedArrayUsingSelector:@selector(compare:)];
        DirectMessage * mostRecentMessage =
            [sortedDirectMessages objectAtIndex:0];
        long long updateIdAsLongLong =
            [mostRecentMessage.identifier longLongValue];
        directMessageCache.sentUpdateId =
            [NSNumber numberWithLongLong:updateIdAsLongLong];
    }

    if (!refreshingMessages)
        loadMoreSentNextPage = [page intValue] + 1;

    [self updateViewsWithNewMessages];
    [[ErrorState instance] exitErrorState];
}

- (void)failedToFetchSentDirectMessagesSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
{
    NSLog(@"Message Display Manager: failed to fetch timeline since %@",
        updateId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchmessages", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error
        retryTarget:self retryAction:@selector(refreshWithLatest)];
    [wrapperController setUpdatingState:kDisconnected];

    outstandingSentRequests--;
}

- (void)user:(NSString *)username isFollowing:(NSString *)followee
{
    NSLog(@"Direct message display manager: %@ is following %@", username,
        followee);
    [self.userInfoController setFollowing:YES];
    [[ErrorState instance] exitErrorState];
}

- (void)user:(NSString *)username isNotFollowing:(NSString *)followee
{
    NSLog(@"Direct message display manager: %@ is not following %@", username,
        followee);
    [self.userInfoController setFollowing:NO];
    [[ErrorState instance] exitErrorState];
}

- (void)failedToQueryIfUser:(NSString *)username
    isFollowing:(NSString *)followee error:(NSError *)error
{
    NSLog(@"Direct message display mgr: failed to query if %@ is following %@",
        username, followee);
    NSLog(@"Error: %@", error);

    [self.userInfoController setFailedToQueryFollowing];

    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.followingstatus", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)userIsBlocked:(NSString *)username
{
    if ([self.otherUserInConversation.username isEqual:username])
        [self.userInfoController setBlocked:YES];
}

- (void)userIsNotBlocked:(NSString *)username
{
    if ([self.otherUserInConversation.username isEqual:username])
        [self.userInfoController setBlocked:NO];
}

- (void)blockedUser:(User *)user withUsername:(NSString *)username
{
    if ([self.otherUserInConversation.username isEqual:username])
        [self.userInfoController setBlocked:YES];
}

- (void)failedToBlockUserWithUsername:(NSString *)username
    error:(NSError *)error
{
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.unblock", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)unblockedUser:(User *)user withUsername:(NSString *)username
{
    if ([self.otherUserInConversation.username isEqual:username])
        [self.userInfoController setBlocked:NO];
}

- (void)failedToUnblockUserWithUsername:(NSString *)username
    error:(NSError *)error
{
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.unblock", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, username];
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
}

- (void)startedFollowingUsername:(NSString *)aUsername
{
    NSLog(@"Direct message display manager: started following '%@'", aUsername);
    [userInfoController setFollowing:YES];
}

- (void)failedToStartFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.startfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, aUsername];
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)stoppedFollowingUsername:(NSString *)aUsername
{
    NSLog(@"Direct message display manager: stopped following '%@'", aUsername);
    [userInfoController setFollowing:NO];
}

- (void)failedToStopFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.stopfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, aUsername];
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)failedToDeleteDirectMessageWithId:(NSString *)directMessageId
    error:(NSError *)error;
{
    NSLog(@"Direct message display manager: failed to delete direct message");
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.deletedirectmessage", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    NSLog(@"Message Display Manager: view will appear");
    if (!alreadyBeenDisplayedAfterCredentialChange)
        [self viewAppearedForFirstTimeAfterCredentialChange];
}

#pragma mark DirectMessageInboxViewControllerDelegate implementation

- (void)selectedConversationPreview:(ConversationPreview *)preview
{
    self.currentConversationUserId = preview.otherUserId;
    NSLog(@"Messages Display Manager: Selected conversation for user '%@'",
        self.currentConversationUserId);

    NSArray * messages =
        [sortedConversations objectForKey:self.currentConversationUserId];
    DirectMessage * firstMessage = [messages objectAtIndex:0];

    self.otherUserInConversation =
        [firstMessage.sender.username isEqual:activeAcctUsername] ?
        firstMessage.recipient : firstMessage.sender;

    NSString * name =
        self.otherUserInConversation.name &&
        ![[self class] displayWithUsername] ?
        self.otherUserInConversation.name :
        self.otherUserInConversation.username;

    self.conversationController.navigationItem.title = name;
    [wrapperController.navigationController
        pushViewController:self.conversationController animated:YES];
    [self.conversationController setMessages:messages];
    NSUInteger newMessageCountForUserAsInt =
        [newDirectMessagesState countForUserId:preview.otherUserId];
    newMessageCountForUserAsInt =
        newMessageCountForUserAsInt - preview.numNewMessages;

    // this will also update the total count
    [newDirectMessagesState setCount:newMessageCountForUserAsInt
        forUserId:preview.otherUserId];

    [self updateBadge];
}

#pragma mark DirectMessageConversationViewControllerDelegate implementation

- (void)selectedTweet:(DirectMessage *)message
    avatarImage:(UIImage *)avatarImage
{
    // HACK: forces to scroll to top
    [self.tweetViewController.tableView setContentOffset:CGPointMake(0, 300)
        animated:NO];

    NSLog(@"Message display manager: selected message: %@", message);
    self.selectedMessage = message;

    BOOL tweetByUser = [message.sender.username isEqual:activeAcctUsername];
    self.tweetViewController.navigationItem.rightBarButtonItem.enabled =
        !tweetByUser;
    [self.tweetViewController setUsersTweet:tweetByUser];
    self.tweetViewController.showsExtendedActions = NO;

    UIBarButtonItem * rightBarButtonItem =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self
        action:@selector(presentDirectMessageActions)];
    self.tweetViewController.navigationItem.rightBarButtonItem =
        rightBarButtonItem;
    [rightBarButtonItem release];

    self.tweetViewController.navigationItem.title =
        NSLocalizedString(@"tweetdetailsview.title.directmessage", @"");
    [self.tweetViewController setUsersTweet:YES];
    [self.tweetViewController hideFavoriteButton:YES];

    TweetInfo * tweetInfo = [TweetInfo createFromDirectMessage:message];
    [self.tweetViewController displayTweet:tweetInfo
        onNavigationController:wrapperController.navigationController];
    self.tweetViewController.allowDeletion =
        [message.sender.username isEqual:activeAcctUsername];
}

#pragma mark TweetDetailsViewDelegate implementation

- (void)showUserInfo
{
    [self showUserInfoForUser:otherUserInConversation];
}

- (void)showUserInfoForUser:(User *)aUser
{
    NSLog(@"Direct message display manager: showing user info for %@", aUser);
    // HACK: forces to scroll to top
    [self.userInfoController.tableView setContentOffset:CGPointMake(0, 300)
        animated:NO];

    self.userInfoController.navigationItem.title = aUser.username;
    [wrapperController.navigationController
        pushViewController:self.userInfoController animated:YES];
    self.userInfoController.followingEnabled =
        ![credentials.username isEqual:aUser.username];
    [self.userInfoController setUser:aUser];
    if (self.userInfoController.followingEnabled)
        [service isUser:credentials.username following:aUser.username];
    [service isUserBlocked:aUser.username];
}

- (void)showUserInfoForUsername:(NSString *)aUsername
{
    // HACK: forces to scroll to top
    [self.userInfoController.tableView setContentOffset:CGPointMake(0, 300)
        animated:NO];
    [self.userInfoController showingNewUser];
    self.userInfoControllerWrapper.navigationItem.title = aUsername;
    [self.userInfoControllerWrapper setCachedDataAvailable:NO];
    [self.userInfoControllerWrapper setUpdatingState:kConnectedAndUpdating];
    [wrapperController.navigationController
        pushViewController:self.userInfoControllerWrapper animated:YES];
    self.userInfoController.followingEnabled =
        ![credentials.username isEqual:aUsername];

    if (self.userInfoController.followingEnabled)
        [service isUser:credentials.username following:aUsername];

    [self.userInfoTwitterService fetchUserInfoForUsername:aUsername];
}

- (void)showTweetsForUser:(NSString *)username
{
    NSLog(@"Direct Message Manager: showing tweets for %@", username);

    NSString * title =
        NSLocalizedString(@"timelineview.usertweets.title", @"");
    self.tweetDetailsNetAwareViewController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];
    
    self.tweetDetailsTimelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        tweetDetailsNetAwareViewController
        title:title composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.tweetDetailsTimelineDisplayMgr.displayAsConversation = NO;
    self.tweetDetailsTimelineDisplayMgr.setUserToFirstTweeter = YES;
    [self.tweetDetailsTimelineDisplayMgr
        setTimelineHeaderView:nil];
    self.tweetDetailsTimelineDisplayMgr.currentUsername = username;
    [self.tweetDetailsTimelineDisplayMgr setCredentials:credentials];

    UIBarButtonItem * sendDMButton =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
        target:self.tweetDetailsTimelineDisplayMgr
        action:@selector(sendDirectMessageToCurrentUser)];
    
    self.tweetDetailsNetAwareViewController.navigationItem.rightBarButtonItem =
        sendDMButton;
    
    self.tweetDetailsNetAwareViewController.delegate =
        self.tweetDetailsTimelineDisplayMgr;
    
    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:managedObjectContext]
        autorelease];
    
    ArbUserTimelineDataSource * dataSource =
        [[[ArbUserTimelineDataSource alloc]
        initWithTwitterService:twitterService
        username:username]
        autorelease];
    
    self.tweetDetailsCredentialsPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];
    
    twitterService.delegate = dataSource;
    [self.tweetDetailsTimelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO allPagesLoaded:NO];
    dataSource.delegate = self.tweetDetailsTimelineDisplayMgr;
    
    [dataSource setCredentials:credentials];
    [wrapperController.navigationController
        pushViewController:self.tweetDetailsNetAwareViewController
        animated:YES];
}

- (void)showResultsForSearch:(NSString *)query
{
    NSLog(@"Direct Message Manager: showing search results for '%@'", query);
    self.currentSearch = query;

    self.tweetDetailsNetAwareViewController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.tweetDetailsTimelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        tweetDetailsNetAwareViewController
        title:query composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.tweetDetailsTimelineDisplayMgr.displayAsConversation = NO;
    self.tweetDetailsTimelineDisplayMgr.setUserToFirstTweeter = NO;
    self.tweetDetailsTimelineDisplayMgr.currentUsername = nil;
    UIView * headerView =
        [self.savedSearchMgr isSearchSaved:query] ?
        [self removeSearchView] : [self saveSearchView];
    [self.tweetDetailsTimelineDisplayMgr setTimelineHeaderView:headerView];
    [self.tweetDetailsTimelineDisplayMgr setCredentials:credentials];

    self.tweetDetailsNetAwareViewController.navigationItem.rightBarButtonItem =
        nil;

    self.tweetDetailsNetAwareViewController.delegate =
        self.tweetDetailsTimelineDisplayMgr;

    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:managedObjectContext]
        autorelease];

    SearchDataSource * dataSource =
        [[[SearchDataSource alloc]
        initWithTwitterService:twitterService
        query:query]
        autorelease];

    self.tweetDetailsCredentialsPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];

    twitterService.delegate = dataSource;
    [self.tweetDetailsTimelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO allPagesLoaded:NO];
    dataSource.delegate = self.tweetDetailsTimelineDisplayMgr;

    [dataSource setCredentials:credentials];
    [wrapperController.navigationController
        pushViewController:self.tweetDetailsNetAwareViewController
        animated:YES];
}

- (void)showLocationOnMap:(NSString *)locationString
{
    NSLog(@"Direct message display manager: showing %@ on map", locationString);

    self.locationMapViewController.navigationItem.title = @"Map";
    
    [wrapperController.navigationController
        pushViewController:self.locationMapViewController animated:YES];

    [self.locationMapViewController setLocation:locationString];
}

- (void)showLocationInfo:(NSString *)locationString
    coordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"Direct message display manager: showing location info for %@",
        locationString);

    [wrapperController.navigationController
        pushViewController:self.locationInfoViewController animated:YES];

    [self.locationInfoViewController setLocationString:locationString
        coordinate:coordinate];
}

- (void)showingTweetDetails:(TweetViewController *)tweetController
{
    NSLog(@"Messages Display Manager: showing tweet details...");
    [self deallocateTweetDetailsNode];
}

- (void)loadNewTweetWithId:(NSString *)tweetId username:(NSString *)username
{
    // not supported for direct messages
}

- (void)setCurrentTweetDetailsUser:(NSString *)username
{
    // not supported for direct messages
}

- (void)reTweetSelected
{
    // not supported for direct messages
}

- (void)replyToTweet
{
    [self sendDirectMessageToOtherUserInConversation];
}

- (void)sendDirectMessageToUser:(NSString *)aUsername
{
    NSLog(@"Direct message display manager: sending direct message to %@",
        aUsername);
    [self.composeMessageDisplayMgr composeDirectMessageTo:aUsername];
}

- (void)sendPublicMessageToUser:(NSString *)aUsername
{
    NSLog(@"Direct message display manager: sending public message to %@",
        aUsername);
    [composeTweetDisplayMgr
        composeTweetWithText:[NSString stringWithFormat:@"@%@ ", aUsername]];
}

- (void)setFavorite:(BOOL)favorite
{
    // not supported for direct messages
}

- (void)loadConversationFromTweetId:(NSString *)tweetId
{
    // not supported for direct messages
}

#pragma mark UserInfoViewControllerDelegate implementation

- (void)showingUserInfoView
{
    NSLog(@"Direct message display manager: showing user info view");
    [self deallocateTweetDetailsNode];
}

- (void)startFollowingUser:(NSString *)username
{
    NSLog(@"Timeline display manager: sending 'follow user' request for %@",
        username);
    [service followUser:username];
}

- (void)stopFollowingUser:(NSString *)username
{
    NSLog(@"Timeline display manager: sending 'stop following' request for %@",
        username);
    [service stopFollowingUser:username];
}

- (void)blockUser:(NSString *)username
{
    [service blockUserWithUsername:username];
}

- (void)unblockUser:(NSString *)username
{
    [service unblockUserWithUsername:username];
}

- (void)displayFavoritesForUser:(NSString *)username
{
    NSLog(@"Direct message display manager: displaying favorites for user %@",
        username);
    NSString * title =
        NSLocalizedString(@"timelineview.favorites.title", @"");
    self.tweetDetailsNetAwareViewController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.tweetDetailsTimelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        tweetDetailsNetAwareViewController
        title:title composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.tweetDetailsTimelineDisplayMgr.displayAsConversation = YES;
    self.tweetDetailsTimelineDisplayMgr.setUserToFirstTweeter = NO;
    [self.tweetDetailsTimelineDisplayMgr setCredentials:credentials];

    self.tweetDetailsNetAwareViewController.delegate =
        self.tweetDetailsTimelineDisplayMgr;

    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:managedObjectContext]
        autorelease];

    FavoritesTimelineDataSource * dataSource =
        [[[FavoritesTimelineDataSource alloc]
        initWithTwitterService:twitterService
        username:username]
        autorelease];

    self.tweetDetailsCredentialsPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];

    twitterService.delegate = dataSource;
    [self.tweetDetailsTimelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO allPagesLoaded:NO];
    dataSource.delegate = self.tweetDetailsTimelineDisplayMgr;

    [dataSource setCredentials:credentials];
    [wrapperController.navigationController
        pushViewController:self.tweetDetailsNetAwareViewController
        animated:YES];
}

- (void)displayFollowingForUser:(NSString *)username
{
    NSLog(@"Direct message display manager: displaying 'following' list for %@",
        username);

    self.userListNetAwareViewController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.userListDisplayMgr =
        [userListDisplayMgrFactory
        createUserListDisplayMgrWithWrapperController:
        self.userListNetAwareViewController
        composeTweetDisplayMgr:composeTweetDisplayMgr
        showFollowing:YES
        username:username];
    [self.userListDisplayMgr setCredentials:credentials];

    [wrapperController.navigationController
        pushViewController:self.userListNetAwareViewController animated:YES];
}

- (void)displayFollowersForUser:(NSString *)username
{
    NSLog(@"Direct message display manager: displaying 'followers' list for %@",
        username);

    self.userListNetAwareViewController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.userListDisplayMgr =
        [userListDisplayMgrFactory
        createUserListDisplayMgrWithWrapperController:
        self.userListNetAwareViewController
        composeTweetDisplayMgr:composeTweetDisplayMgr
        showFollowing:NO
        username:username];
    [self.userListDisplayMgr setCredentials:credentials];

    [wrapperController.navigationController
        pushViewController:self.userListNetAwareViewController animated:YES];
}

- (void)deleteTweet:(NSString *)tweetId
{
    [service deleteDirectMessage:tweetId];
    [conversationController performSelector:@selector(deleteTweet:)
        withObject:tweetId afterDelay:0.5];
}

#pragma mark TwitchBrowserViewControllerDelegate implementation

- (void)composeTweetWithText:(NSString *)text
{
    NSLog(@"Messages display manager: composing new tweet with text '%@'...",
        text);
    [composeTweetDisplayMgr composeTweetWithText:text];
}

- (void)readLater:(NSString *)url
{
    // TODO: implement me
}

#pragma mark ComposeTweetDisplayMgrDelegate implementation

- (void)userDidCancelComposingTweet
{
    // Not applicable
}

- (void)userIsSendingTweet:(NSString *)tweet
{
    // Not applicable
}

- (void)userDidSendTweet:(Tweet *)tweet
{
    // Not applicable
}

- (void)userFailedToSendTweet:(NSString *)tweet
{
    // Not applicable
}

- (void)userIsReplyingToTweet:(NSString *)origTweetId
                     fromUser:(NSString *)origUsername
                     withText:(NSString *)text
{
}

- (void)userDidReplyToTweet:(NSString *)origTweetId
                   fromUser:(NSString *)origUsername
                  withTweet:(Tweet *)reply
{
    // Not applicable
}

- (void)userFailedToReplyToTweet:(NSString *)origTweetId
                        fromUser:(NSString *)origUsername
                        withText:(NSString *)text
{
    // Not applicable
}

- (void)userIsSendingDirectMessage:(NSString *)dm to:(NSString *)username
{
    [self.conversationController.navigationItem
        setRightBarButtonItem:[self sendingTweetProgressView] animated:YES];
}

- (void)userDidSendDirectMessage:(DirectMessage *)dm
{
    [self.conversationController.navigationItem
        setRightBarButtonItem:[self newMessageButtonItem] animated:YES];
        
    if ([dm.recipient.identifier isEqual:self.currentConversationUserId])
        [self.conversationController addTweet:dm];
    
    [directMessageCache addSentDirectMessage:dm];
    [self updateViewsWithNewMessages];
}

- (void)userFailedToSendDirectMessage:(NSString *)dm to:(NSString *)username
{
    NSDictionary * userInfo =
        [NSDictionary dictionaryWithObjectsAndKeys:
        dm, @"dm",
        username, @"username", nil];

    // if the error happened quickly, while the compose modal view is still
    // dismissing, re-presenting it has no effect; force a brief delay for now
    // and revisit later
    SEL sel = @selector(presentFailedDirectMessageOnTimer:);
    [NSTimer scheduledTimerWithTimeInterval:0.8
                                     target:self
                                   selector:sel
                                   userInfo:userInfo
                                    repeats:NO];
}

- (void)presentFailedDirectMessageOnTimer:(NSTimer *)timer
{
    NSDictionary * userInfo = timer.userInfo;
    NSString * dm = [userInfo objectForKey:@"dm"];
    NSString * username = [userInfo objectForKey:@"username"];

    [self.composeMessageDisplayMgr composeDirectMessageTo:username withText:dm];
}

#pragma mark UIActionSheetDelegate implementation

- (void)actionSheet:(UIActionSheet *)sheet
    clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"User clicked button at index: %d.", buttonIndex);

    NSString * title =
        NSLocalizedString(@"photobrowser.unabletosendmail.title", @"");
    NSString * message =
        NSLocalizedString(@"photobrowser.unabletosendmail.message", @"");

    switch (buttonIndex) {
        case 0:
            NSLog(@"Sending tweet in email...");
            if ([MFMailComposeViewController canSendMail])
                [self displayComposerMailSheet];
            else {     
                UIAlertView * alert =
                    [UIAlertView simpleAlertViewWithTitle:title
                    message:message];
                [alert show];
            }
            break;
    }

    [sheet autorelease];
}

#pragma mark MFMailComposeViewControllerDelegate implementation

- (void)mailComposeController:(MFMailComposeViewController *)controller
    didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    
    if (result == MFMailComposeResultFailed) {
        NSString * title =
            NSLocalizedString(@"photobrowser.emailerror.title", @"");
        UIAlertView * alert =
            [UIAlertView simpleAlertViewWithTitle:title
            message:[error description]];
        [alert show];
    }

    [controller dismissModalViewControllerAnimated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
}


#pragma mark Public DirectMessagesDisplayMgr implementation

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Message display manager: setting credentials to '%@'",
        someCredentials);

    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:credentials];

    self.activeAcctUsername = credentials.username;
    self.savedSearchMgr.accountName = credentials.username;

    self.conversationController.segregatedSenderUsername = credentials.username;

    [wrapperController.navigationController
        popToRootViewControllerAnimated:NO];
}

- (void)clearState
{
    [conversations removeAllObjects];
    [sortedConversations removeAllObjects];
    alreadyBeenDisplayedAfterCredentialChange = NO;
    self.newDirectMessages = nil;
    loadMoreSentNextPage = 1;
    loadMoreReceivedNextPage = 1;
    refreshingMessages = NO;
    [inboxController setNumReceivedMessages:0 sentMessages:0];
    self.currentConversationUserId = nil;
    receivedQueryResponse = NO;
}

- (void)viewAppearedForFirstTimeAfterCredentialChange
{
    if (directMessageCache.receivedUpdateId && directMessageCache.sentUpdateId)
        [self updateDirectMessagesSinceLastUpdateIds];
    else
        [self updateWithABunchOfRecentMessages];
    alreadyBeenDisplayedAfterCredentialChange = YES;
}

- (void)updateDirectMessagesSinceLastUpdateIds
{
    NSNumber * receivedUpdateId = directMessageCache.receivedUpdateId;
    NSNumber * sentUpdateId = directMessageCache.sentUpdateId;
    NSLog(@"Messages Display Manager: Updating since update id %@, %@...",
        receivedUpdateId, sentUpdateId);
    if (receivedUpdateId && sentUpdateId) {
        refreshingMessages = YES;
        [self fetchDirectMessagesSinceId:receivedUpdateId page:nil
            numMessages:nil];
        [self fetchSentDirectMessagesSinceId:sentUpdateId page:nil
            numMessages:nil];

        [self setUpdatingState];
    } else
        [self updateWithABunchOfRecentMessages];
}

- (void)refreshWithLatest
{
    [[ErrorState instance] exitErrorState];
    [self updateDirectMessagesSinceLastUpdateIds];
}

- (void)updateWithABunchOfRecentMessages
{
    NSLog(@"Messages Display Manager: Updating with a bunch of messages...");
    refreshingMessages = NO;
    NSNumber * count = [NSNumber numberWithInteger:200];
    [self fetchDirectMessagesSinceId:nil page:[NSNumber numberWithInt:1]
        numMessages:count];
    [self fetchSentDirectMessagesSinceId:nil
        page:[NSNumber numberWithInt:1] numMessages:count];

    [self setUpdatingState];
}

- (void)loadAnotherPageOfMessages
{
    NSLog(@"Messages Display Manager: Loading more messages (page %d)...",
        loadMoreReceivedNextPage);
    refreshingMessages = NO;
    NSNumber * count = [NSNumber numberWithInteger:200];
    [self fetchDirectMessagesSinceId:nil
        page:[NSNumber numberWithInt:loadMoreReceivedNextPage]
        numMessages:count];
    [self fetchSentDirectMessagesSinceId:nil
        page:[NSNumber numberWithInt:loadMoreSentNextPage] numMessages:count];

    [self setUpdatingState];
}

- (DirectMessageConversationViewController *)conversationController
{
    if (!conversationController) {
        conversationController = 
            [[DirectMessageConversationViewController alloc]
            initWithNibName:@"DirectMessageConversationView" bundle:nil];
        conversationController.delegate = self;
        
        UIBarButtonItem * composeMessageButton =
            [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
            target:self
            action:@selector(sendDirectMessageToOtherUserInConversation)]
            autorelease];
        conversationController.navigationItem.rightBarButtonItem =
            composeMessageButton;
    }

    return conversationController;
}

- (TweetViewController *)tweetViewController
{
    if (!tweetViewController) {
        tweetViewController =
            [[TweetViewController alloc]
            initWithNibName:@"TweetView" bundle:nil];

        UIBarButtonItem * replyButton =
            [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self
            action:@selector(presentTweetActions)]
            autorelease];
        [tweetViewController.navigationItem
            setRightBarButtonItem:replyButton];

        NSString * title = NSLocalizedString(@"tweetdetailsview.title", @"");
        tweetViewController.navigationItem.title = title;
        tweetViewController.delegate = self;
    }

    return tweetViewController;
}

- (void)setDirectMessageCache:(DirectMessageCache *)aMessageCache
{
    [aMessageCache retain];
    [directMessageCache release];
    directMessageCache = aMessageCache;

    [self updateViewsWithNewMessages];
}

- (void)setNewDirectMessagesState:(NewDirectMessagesState *)state
{
    [state retain];
    [newDirectMessagesState release];
    newDirectMessagesState = state;

    [self updateViewsWithNewMessages];
    [self updateBadge];
}

- (UITabBarItem *)tabBarItem
{
    return wrapperController.parentViewController.tabBarItem;
}

- (ComposeTweetDisplayMgr *)composeMessageDisplayMgr
{
    if (!composeMessageDisplayMgr) {
        TwitterService * twitterService = [service clone];  // autoreleased

        composeMessageDisplayMgr =
            [[ComposeTweetDisplayMgr alloc]
            initWithRootViewController:wrapperController.tabBarController
                        twitterService:twitterService
                               context:managedObjectContext];
        composeMessageDisplayMgr.delegate = self;
    }

    return composeMessageDisplayMgr;
}

- (UIBarButtonItem *)sendingTweetProgressView
{
    if (!sendingTweetProgressView) {
        UIActivityIndicatorView * view =
            [[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

        sendingTweetProgressView =
            [[UIBarButtonItem alloc] initWithCustomView:view];

        [view startAnimating];

        [view release];
    }

    return sendingTweetProgressView;
}

- (UIBarButtonItem *)newMessageButtonItem
{
    UIBarButtonItem * button =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self
        action:@selector(sendDirectMessageToOtherUserInConversation)];

    return [button autorelease];
}

#pragma mark Private DirectMessagesDisplayMgr implementation

- (void)fetchDirectMessagesSinceId:(NSNumber *)updateId page:(NSNumber *)page
    numMessages:(NSNumber *)numMessages
{
    if (outstandingReceivedRequests == 0) { // only one at a time
        outstandingReceivedRequests++;
        [service fetchDirectMessagesSinceId:updateId page:page
            count:numMessages];
    }
}

- (void)fetchSentDirectMessagesSinceId:(NSNumber *)updateId
    page:(NSNumber *)page numMessages:(NSNumber *)numMessages
{
    if (outstandingSentRequests == 0) { // only one at a time
        outstandingSentRequests++;
        [service fetchSentDirectMessagesSinceId:updateId page:page
            count:numMessages];
    }
}

- (void)setUpdatingState
{
    if (outstandingReceivedRequests == 0 && outstandingSentRequests == 0)
        [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    else
        [wrapperController setUpdatingState:kConnectedAndUpdating];
}

- (void)updateViewsWithNewMessages
{
    [self setUpdatingState];
    if (outstandingReceivedRequests == 0 && outstandingSentRequests == 0) {
        [self constructConversationsFromMessages];
        [inboxController setConversationPreviews:
            [self constructConversationPreviewsFromMessages]];
            
        BOOL cachedData =
            receivedQueryResponse ||
            [[directMessageCache receivedDirectMessages] count] > 0 ||
            [[directMessageCache sentDirectMessages] count];

        [wrapperController setCachedDataAvailable:cachedData];

        NSUInteger numReceived =
            [[directMessageCache receivedDirectMessages] count];
        NSUInteger numSent = [[directMessageCache sentDirectMessages] count];
        [inboxController setNumReceivedMessages:numReceived
            sentMessages:numSent];
    }
}

- (void)constructConversationsFromMessages
{
    NSDictionary * receivedDirectMessages =
        directMessageCache.receivedDirectMessages;
    NSDictionary * sentDirectMessages = directMessageCache.sentDirectMessages;
    for (DirectMessage * directMessage in [receivedDirectMessages allValues]) {
        NSString * identifier = directMessage.sender.identifier;
        NSMutableDictionary * conversation =
            [conversations objectForKey:identifier];
        if (!conversation) {
            conversation = [NSMutableDictionary dictionary];
            [conversations setObject:conversation forKey:identifier];
        }
        [conversation setObject:directMessage forKey:directMessage.identifier];
    }
    for (DirectMessage * directMessage in [sentDirectMessages allValues]) {
        NSString * identifier = directMessage.recipient.identifier;
        NSMutableDictionary * conversation =
            [conversations objectForKey:identifier];
        if (!conversation) {
            conversation = [NSMutableDictionary dictionary];
            [conversations setObject:conversation forKey:identifier];
        }
        [conversation setObject:directMessage forKey:directMessage.identifier];
    }
    
    // perform sanity check
    NSDictionary * allNewMessageCountsByUser =
        [newDirectMessagesState allNewMessagesByUser];
    for (id userId in [allNewMessageCountsByUser allKeys])
        if (![conversations objectForKey:userId])
            [newDirectMessagesState setCount:0 forUserId:userId];

    for (NSString * userId in [conversations allKeys]) {
        NSDictionary * conversation = [conversations objectForKey:userId];
        NSArray * sortedMessageIds =
            [conversation keysSortedByValueUsingSelector:@selector(compare:)];
        NSMutableArray * sortedConversation = [NSMutableArray array];
        for (NSString * messageId in sortedMessageIds) {
            DirectMessage * message = [conversation objectForKey:messageId];
            [sortedConversation addObject:message];
        }
        [sortedConversations setObject:sortedConversation forKey:userId];
    }
}

- (NSArray *)constructConversationPreviewsFromMessages
{
    NSMutableArray * conversationPreviews = [NSMutableArray array];

    for (DirectMessage * message in self.newDirectMessages)
        [newDirectMessagesState
            incrementCountForUserId:message.sender.identifier];

    self.newDirectMessages = nil;

    for (NSArray * conversation in [sortedConversations allValues]) {
        DirectMessage * mostRecentMessage = [conversation objectAtIndex:0];
        User * otherUser =
            [mostRecentMessage.sender.username isEqual:activeAcctUsername] ?
            mostRecentMessage.recipient : mostRecentMessage.sender;
        NSUInteger numMessages =
            [newDirectMessagesState countForUserId:otherUser.identifier];
            
        NSString * displayName =
            otherUser.name && ![[self class] displayWithUsername] ?
            otherUser.name : otherUser.username;
        ConversationPreview * preview =
            [[[ConversationPreview alloc]
            initWithOtherUserId:otherUser.identifier
            otherUserName:displayName
            mostRecentMessage:mostRecentMessage.text
            mostRecentMessageDate:mostRecentMessage.created
            numNewMessages:numMessages]
            autorelease];
        [conversationPreviews addObject:preview];
    }

    return [conversationPreviews sortedArrayUsingSelector:@selector(compare:)];
}

- (void)composeNewDirectMessage
{
    NSLog(@"Messages display manager: composing new direct message...");
    [self.composeMessageDisplayMgr composeDirectMessage];
}

- (void)sendDirectMessageToOtherUserInConversation
{
    NSLog(@"Messages display manager: sending direct message to %@",
        self.otherUserInConversation.username);
    [self.composeMessageDisplayMgr
        composeDirectMessageTo:self.otherUserInConversation.username];
}

- (void)deallocateTweetDetailsNode
{
    self.tweetDetailsCredentialsPublisher = nil;
    self.tweetDetailsTimelineDisplayMgr = nil;
    self.tweetDetailsNetAwareViewController = nil;
    self.currentSearch = nil;
}

- (void)updateBadge
{
    self.tabBarItem.badgeValue =
        newDirectMessagesState.numNewMessages > 0 ?
        [NSString stringWithFormat:@"%d",
        newDirectMessagesState.numNewMessages] :
        nil;
}

- (void)removeSearch:(id)sender
{
    [self.tweetDetailsTimelineDisplayMgr
        setTimelineHeaderView:[self saveSearchView]];
    [self.savedSearchMgr removeSavedSearchForQuery:self.currentSearch];
}

- (void)saveSearch:(id)sender
{
    [self.tweetDetailsTimelineDisplayMgr
        setTimelineHeaderView:[self removeSearchView]];
    [self.savedSearchMgr addSavedSearch:self.currentSearch];
}

- (UIView *)saveSearchView
{
    NSString * title = NSLocalizedString(@"savedsearch.save.title", @"");
    SEL action = @selector(saveSearch:);

    return [self toggleSaveSearchViewWithTitle:title action:action];
}

- (UIView *)removeSearchView
{
    NSString * title = NSLocalizedString(@"savedsearch.remove.title", @"");
    SEL action = @selector(removeSearch:);

    return [self toggleSaveSearchViewWithTitle:title action:action];
}

- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title
    action:(SEL)action
{
    CGRect viewFrame = CGRectMake(0, 0, 320, 51);
    UIView * view = [[UIView alloc] initWithFrame:viewFrame];

    CGRect buttonFrame = CGRectMake(20, 7, 280, 37);
    UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = buttonFrame;

    UIImage * background =
        [UIImage imageNamed:@"SaveSearchButtonBackground.png"];
    UIImage * selectedBackground =
        [UIImage imageNamed:@"SaveSearchButtonBackgroundHighlighted.png"];
    [button setBackgroundImage:background forState:UIControlStateNormal];
    [button setBackgroundImage:selectedBackground
                      forState:UIControlStateHighlighted];

    [button setTitle:title forState:UIControlStateNormal];

    UIColor * color = [UIColor colorWithRed:.353 green:.4 blue:.494 alpha:1.0];
    [button setTitleColor:color forState:UIControlStateNormal];

    button.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;

    UIControlEvents events = UIControlEventTouchUpInside;
    [button addTarget:self action:action forControlEvents:events];

    [view addSubview:button];

    return [view autorelease];
}

- (void)presentDirectMessageActions
{
    NSString * cancel =
        NSLocalizedString(@"directmessage.actions.cancel", @"");
    NSString * email =
        NSLocalizedString(@"directmessage.actions.email", @"");

    UIActionSheet * sheet =
        [[UIActionSheet alloc]
        initWithTitle:nil delegate:self
        cancelButtonTitle:cancel destructiveButtonTitle:nil
        otherButtonTitles:email, nil];

    // The alert sheet needs to be displayed in the UITabBarController's view.
    // If it's displayed in a child view, the action sheet will appear to be
    // modal on top of the tab bar, but it will not intercept any touches that
    // occur within the tab bar's bounds. Thus about 3/4 of the 'Cancel' button
    // becomes unusable. Reaching for the UITabBarController in this way is
    // definitely a hack, but fixes the problem for now.
    UIView * rootView =
        wrapperController.parentViewController.parentViewController.view;
    [sheet showInView:rootView];
}

- (void)displayComposerMailSheet
{
    MFMailComposeViewController * picker =
        [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;

    static NSString * subjectRegex = @"\\S+\\s\\S+\\s\\S+\\s\\S+\\s\\S+";
    NSString * subject =
        [self.selectedMessage.text stringByMatching:subjectRegex];
    if (subject && ![subject isEqual:@""])
        subject = [NSString stringWithFormat:@"%@...", subject];
    else
        subject = self.selectedMessage.text;
    [picker setSubject:subject];

    NSString * body =
        [NSString stringWithFormat:@"%@", self.selectedMessage.text];
    [picker setMessageBody:body isHTML:NO];

    [self.tweetViewController presentModalViewController:picker animated:YES];

    [picker release];
}

- (SavedSearchMgr *)savedSearchMgr
{
    if (!savedSearchMgr)
        savedSearchMgr =
            [[SavedSearchMgr alloc]
            initWithAccountName:credentials.username
            context:managedObjectContext];

    return savedSearchMgr;
}

- (UserInfoViewController *)userInfoController
{
    if (!userInfoController) {
        userInfoController =
            [[UserInfoViewController alloc]
            initWithNibName:@"UserInfoView" bundle:nil];

        userInfoController.findPeopleBookmarkMgr = findPeopleBookmarkMgr;
        userInfoController.delegate = self;
    }

    return userInfoController;
}

- (NetworkAwareViewController *)userInfoControllerWrapper
{
    if (!userInfoControllerWrapper) {
        userInfoControllerWrapper =
            [[NetworkAwareViewController alloc]
            initWithTargetViewController:self.userInfoController];
    }

    return userInfoControllerWrapper;
}

- (UserInfoRequestAdapter *)userInfoRequestAdapter
{
    if (!userInfoRequestAdapter) {
        userInfoRequestAdapter =
            [[UserInfoRequestAdapter alloc]
            initWithTarget:self.userInfoController action:@selector(setUser:)
            wrapperController:self.userInfoControllerWrapper errorHandler:self];
    }

    return userInfoRequestAdapter;
}

- (TwitterService *)userInfoTwitterService
{
    if (!userInfoTwitterService) {
        userInfoTwitterService =
            [[TwitterService alloc] initWithTwitterCredentials:credentials
            context:managedObjectContext];
        userInfoTwitterService.delegate = self.userInfoRequestAdapter;
    }
    
    return userInfoTwitterService;
}

- (void)sendDirectMessageToCurrentUser
{
    NSLog(@"Direct message display manager: sending direct message to %@",
        otherUserInConversation.username);
    [composeTweetDisplayMgr
        composeDirectMessageTo:otherUserInConversation.username];
}

+ (BOOL)displayWithUsername
{
    if (!alreadyReadDisplayWithUsernameValue) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        NSInteger displayNameValAsNumber =
            [defaults integerForKey:@"display_name"];
        displayWithUsername = displayNameValAsNumber;
    }

    alreadyReadDisplayWithUsernameValue = YES;

    return displayWithUsername;
}

- (LocationMapViewController *)locationMapViewController
{
    if (!locationMapViewController) {
        locationMapViewController =
            [[LocationMapViewController alloc]
            initWithNibName:@"LocationMapView" bundle:nil];
        locationMapViewController.delegate = self;

        UIBarButtonItem * currentLocationButton =
            [[[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"Location.png"]
            style:UIBarButtonItemStyleBordered target:locationMapViewController
            action:@selector(setCurrentLocation:)] autorelease];
        self.locationMapViewController.navigationItem.rightBarButtonItem =
            currentLocationButton;
    }

    return locationMapViewController;
}

- (LocationInfoViewController *)locationInfoViewController
{
    if (!locationInfoViewController) {
        locationInfoViewController =
            [[LocationInfoViewController alloc]
            initWithNibName:@"LocationInfoView" bundle:nil];
        locationInfoViewController.navigationItem.title =
            NSLocalizedString(@"locationinfo.title", @"");
        locationInfoViewController.delegate = self;

        UIBarButtonItem * forwardButton =
            [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAction
            target:locationInfoViewController
            action:@selector(showForwardOptions)] autorelease];
        self.locationInfoViewController.navigationItem.rightBarButtonItem =
            forwardButton;
    }

    return locationInfoViewController;
}

@end
