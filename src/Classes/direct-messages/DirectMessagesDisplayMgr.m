
//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#include <AudioToolbox/AudioToolbox.h>
#import "DirectMessagesDisplayMgr.h"
#import "ConversationPreview.h"
#import "DirectMessage.h"
#import "TweetInfo.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "InfoPlistConfigReader.h"
#import "RegexKitLite.h"
#import "ErrorState.h"
#import "NSArray+IterationAdditions.h"

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

- (void)displayComposerMailSheet;

- (void)sendDirectMessageToCurrentUser;

- (void)showNextTweet;
- (void)showPreviousTweet;
- (void)updateTweetIndexCache;

+ (BOOL)displayWithUsername;

@property (nonatomic, retain) UIBarButtonItem * inboxViewComposeTweetButton;
@property (nonatomic, readonly) NSMutableDictionary * tweetIdToIndexDict;

@end

@implementation DirectMessagesDisplayMgr

static BOOL displayWithUsername;
static BOOL alreadyReadDisplayWithUsernameValue;

@synthesize activeAcctUsername, otherUserInConversation, selectedMessage,
    tweetDetailsTimelineDisplayMgr, tweetDetailsNetAwareViewController,
    tweetDetailsCredentialsPublisher, tweetIdToIndexDict,
    directMessageCache, newDirectMessages, inboxViewComposeTweetButton,
    newDirectMessagesState, currentConversationUserId;

