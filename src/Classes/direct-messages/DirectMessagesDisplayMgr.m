//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessagesDisplayMgr.h"
#import "ConversationPreview.h"
#import "DirectMessage.h"
#import "TweetInfo.h"
#import "ArbUserTimelineDataSource.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface DirectMessage (Sorting)

- (NSComparisonResult)compare:(DirectMessage *)directMessage;

@end

@implementation DirectMessage (Sorting)

- (NSComparisonResult)compare:(DirectMessage *)directMessage
{
    NSNumber * myId =
        [NSNumber numberWithLongLong:[self.identifier longLongValue]];
    NSNumber * theirId =
        [NSNumber numberWithLongLong:[directMessage.identifier longLongValue]];

    return [theirId compare:myId];
}

@end

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

@end

@implementation DirectMessagesDisplayMgr

@synthesize activeAcctUsername, otherUserInConversation, selectedMessage,
    tweetDetailsTimelineDisplayMgr, tweetDetailsNetAwareViewController,
    tweetDetailsCredentialsPublisher, userListNetAwareViewController,
    userListController, directMessageCache;

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
    [credentials release];
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
}

- (void)sentDirectMessages:(NSArray *)directMessages
    fetchedSinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
    count:(NSNumber *)count
{
    NSLog(@"Messages Display Manager: Received sent direct messages (%d)...",
        [directMessages count]);
    [directMessageCache addSentDirectMessages:directMessages];

    outstandingSentRequests--;
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
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    NSLog(@"Message Display Manager: view will appear");
    if (!alreadyBeenDisplayedAfterCredentialChange)
        [self viewAppearedForFirstTimeAfterCredentialChange];
}

#pragma mark DirectMessageInboxViewControllerDelegate implementation

- (void)selectedConversationForUserId:(NSString *)userId
{
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

#pragma mark Public DirectMessagesDisplayMgr implementation

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Message display manager: setting credentials to '%@'", credentials);
    
    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:credentials];

    self.activeAcctUsername = credentials.username;

    // clear any state, if something outside of this class sets it, fine
    [directMessageCache clear];
    [conversations removeAllObjects];
    [sortedConversations removeAllObjects];
    alreadyBeenDisplayedAfterCredentialChange = NO;

    self.conversationController.segregatedSenderUsername = credentials.username;
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
    [self fetchDirectMessagesSinceId:receivedUpdateId page:nil numMessages:nil];
    [self fetchSentDirectMessagesSinceId:sentUpdateId page:nil numMessages:nil];

    [self setUpdatingState];
}

- (void)updateWithABunchOfRecentMessages
{
    NSLog(@"Messages Display Manager: Updating with a bunch of messages...");
    [self fetchDirectMessagesSinceId:nil page:[NSNumber numberWithInt:1]
        numMessages:nil];
    [self fetchSentDirectMessagesSinceId:nil
        page:[NSNumber numberWithInt:1] numMessages:nil];

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

#pragma mark Private DirectMessagesDisplayMgr implementation

- (void)fetchDirectMessagesSinceId:(NSNumber *)updateId page:(NSNumber *)page
    numMessages:(NSNumber *)numMessages
{
    outstandingReceivedRequests++;

    NSNumber * count = [NSNumber numberWithInteger:200];
    [service fetchDirectMessagesSinceId:updateId page:page count:count];
}

- (void)fetchSentDirectMessagesSinceId:(NSNumber *)updateId
    page:(NSNumber *)page numMessages:(NSNumber *)numMessages
{
    outstandingSentRequests++;

    NSNumber * count = [NSNumber numberWithInteger:200];
    [service fetchSentDirectMessagesSinceId:updateId page:page count:count];
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
        [wrapperController setCachedDataAvailable:YES];
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
    for (NSArray * conversation in [sortedConversations allValues]) {
        DirectMessage * mostRecentMessage = [conversation objectAtIndex:0];
        User * otherUser =
            [mostRecentMessage.sender.username isEqual:activeAcctUsername] ?
            mostRecentMessage.recipient : mostRecentMessage.sender;
        ConversationPreview * preview =
            [[[ConversationPreview alloc]
            initWithOtherUserId:otherUser.identifier
            otherUserName:otherUser.name
            mostRecentMessage:mostRecentMessage.text
            mostRecentMessageDate:mostRecentMessage.created
            newMessages:NO]
            autorelease];
        [conversationPreviews addObject:preview];
    }

    return [conversationPreviews sortedArrayUsingSelector:@selector(compare:)];
}

- (void)composeNewDirectMessage
{
    NSLog(@"Messages display manager: composing new direct message...");
    [composeTweetDisplayMgr composeDirectMessage];
}

- (void)sendDirectMessageToOtherUserInConversation
{
    NSLog(@"Messages display manager: sending direct message to %@",
        self.otherUserInConversation.username);
    [composeTweetDisplayMgr
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

@end
