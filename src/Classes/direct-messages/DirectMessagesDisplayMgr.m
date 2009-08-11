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
- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error;
- (void)updateBadge;
- (void)presentFailedDirectMessageOnTimer:(NSTimer *)timer;

- (void)removeSearch:(NSString *)search;
- (void)saveSearch:(NSString *)search;

- (UIView *)saveSearchView;
- (UIView *)removeSearchView;
- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title
    action:(SEL)action;

+ (BOOL)displayWithUsername;

@property (nonatomic, retain) SavedSearchMgr * savedSearchMgr;
@property (nonatomic, retain) NSString * currentSearch;

@end

@implementation DirectMessagesDisplayMgr

static BOOL displayWithUsername;
static BOOL alreadyReadDisplayWithUsernameValue;

@synthesize activeAcctUsername, otherUserInConversation, selectedMessage,
    tweetDetailsTimelineDisplayMgr, tweetDetailsNetAwareViewController,
    tweetDetailsCredentialsPublisher, userListNetAwareViewController,
    userListController, directMessageCache, newDirectMessages,
    newDirectMessagesState, currentConversationUserId, currentSearch,
    savedSearchMgr;

- (void)dealloc
{
    [wrapperController release];
    [inboxController release];
    [tweetViewController release];
    [browserController release];
    [photoBrowser release];
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
    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    inboxController:(DirectMessageInboxViewController *)anInboxController
    service:(TwitterService *)aService
    initialCache:(DirectMessageCache *)initialCache
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )aManagedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        inboxController = [anInboxController retain];
        service = [aService retain];
        timelineDisplayMgrFactory = [factory retain];
        managedObjectContext = [aManagedObjectContext retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];

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
        refreshButton.action =
            @selector(updateDirectMessagesSinceLastUpdateIds);

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
}

- (void)failedToFetchDirectMessagesSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
{
    NSLog(@"Message Display Manager: failed to fetch timeline since %@",
        updateId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchmessages", @"");
    [self displayErrorWithTitle:errorMessage error:error];

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
}

- (void)failedToFetchSentDirectMessagesSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
{
    NSLog(@"Message Display Manager: failed to fetch timeline since %@",
        updateId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchmessages", @"");
    [self displayErrorWithTitle:errorMessage error:error];

    outstandingSentRequests--;
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
    NSLog(@"Message display manager: selected message: %@", message);
    self.selectedMessage = message;

    BOOL tweetByUser = [message.sender.username isEqual:activeAcctUsername];
    self.tweetViewController.navigationItem.rightBarButtonItem.enabled =
        !tweetByUser;
    [self.tweetViewController setUsersTweet:tweetByUser];

    UIBarButtonItem * rightBarButtonItem =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self
        action:@selector(sendDirectMessageToOtherUserInConversation)];
    self.tweetViewController.navigationItem.rightBarButtonItem =
        rightBarButtonItem;
    self.tweetViewController.navigationItem.title =
        NSLocalizedString(@"tweetdetailsview.title.directmessage", @"");
    [self.tweetViewController setUsersTweet:YES];
    [self.tweetViewController hideFavoriteButton:YES];

    TweetInfo * tweetInfo = [TweetInfo createFromDirectMessage:message];
    [self.tweetViewController displayTweet:tweetInfo avatar:avatarImage
        onNavigationController:wrapperController.navigationController];
}

#pragma mark TweetDetailsViewDelegate implementation

- (void)showUserInfoWithAvatar:(UIImage *)avatar
{
    [self showUserInfoForUser:otherUserInConversation withAvatar:avatar];
}

- (void)showUserInfoForUser:(User *)aUser withAvatar:(UIImage *)avatar
{
//    NSLog(@"Timeline display manager: showing user info for %@", aUser);
//    userInfoController.navigationItem.title = aUser.name;
//    [self.wrapperController.navigationController
//        pushViewController:self.userInfoController animated:YES];
//    self.userInfoController.followingEnabled =
//        ![credentials.username isEqual:aUser.username];
//    [self.userInfoController setUser:aUser avatarImage:avatar];
//    if (self.userInfoController.followingEnabled)
//        [service isUser:credentials.username following:aUser.username];
//    // HACK: this is called twice to make sure it gets displayed the first time
//    userInfoController.navigationItem.title = aUser.name;
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
    NSLog(@"Timeline display manager: showing %@ on map", locationString);
    NSString * locationWithoutCommas =
        [locationString stringByReplacingOccurrencesOfString:@"iPhone:"
        withString:@""];
    NSString * urlString =
        [[NSString
        stringWithFormat:@"http://maps.google.com/maps?q=%@",
        locationWithoutCommas]
        stringByAddingPercentEscapesUsingEncoding:
        NSUTF8StringEncoding];
    NSURL * url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)visitWebpage:(NSString *)webpageUrl
{
    NSLog(@"Messages Display Manager: visiting webpage: %@", webpageUrl);
    [wrapperController presentModalViewController:self.browserController
        animated:YES];
    [self.browserController setUrl:webpageUrl];
}

- (void)showPhotoInBrowser:(RemotePhoto *)remotePhoto
{
    NSLog(@"Messages Display Manager: showing photo: %@", remotePhoto);

    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackTranslucent
        animated:YES];

    [wrapperController presentModalViewController:self.photoBrowser
        animated:YES];
    [self.photoBrowser addRemotePhoto:remotePhoto];
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
}

- (void)showingTweetDetails
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
    // not supported for direct messages
}

- (void)sendDirectMessageToUser:(NSString *)username
{
    // not supported for direct messages    
}

- (void)setFavorite:(BOOL)favorite
{
    // not supported for direct messages
}

#pragma mark TwitchBrowserViewControllerDelegate implementation

- (void)composeTweetWithText:(NSString *)text
{
    NSLog(@"Messages display manager: composing new tweet with text '%@'...",
        text);
    [composeTweetDisplayMgr composeTweetWithText:text];
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

- (TwitchBrowserViewController *)browserController
{
    if (!browserController) {
        browserController =
            [[TwitchBrowserViewController alloc]
            initWithNibName:@"TwitchBrowserView" bundle:nil];
        browserController.delegate = self;
    }

    return browserController;
}

- (PhotoBrowser *)photoBrowser
{
    if (!photoBrowser) {
        photoBrowser =
            [[PhotoBrowser alloc]
            initWithNibName:@"PhotoBrowserView" bundle:nil];
        photoBrowser.delegate = self;
    }

    return photoBrowser;
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

        NSString * twitPicUrl =
            [[InfoPlistConfigReader reader] valueForKey:@"TwitPicPostUrl"];
        TwitPicImageSender * imageSender =
            [[TwitPicImageSender alloc] initWithUrl:twitPicUrl];

        composeMessageDisplayMgr =
            [[ComposeTweetDisplayMgr alloc]
            initWithRootViewController:wrapperController.tabBarController
                        twitterService:twitterService
                           imageSender:imageSender
                               context:managedObjectContext];
        [imageSender release];

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

- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error
{
    NSLog(@"Message Display Manager: displaying error: %@", error);
    if (!failedState) {
        NSString * message = error.localizedDescription;
        UIAlertView * alertView =
            [UIAlertView simpleAlertViewWithTitle:title message:message];
        [alertView show];

        failedState = YES;
    }
    [wrapperController setUpdatingState:kDisconnected];
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

- (SavedSearchMgr *)savedSearchMgr
{
    if (!savedSearchMgr)
        savedSearchMgr =
            [[SavedSearchMgr alloc]
            initWithAccountName:credentials.username
            context:managedObjectContext];

    return savedSearchMgr;
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

@end