- (void)dealloc
{
    [wrapperController release];
    [inboxController release];
    [directMessageViewController release];
    [service release];
    [directMessageCache release];
    [conversations release];
    [sortedConversations release];
    [composeTweetDisplayMgr release];

    [displayMgrHelper release];

    [activeAcctUsername release];
    [otherUserInConversation release];
    [selectedMessage release];

    [managedObjectContext release];
    [credentials release];
    [newDirectMessages release];
    [newDirectMessagesState release];
    [sendingTweetProgressView release];
    [findPeopleBookmarkMgr release];
    [inboxViewComposeTweetButton release];

    [tweetIdToIndexDict release];

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
        managedObjectContext = [aManagedObjectContext retain];
        findPeopleBookmarkMgr = [aFindPeopleBookmarkMgr retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];

        TwitterService * displayHelperService =
            [[[TwitterService alloc]
            initWithTwitterCredentials:service.credentials
            context:aManagedObjectContext]
            autorelease];

        displayMgrHelper =
            [[DisplayMgrHelper alloc]
            initWithWrapperController:aWrapperController
            navigationController:aWrapperController.navigationController
            userListDisplayMgrFactor:userListDispMgrFctry
            composeTweetDisplayMgr:composeTweetDisplayMgr
            twitterService:displayHelperService
            timelineFactory:factory
            managedObjectContext:managedObjectContext
            findPeopleBookmarkMgr:aFindPeopleBookmarkMgr];
        displayHelperService.delegate = displayMgrHelper;

        if (initialCache) {
            directMessageCache = [initialCache retain];
            [wrapperController setCachedDataAvailable:YES];
        } else {
            directMessageCache = [[DirectMessageCache alloc] init];
            [wrapperController setCachedDataAvailable:NO];
        }

        conversations = [[NSMutableDictionary dictionary] retain];
        sortedConversations = [[NSMutableDictionary dictionary] retain];

        self.inboxViewComposeTweetButton =
            wrapperController.navigationItem.rightBarButtonItem;
        self.inboxViewComposeTweetButton.target = self;
        self.inboxViewComposeTweetButton.action =
            @selector(composeNewDirectMessage);

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
            [[directMessages sortedArrayUsingSelector:@selector(compare:)]
            arrayByReversingContents];
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
            [[directMessages sortedArrayUsingSelector:@selector(compare:)]
            arrayByReversingContents];
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

- (void)deletedDirectMessageWithId:(NSString *)directMessageId
{
    [directMessageCache removeDirectMessageWithId:directMessageId];
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

#pragma mark DirectMessageInboxViewControllerDelegate implementation

- (void)selectedConversationPreview:(ConversationPreview *)preview
{
    // HACK: forces to scroll to top
    [self.conversationController.tableView setContentOffset:CGPointMake(0, 392)
        animated:NO];

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

    [self updateTweetIndexCache];
}

#pragma mark DirectMessageConversationViewControllerDelegate implementation

- (void)selectedTweet:(DirectMessage *)message
    avatarImage:(UIImage *)avatarImage
{
    // HACK: forces to scroll to top
    [self.directMessageViewController.tableView
        setContentOffset:CGPointMake(0, 300) animated:NO];

    NSLog(@"Message display manager: selected message: %@", message);
    self.selectedMessage = message;

    BOOL tweetByUser = [message.sender.username isEqual:activeAcctUsername];
    [self.directMessageViewController setUsersTweet:tweetByUser];

    TweetInfo * tweetInfo = [TweetInfo createFromDirectMessage:message];
    [self.directMessageViewController displayTweet:tweetInfo
        onNavigationController:wrapperController.navigationController];

    UISegmentedControl * segmentedControl =
        (UISegmentedControl *)
        self.directMessageViewController.navigationItem.rightBarButtonItem.
        customView;
    NSInteger tweetIndex =
        [[self.tweetIdToIndexDict objectForKey:selectedMessage.identifier]
        intValue];
    NSString * titleFormatString =
        NSLocalizedString(@"tweetdetailsview.titleformat", @"");
    NSArray * messages =
        [sortedConversations objectForKey:self.currentConversationUserId];
    self.directMessageViewController.navigationItem.title =
        [NSString stringWithFormat:titleFormatString, tweetIndex + 1,
        [messages count]];
    [segmentedControl setEnabled:tweetIndex != 0 forSegmentAtIndex:0];
    [segmentedControl setEnabled:tweetIndex != [messages count] - 1
        forSegmentAtIndex:1];
}

#pragma mark TweetDetailsViewDelegate implementation

- (void)showUserInfo
{
    [self showUserInfoForUser:otherUserInConversation];
}

- (void)showUserInfoForUser:(User *)aUser
{
    [displayMgrHelper showUserInfoForUser:aUser];
}

- (void)showUserInfoForUsername:(NSString *)aUsername
{
    [displayMgrHelper showUserInfoForUsername:aUsername];
}

- (void)showingTweetDetails:(DirectMessageViewController *)tweetController
{
    NSLog(@"Messages Display Manager: showing tweet details...");
    [self deallocateTweetDetailsNode];
}

- (void)setFavorite:(BOOL)favorite
{
    // not supported for direct messages
}

- (void)loadConversationFromTweetId:(NSString *)tweetId
{
    // not supported for direct messages
}

- (void)deleteTweet:(NSString *)tweetId
{
    NSLog(@"Direct message display manager: deleting tweet");
    [self clearState];

    [conversationController performSelector:@selector(deleteTweet:)
        withObject:tweetId afterDelay:0.5];

    // Delete the direct message from Twitter after a longer delay than used
    // for the deleteTweet: method above. The DirectMessage object is deleted
    // when we receive confirmation from Twitter that they've deleted it. If
    // this happens before deleteTweet: executes, the method will crash because
    // the DirectMessage object is expected to be alive.
    [service performSelector:@selector(deleteDirectMessage:)
        withObject:tweetId afterDelay:1.0];
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
        someCredentials.username);

    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:credentials];

    self.activeAcctUsername = credentials.username;
    [displayMgrHelper setCredentials:someCredentials];

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

- (void)updateDirectMessagesAfterCredentialChange
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

- (DirectMessageViewController *)directMessageViewController
{
    if (!directMessageViewController) {
        directMessageViewController =
            [[DirectMessageViewController alloc]
            initWithNibName:@"DirectMessageView" bundle:nil];

        NSArray * segmentedControlItems =
            [NSArray arrayWithObjects:[UIImage imageNamed:@"UpButton.png"],
            [UIImage imageNamed:@"DownButton.png"], nil];
        UISegmentedControl * segmentedControl =
            [[[UISegmentedControl alloc] initWithItems:segmentedControlItems]
            autorelease];
        segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        CGRect segmentedControlFrame = segmentedControl.frame;
        segmentedControlFrame.size.width = 88;
        segmentedControl.frame = segmentedControlFrame;
        [segmentedControl addTarget:self action:@selector(handleUpDownButton:)
            forControlEvents:UIControlEventValueChanged];
        UIBarButtonItem * rightBarButtonItem =
            [[[UIBarButtonItem alloc] initWithCustomView:segmentedControl]
            autorelease];
        directMessageViewController.navigationItem.rightBarButtonItem =
            rightBarButtonItem;
        
        NSString * title =
            NSLocalizedString(@"tweetdetailsview.title.directmessage", @"");
        directMessageViewController.navigationItem.backBarButtonItem =
            [[[UIBarButtonItem alloc]
            initWithTitle:title style:UIBarButtonItemStyleBordered target:nil
            action:nil]
            autorelease];

        directMessageViewController.delegate = self;
    }

    return directMessageViewController;
}

- (void)handleUpDownButton:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0)
        [self showPreviousTweet];
    else if (sender.selectedSegmentIndex == 1)
        [self showNextTweet];

    sender.selectedSegmentIndex = -1;
}

