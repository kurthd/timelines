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

@end

@implementation DirectMessagesDisplayMgr

@synthesize activeAcctUsername, otherUserInConversation, selectedMessage,
    tweetDetailsTimelineDisplayMgr, tweetDetailsNetAwareViewController,
    tweetDetailsCredentialsPublisher, userListNetAwareViewController,
    userListController, directMessageCache, newDirectMessages,
    newDirectMessagesState;

- (void)dealloc
{
    [wrapperController release];
    [inboxController release];
    [tweetDetailsController release];
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
    NSString * userId = preview.otherUserId;
    NSLog(@"Messages Display Manager: Selected conversation for user '%@'",
        userId);

    NSArray * messages = [sortedConversations objectForKey:userId];
    DirectMessage * firstMessage = [messages objectAtIndex:0];

    self.otherUserInConversation =
        [firstMessage.sender.username isEqual:activeAcctUsername] ?
        firstMessage.recipient : firstMessage.sender;

    NSString * name = self.otherUserInConversation.name;

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
    self.tweetDetailsController.navigationItem.rightBarButtonItem.enabled =
        !tweetByUser;
    [self.tweetDetailsController setUsersTweet:tweetByUser];

    UIBarButtonItem * rightBarButtonItem =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self
        action:@selector(sendDirectMessageToOtherUserInConversation)];
    self.tweetDetailsController.navigationItem.rightBarButtonItem =
        rightBarButtonItem;
    self.tweetDetailsController.navigationItem.title =
        NSLocalizedString(@"tweetdetailsview.title.directmessage", @"");
    [self.tweetDetailsController setUsersTweet:YES];
    [self.tweetDetailsController hideFavoriteButton:YES];
        
    [wrapperController.navigationController
        pushViewController:self.tweetDetailsController animated:YES];

    TweetInfo * tweetInfo = [TweetInfo createFromDirectMessage:message];
    [self.tweetDetailsController setTweet:tweetInfo avatar:avatarImage];
}

#pragma mark TweetDetailsViewDelegate implementation

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
        title:title managedObjectContext:managedObjectContext
        composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.tweetDetailsTimelineDisplayMgr.displayAsConversation = NO;
    self.tweetDetailsTimelineDisplayMgr.setUserToFirstTweeter = YES;
    self.tweetDetailsTimelineDisplayMgr.currentUsername = username;
    [self.tweetDetailsTimelineDisplayMgr setCredentials:credentials];

    UIBarButtonItem * sendDMButton =
        [[UIBarButtonItem alloc]
        initWithImage:[UIImage imageNamed:@"Envelope.png"]
        style:UIBarButtonItemStyleBordered
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
    [conversationController.navigationItem
        setRightBarButtonItem:[self sendingTweetProgressView] animated:YES];
}

- (void)userDidSendDirectMessage:(DirectMessage *)dm
{
    [conversationController.navigationItem
        setRightBarButtonItem:[self newMessageButtonItem] animated:YES];
    [conversationController addTweet:dm];
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
    NSLog(@"Message display manager: setting credentials to '%@'", credentials);

    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:credentials];

    self.activeAcctUsername = credentials.username;

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

- (TweetDetailsViewController *)tweetDetailsController
{
    if (!tweetDetailsController) {
        tweetDetailsController =
            [[TweetDetailsViewController alloc]
            initWithNibName:@"TweetDetailsView" bundle:nil];

        UIBarButtonItem * replyButton =
            [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self
            action:@selector(presentTweetActions)]
            autorelease];
        [tweetDetailsController.navigationItem
            setRightBarButtonItem:replyButton];

        NSString * title = NSLocalizedString(@"tweetdetailsview.title", @"");
        tweetDetailsController.navigationItem.title = title;
        tweetDetailsController.delegate = self;
    }

    return tweetDetailsController;
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
        initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                             target:self
                             action:@selector(composeTweet:)];

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
        ConversationPreview * preview =
            [[[ConversationPreview alloc]
            initWithOtherUserId:otherUser.identifier
            otherUserName:otherUser.name
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

@end