- (void)showNextTweet
{
    NSLog(@"Direct message display manager: showing next tweet");
    NSArray * messages =
        [sortedConversations objectForKey:self.currentConversationUserId];

    NSNumber * tweetIndex =
        [self.tweetIdToIndexDict objectForKey:selectedMessage.identifier];
    NSLog(@"selectedMessage.identifier: %@", selectedMessage.identifier);
    NSLog(@"Selected tweet index: %@", tweetIndex);

    NSInteger nextIndex = [tweetIndex intValue] + 1;
    NSLog(@"Next tweet index: %d", nextIndex);

    DirectMessage * nextTweet = [messages objectAtIndex:nextIndex];

    [conversationController selectTweetId:nextTweet.identifier];
    [self selectedTweet:nextTweet avatarImage:nil];
}

- (void)showPreviousTweet
{
    NSLog(@"Direct message display manager: showing previous tweet");
    NSArray * messages =
        [sortedConversations objectForKey:self.currentConversationUserId];

    NSNumber * tweetIndex =
        [self.tweetIdToIndexDict objectForKey:selectedMessage.identifier];
    NSLog(@"Selected tweet index: %@", tweetIndex);

    NSInteger previousIndex = [tweetIndex intValue] - 1;
    NSLog(@"Previous tweet index: %d", previousIndex);
        
    DirectMessage * previousTweet = [messages objectAtIndex:previousIndex];

    [conversationController selectTweetId:previousTweet.identifier];
    [self selectedTweet:previousTweet avatarImage:nil];
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

#pragma mark DirectMessageViewControllerDelegate implementation

- (void)sendDirectMessageToUser:(NSString *)aUsername
{
    [displayMgrHelper sendDirectMessageToUser:aUsername];
}

- (void)showResultsForSearch:(NSString *)searchString
{
    [displayMgrHelper showResultsForSearch:searchString];
}

#pragma mark Private DirectMessagesDisplayMgr implementation

- (void)fetchDirectMessagesSinceId:(NSNumber *)updateId page:(NSNumber *)page
    numMessages:(NSNumber *)numMessages
{
    if (outstandingReceivedRequests == 0) { // only one at a time
        outstandingReceivedRequests++;
        NSLog(@"Fetching received messages with id: %@, page: %@, qty: %@",
            updateId, page, numMessages);
        [service fetchDirectMessagesSinceId:updateId page:page
            count:numMessages];
    }
}

- (void)fetchSentDirectMessagesSinceId:(NSNumber *)updateId
    page:(NSNumber *)page numMessages:(NSNumber *)numMessages
{
    if (outstandingSentRequests == 0) { // only one at a time
        outstandingSentRequests++;
        NSLog(@"Fetching sent messages with id: %@, page: %@, qty: %@",
            updateId, page, numMessages);
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
        NSArray * convoPreviews =
            [self constructConversationPreviewsFromMessages];
        [inboxController setConversationPreviews:convoPreviews];
            
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

        // if currently viewing a conversation, update convo view
        if (self.currentConversationUserId) {
            NSArray * messages =
                [sortedConversations
                objectForKey:self.currentConversationUserId];
            [self.conversationController setMessages:messages];
        }
    }
}

- (void)constructConversationsFromMessages
{
    [conversations removeAllObjects];
    [sortedConversations removeAllObjects];

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
            [[conversation keysSortedByValueUsingSelector:@selector(compare:)]
            arrayByReversingContents];
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

- (void)updateBadge
{
    self.tabBarItem.badgeValue =
        newDirectMessagesState.numNewMessages > 0 ?
        [NSString stringWithFormat:@"%d",
        newDirectMessagesState.numNewMessages] :
        nil;
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
        [NSString stringWithFormat:@"\"%@\"\n- %@",
        self.selectedMessage.text, self.selectedMessage.sender.username];
    [picker setMessageBody:body isHTML:NO];

    [self.directMessageViewController presentModalViewController:picker
        animated:YES];

    [picker release];
}

- (void)sendDirectMessageToCurrentUser
{
    NSLog(@"Direct message display manager: sending direct message to %@",
        otherUserInConversation.username);
    [composeTweetDisplayMgr
        composeDirectMessageTo:otherUserInConversation.username];
}

- (void)updateDisplayForSendingDirectMessage
{
    [self.conversationController.navigationItem
        setRightBarButtonItem:[self sendingTweetProgressView] animated:YES];
    [wrapperController.navigationItem
        setRightBarButtonItem:[self sendingTweetProgressView] animated:YES];
}

- (void)updateDisplayForFailedDirectMessage:(NSString *)recipient
{
    [self.conversationController.navigationItem
        setRightBarButtonItem:[self newMessageButtonItem] animated:YES];
    [wrapperController.navigationItem
        setRightBarButtonItem:self.inboxViewComposeTweetButton animated:YES];
}

- (void)addDirectMessage:(DirectMessage *)dm
{
    NSLog(@"Direct message display manager: adding direct message");

    [self.conversationController.navigationItem
        setRightBarButtonItem:[self newMessageButtonItem] animated:YES];
    [wrapperController.navigationItem
        setRightBarButtonItem:self.inboxViewComposeTweetButton animated:YES];
    if ([dm.recipient.identifier isEqual:self.currentConversationUserId])
        [self.conversationController addTweet:dm];

    [directMessageCache addSentDirectMessage:dm];
    [self updateViewsWithNewMessages];
}

- (NSMutableDictionary *)tweetIdToIndexDict
{
    if (!tweetIdToIndexDict)
        tweetIdToIndexDict = [[NSMutableDictionary dictionary] retain];

    return tweetIdToIndexDict;
}

- (void)updateTweetIndexCache
{
    [self.tweetIdToIndexDict removeAllObjects];
    NSArray * messages =
        [sortedConversations objectForKey:self.currentConversationUserId];

    for (NSInteger i = 0; i < [messages count]; i++) {
        DirectMessage * tweetInfo = [messages objectAtIndex:i];
        [self.tweetIdToIndexDict setObject:[NSNumber numberWithInt:i]
            forKey:tweetInfo.identifier];
    }
}

#pragma mark static helper methods

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
