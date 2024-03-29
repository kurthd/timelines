//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#include <AudioToolbox/AudioToolbox.h>
#import "MentionTimelineDisplayMgr.h"
#import "ErrorState.h"
#import "NSArray+IterationAdditions.h"
#import "SettingsReader.h"
#import "TwitchAppDelegate.h"

@interface MentionTimelineDisplayMgr ()

- (void)setUpdatingState;
- (void)fetchMentionsSinceId:(NSNumber *)updateId page:(NSNumber *)page
    numMessages:(NSNumber *)numMessages;
- (void)updateTweetIndexCache;
- (void)updateViewWithNewMentions;

- (void)handleUpDownButton:(UISegmentedControl *)sender;
- (void)showNextTweet;
- (void)showPreviousTweet;

- (NetworkAwareViewController *)newTweetDetailsWrapperController;
- (TweetViewController *)newTweetDetailsController;

@property (nonatomic, readonly) TweetViewController * tweetDetailsController;
@property (nonatomic, readonly) NSMutableDictionary * tweetIdToIndexDict;
@property (nonatomic, readonly) NSMutableDictionary * tweetIndexToIdDict;

@property (nonatomic, copy) NSNumber * lastUpdateId;
@property (nonatomic, copy) NSMutableDictionary * mentions;
@property (nonatomic, copy) NSString * activeAcctUsername;
@property (nonatomic, retain) Tweet * selectedTweet;
@property (nonatomic, retain)
    NetworkAwareViewController * lastTweetDetailsWrapperController;
@property (nonatomic, retain) TweetViewController * lastTweetDetailsController;
@property (nonatomic, readonly) UIBarButtonItem * updatingTimelineActivityView;

@end

@implementation MentionTimelineDisplayMgr

@synthesize lastUpdateId, mentions, activeAcctUsername, mentionIdToShow,
    selectedTweet, lastTweetDetailsWrapperController,
    lastTweetDetailsController, navigationController, refreshButton;

- (void)dealloc
{
    [wrapperController release];
    [navigationController release];
    [timelineController release];
    [tweetDetailsController release];
    [service release];
    [tabBarItem release];
    [composeTweetDisplayMgr release];
    [managedObjectContext release];

    [displayMgrHelper release];

    [lastUpdateId release];
    [mentions release];
    [activeAcctUsername release];
    [selectedTweet release];
    [credentials release];

    [tweetIdToIndexDict release];
    [tweetIndexToIdDict release];
    
    [conversationDisplayMgrs release];

    [lastTweetDetailsWrapperController release];
    [lastTweetDetailsController release];

    [updatingTimelineActivityView release];
    [refreshButton release];

    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    navigationController:(UINavigationController *)aNavigationController
    timelineController:(TimelineViewController *)aTimelineController
    service:(TwitterService *)aService
    factory:(TimelineDisplayMgrFactory *)timelineFactory
    managedObjectContext:(NSManagedObjectContext* )aManagedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr
    userListDisplayMgrFactory:(UserListDisplayMgrFactory *)userListDispMgrFctry
    tabBarItem:(UITabBarItem *)aTabBarItem
    contactCache:(ContactCache *)aContactCache
    contactMgr:(ContactMgr *)aContactMgr
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        navigationController = [aNavigationController retain];
        timelineController = [aTimelineController retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        managedObjectContext = [aManagedObjectContext retain];
        service = [aService retain];
        tabBarItem = [aTabBarItem retain];
        pagesShown = 1;

        TwitterService * displayHelperService =
            [[[TwitterService alloc]
            initWithTwitterCredentials:service.credentials
            context:aManagedObjectContext]
            autorelease];

        displayMgrHelper =
            [[DisplayMgrHelper alloc]
            initWithWrapperController:aWrapperController
            navigationController:aNavigationController
            userListDisplayMgrFactor:userListDispMgrFctry
            composeTweetDisplayMgr:aComposeTweetDisplayMgr
            twitterService:displayHelperService
            timelineFactory:timelineFactory
            managedObjectContext:aManagedObjectContext
            findPeopleBookmarkMgr:findPeopleBookmarkMgr
            contactCache:aContactCache contactMgr:aContactMgr];
        displayHelperService.delegate = displayMgrHelper;

        conversationDisplayMgrs = [[NSMutableArray alloc] init];

        mentions = [[NSMutableDictionary dictionary] retain];
    }

    return self;
}

#pragma mark TwitterServiceDelegate implementation

- (void)mentions:(NSArray *)newMentions
    fetchedSinceUpdateId:(NSNumber *)updateId page:(NSNumber *)page
    count:(NSNumber *)count
{
    NSInteger oldTimelineCount = [[mentions allKeys] count];

    NSLog(@"Received mentions (%d)...", oldTimelineCount);
    NSLog(@"Mentions update id: %@", updateId);
    NSLog(@"Mentions page: %@", page);

    if ([newMentions count] > 0) {
        NSArray * sortedMentions =
            [[newMentions sortedArrayUsingSelector:@selector(compare:)]
            arrayByReversingContents];
        Tweet * mostRecentTweet = [sortedMentions objectAtIndex:0];
        long long updateIdAsLongLong =
            [mostRecentTweet.identifier longLongValue];
        self.lastUpdateId = [NSNumber numberWithLongLong:updateIdAsLongLong];
    }

    for (Tweet * mention in newMentions)
        [mentions setObject:mention forKey:mention.identifier];

    NSInteger newTimelineCount = [[mentions allKeys] count];

    outstandingRequests--;

    if (refreshingMessages) {
        if ([newMentions count] > 0) {
            pagesShown = [mentions count] / [SettingsReader fetchQuantity];
            pagesShown = pagesShown > 0 ? pagesShown : 1;
        }
    } else {
        NSInteger pageAsInt = [page intValue];
        BOOL allPagesLoaded =
            (oldTimelineCount == newTimelineCount && receivedQueryResponse) ||
            newTimelineCount == 0;
        if (allPagesLoaded) {
            NSLog(@"Mention display manager: setting all pages loaded");
            NSLog(@"Refreshing mentions?: %d", refreshingMessages);
            NSLog(@"Old mentions count: %d", oldTimelineCount);
            NSLog(@"New mentions count: %d", newTimelineCount);
        } else if (pageAsInt != 0)
            pagesShown = pageAsInt;

        [timelineController setAllPagesLoaded:allPagesLoaded];
    }

    receivedQueryResponse = YES;

    if ([SettingsReader scrollToTop])
        [timelineController setTweets:[mentions allValues] page:pagesShown
            visibleTweetId:updateId];
    else
        [timelineController setWithoutScrollingTweets:[mentions allValues]
            page:pagesShown];

    [self updateViewWithNewMentions];

    [[ErrorState instance] exitErrorState];
    [self updateTweetIndexCache];

    self.mentionIdToShow = nil;
}

- (void)failedToFetchMentionsSinceUpdateId:(NSNumber *)updateId
    page:(NSNumber *)page count:(NSNumber *)count error:(NSError *)error
{
    NSLog(@"Failed to fetch mentions since %@", updateId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchmentions", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error
        retryTarget:self retryAction:@selector(refreshWithLatest)];
    [wrapperController setUpdatingState:kDisconnected];
    if (self.refreshButton)
        [wrapperController.navigationItem
            setLeftBarButtonItem:self.refreshButton
            animated:YES];

    outstandingRequests--;
}

- (void)fetchedTweet:(Tweet *)tweet withId:(NSNumber *)tweetId
{
    NSLog(@"Mention display mgr: fetched tweet: %@", tweet);

    [self.lastTweetDetailsController hideFavoriteButton:NO];
    [self.lastTweetDetailsController displayTweet:tweet
         onNavigationController:nil];
}

- (void)failedToFetchTweetWithId:(NSNumber *)tweetId error:(NSError *)error
{
    NSLog(@"Mention display manager: failed to fetch tweet %@", tweetId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchtweet", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
    [self.lastTweetDetailsWrapperController setUpdatingState:kDisconnected];
}

- (void)tweet:(Tweet *)tweet markedAsFavorite:(BOOL)favorite
{
    NSLog(@"Mention display manager: set favorite value for tweet: %@",
        tweet.identifier);
    tweet.favorited = [NSNumber numberWithBool:favorite];
    if ([self.lastTweetDetailsController.tweet.identifier
        isEqual:tweet.identifier])
        [self.lastTweetDetailsController setFavorited:favorite];
}

- (void)failedToMarkTweet:(NSNumber *)tweetId asFavorite:(BOOL)favorite
    error:(NSError *)error
{
    NSLog(@"Mention display manager: failed to set favorite");
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.setfavorite", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
    if ([self.lastTweetDetailsController.tweet.identifier isEqual:tweetId])
        [self.lastTweetDetailsController
        setFavorited:
        [self.lastTweetDetailsController.tweet.favorited boolValue]];
}

- (void)retweetSentSuccessfully:(Tweet *)retweet tweetId:(NSNumber *)tweetId
{
    NSLog(@"Successfully posted retweet; id: %@", tweetId);
    if ([self.lastTweetDetailsController.tweet.identifier isEqual:tweetId]) {
        [self.lastTweetDetailsController setSentRetweet];
        
        TwitchAppDelegate * appDelegate = (TwitchAppDelegate *)
            [[UIApplication sharedApplication] delegate];
        [appDelegate userDidSendTweet:retweet];
    }
}

- (void)failedToSendRetweet:(NSNumber *)tweetId error:(NSError *)error
{
    NSLog(@"Failed to post retweet: %@", tweetId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.retweet", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
    if ([self.lastTweetDetailsController.tweet.identifier isEqual:tweetId])
        [self.lastTweetDetailsController setSentRetweet];
}

- (void)failedToDeleteTweetWithId:(NSNumber *)tweetId error:(NSError *)error
{
    NSLog(@"Mention display manager: failed to delete tweet");
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.deletetweet", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    NSLog(@"Mentions timeline will appear");
    displayed = YES;
    self.selectedTweet = nil;
}

- (void)networkAwareViewWillDisappear
{
    NSLog(@"Mentions timeline will disappear");
    displayed = NO;
}

#pragma mark TimelineViewControllerDelegate implementation

- (void)selectedTweet:(Tweet *)tweet
{
    // HACK: forces to scroll to top
    [self.tweetDetailsController.tableView setContentOffset:CGPointMake(0, 300)
        animated:NO];

    NSLog(@"Mention display manager: selected tweet: %@", tweet);
    self.selectedTweet = tweet;
    
    BOOL tweetByUser = [tweet.user.username isEqual:credentials.username];
    self.tweetDetailsController.navigationItem.rightBarButtonItem.enabled =
        !tweetByUser;
    [self.tweetDetailsController setUsersTweet:tweetByUser];

    NSArray * segmentedControlItems =
        [NSArray arrayWithObjects:[UIImage imageNamed:@"UpButton.png"],
        [UIImage imageNamed:@"DownButton.png"], nil];
    UISegmentedControl * upDownControl =
        [[[UISegmentedControl alloc] initWithItems:segmentedControlItems]
        autorelease];
    upDownControl.segmentedControlStyle = UISegmentedControlStyleBar;
    CGRect segmentedControlFrame = upDownControl.frame;
    segmentedControlFrame.size.width = 88;
    upDownControl.frame = segmentedControlFrame;
    [upDownControl addTarget:self action:@selector(handleUpDownButton:)
        forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem * rightBarButtonItem =
        [[[UIBarButtonItem alloc] initWithCustomView:upDownControl]
        autorelease];
    self.tweetDetailsController.navigationItem.rightBarButtonItem =
        rightBarButtonItem;

    [self.tweetDetailsController hideFavoriteButton:NO];
    [self.tweetDetailsController displayTweet:tweet
        onNavigationController:navigationController];
    self.tweetDetailsController.allowDeletion =
        [tweet.user.username isEqual:credentials.username];
        
    NSInteger tweetIndex =
        [[self.tweetIdToIndexDict objectForKey:selectedTweet.identifier]
        intValue];
    NSString * titleFormatString =
        NSLocalizedString(@"tweetdetailsview.titleformat", @"");
    self.tweetDetailsController.navigationItem.title =
        [NSString stringWithFormat:titleFormatString, tweetIndex + 1,
        [mentions count]];
    [upDownControl setEnabled:tweetIndex != 0 forSegmentAtIndex:0];
    [upDownControl setEnabled:tweetIndex != [mentions count] - 1
        forSegmentAtIndex:1];
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
    NSLog(@"Mention display manager: showing next tweet");
    NSNumber * tweetIndex =
        [self.tweetIdToIndexDict objectForKey:selectedTweet.identifier];
    NSLog(@"Selected tweet index: %@", tweetIndex);

    NSNumber * nextIndex = [NSNumber numberWithInt:[tweetIndex intValue] + 1];
    NSLog(@"Next tweet index: %@", nextIndex);

    NSString * nextTweetId = [self.tweetIndexToIdDict objectForKey:nextIndex];
    Tweet * nextTweet = [mentions objectForKey:nextTweetId];

    [timelineController selectTweetId:nextTweetId];
    [self selectedTweet:nextTweet];
}

- (void)showPreviousTweet
{
    NSLog(@"Mention display manager: showing previous tweet");
    NSNumber * tweetIndex =
        [self.tweetIdToIndexDict objectForKey:selectedTweet.identifier];
    NSLog(@"Selected tweet index: %@", tweetIndex);

    NSNumber * previousIndex =
        [NSNumber numberWithInt:[tweetIndex intValue] - 1];
    NSLog(@"Previous tweet index: %@", previousIndex);
        
    NSString * previousTweetId =
        [self.tweetIndexToIdDict objectForKey:previousIndex];
    Tweet * previousTweet = [mentions objectForKey:previousTweetId];

    [timelineController selectTweetId:previousTweetId];
    [self selectedTweet:previousTweet];
}

- (void)loadMoreTweets
{
    NSLog(@"Mention display manager: loading more tweets...");
    [self loadAnotherPageOfMentions];
}

- (void)userViewedNewestTweets
{}

#pragma mark TweetViewControllerDelegate implementation

- (void)showUserInfoForUser:(User *)aUser
{
    [displayMgrHelper showUserInfoForUser:aUser];
}

- (void)showUserInfoForUsername:(NSString *)aUsername
{
    [displayMgrHelper showUserInfoForUsername:aUsername];    
}

- (void)showResultsForSearch:(NSString *)query
{
    [displayMgrHelper showResultsForSearch:query];
}

- (void)setFavorite:(BOOL)favorite
{
    Tweet * effectiveTweet =
        selectedTweet.retweet ? selectedTweet.retweet : selectedTweet;
    NSLog(@"Mention display manager: setting tweet %@ by %@ to '%@'",
        effectiveTweet.identifier, effectiveTweet.user.username,
        favorite ? @"favorite" : @"not favorite");
    [[ErrorState instance] exitErrorState];
    [service markTweet:effectiveTweet.identifier asFavorite:favorite];
}

- (void)showLocationOnMap:(NSString *)location
{
    [displayMgrHelper showLocationOnMap:location];
}

- (void)showingTweetDetails:(TweetViewController *)tweetController
{
    NSLog(@"Mention display manager: showing tweet details...");
    self.selectedTweet = tweetController.tweet;
    self.lastTweetDetailsController = tweetController;
}

- (void)loadNewTweetWithId:(NSNumber *)tweetId username:(NSString *)username
    animated:(BOOL)animated
{
    NSLog(@"Mention display manager: showing tweet details for tweet %@",
        tweetId);

    [service fetchTweet:tweetId];
    [[self navigationController]
        pushViewController:self.newTweetDetailsWrapperController
        animated:animated];
    [self.lastTweetDetailsWrapperController setCachedDataAvailable:NO];
    [self.lastTweetDetailsWrapperController
        setUpdatingState:kConnectedAndUpdating];
}

- (void)reTweetSelected
{
    NSLog(@"Mention display manager: composing retweet");
    NSString * reTweetMessage;
    switch ([SettingsReader retweetFormat]) {
        case kRetweetFormatVia:
            reTweetMessage =
                [NSString stringWithFormat:@"%@ (via @%@)", selectedTweet.text,
                selectedTweet.user.username];
        break;
        case kRetweetFormatRT:
            reTweetMessage =
                [NSString stringWithFormat:@"RT @%@: %@",
                selectedTweet.user.username, selectedTweet.text];
        break;
    }
    
    [composeTweetDisplayMgr composeTweetWithText:reTweetMessage animated:YES];
}

- (void)retweetNativelyWithTwitter
{
    NSLog(@"Posting retweet of tweet %@", selectedTweet.identifier);
    [service sendRetweet:selectedTweet.identifier];
}

- (void)replyToTweet
{
    NSLog(@"Mention display manager: reply to tweet selected");
    [composeTweetDisplayMgr
        composeReplyToTweet:selectedTweet.identifier
        fromUser:selectedTweet.user.username];
}

- (void)loadConversationFromTweetId:(NSNumber *)tweetId
{
    UINavigationController * navController = navigationController;
    
    ConversationDisplayMgr * mgr =
        [[ConversationDisplayMgr alloc]
        initWithTwitterService:[service clone]
        context:managedObjectContext];
    [conversationDisplayMgrs addObject:mgr];
    [mgr release];
    
    mgr.delegate = self;
    [mgr displayConversationFrom:tweetId navigationController:navController];
}

- (void)deleteTweet:(NSNumber *)tweetId
{
    NSLog(@"Removing mention with id %@", tweetId);
    [mentions removeObjectForKey:tweetId];
    [timelineController performSelector:@selector(deleteTweet:)
        withObject:tweetId afterDelay:0.5];

    // Delete the tweet from Twitter after a longer delay than used for the
    // deleteTweet: method above. The Tweet object is deleted when we receive
    // confirmation from Twitter that they've deleted it. If this happens before
    // deleteTweet: executes, the method will crash because the Tweet object is
    // expected to be alive.
    [service performSelector:@selector(deleteTweet:)
        withObject:tweetId afterDelay:1.0];

    [self updateTweetIndexCache];
}

- (void)tweetViewController:(TweetViewController *)controller
       finishedLoadingTweet:(Tweet *)tweet
{
    if (controller == self.lastTweetDetailsController) {
        [self.lastTweetDetailsWrapperController
            setUpdatingState:kConnectedAndNotUpdating];
        [self.lastTweetDetailsWrapperController setCachedDataAvailable:YES];
    }
}

#pragma mark ConversationDisplayMgrDelegate implementation

- (void)displayTweetFromConversation:(Tweet *)tweet
{
    TweetViewController * controller = [self newTweetDetailsController];

    self.selectedTweet = tweet;

    controller.allowDeletion =
        [tweet.user.username isEqual:credentials.username];
    [controller hideFavoriteButton:NO];
    [controller displayTweet:tweet onNavigationController:navigationController];
}

#pragma mark Public interface implementation

- (void)refreshWithLatest
{
    [[ErrorState instance] exitErrorState];
    [self updateMentionsSinceLastUpdateIds];
}

- (void)updateMentionsSinceLastUpdateIds
{
    NSLog(@"Updating mentions since update id %@...", self.lastUpdateId);
    if (self.lastUpdateId) {
        refreshingMessages = YES;
        [self fetchMentionsSinceId:self.lastUpdateId page:nil numMessages:nil];
        [self setUpdatingState];
    } else
        [self updateWithABunchOfRecentMentions];
}

- (void)updateWithABunchOfRecentMentions
{
    NSLog(@"Updating with a bunch of mentions...");
    refreshingMessages = NO;
    NSNumber * count =
        [NSNumber numberWithInteger:[SettingsReader fetchQuantity]];
    [self fetchMentionsSinceId:[NSNumber numberWithInt:0]
        page:[NSNumber numberWithInt:1] numMessages:count];
    [self setUpdatingState];
}

- (void)loadAnotherPageOfMentions
{
    NSInteger effectivePagesShown =
        [mentions count] / [SettingsReader fetchQuantity];
    NSInteger nextPage = effectivePagesShown + 1;
    NSLog(@"Loading more mentions (page %d)...", nextPage);
    refreshingMessages = NO;
    NSNumber * count =
        [NSNumber numberWithInteger:[SettingsReader fetchQuantity]];
    [self fetchMentionsSinceId:[NSNumber numberWithInt:0]
        page:[NSNumber numberWithInt:nextPage] numMessages:count];
    [self setUpdatingState];
}

- (void)updateMentionsAfterCredentialChange
{
    if (self.lastUpdateId)
        [self updateMentionsSinceLastUpdateIds];
    else
        [self updateWithABunchOfRecentMentions];
    alreadyBeenDisplayedAfterCredentialChange = YES;
}

- (void)setTimeline:(NSDictionary *)someMentions updateId:(NSNumber *)anUpdateId
{
    [mentions removeAllObjects];
    [mentions addEntriesFromDictionary:someMentions];

    pagesShown = [mentions count] / [SettingsReader fetchQuantity];
    pagesShown = pagesShown > 0 ? pagesShown : 1;

    self.lastUpdateId = anUpdateId;

    [timelineController setTweets:[someMentions allValues] page:pagesShown
        visibleTweetId:nil];

    [self updateViewWithNewMentions];

    [self updateTweetIndexCache];
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Mention display manager: setting credentials to '%@'",
        someCredentials.username);

    [someCredentials retain];
    [credentials autorelease];
    credentials = someCredentials;

    [service setCredentials:someCredentials];

    self.activeAcctUsername = someCredentials.username;
    [displayMgrHelper setCredentials:someCredentials];
}

- (void)clearState
{
    [self.mentions removeAllObjects];
    alreadyBeenDisplayedAfterCredentialChange = NO;
    pagesShown = 1;
    refreshingMessages = NO;
    self.lastUpdateId = nil;
    [conversationDisplayMgrs removeAllObjects];
    [self.tweetIdToIndexDict removeAllObjects];
    [self.tweetIndexToIdDict removeAllObjects];
    [timelineController setTweets:[NSArray array] page:0 visibleTweetId:nil];
}

#pragma mark Private interface implementation

- (TweetViewController *)tweetDetailsController
{
    if (!tweetDetailsController) {
        tweetDetailsController =
            [[TweetViewController alloc]
            initWithNibName:@"TweetView" bundle:nil];

        UIBarButtonItem * replyButton =
            [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self
            action:@selector(presentTweetActions)]
            autorelease];
        [tweetDetailsController.navigationItem
            setRightBarButtonItem:replyButton];

        NSString * title = NSLocalizedString(@"tweetdetailsview.title", @"");
        tweetDetailsController.navigationItem.title = title;
        tweetDetailsController.navigationItem.backBarButtonItem =
            [[[UIBarButtonItem alloc]
            initWithTitle:title style:UIBarButtonItemStyleBordered target:nil
            action:nil]
            autorelease];
            
        tweetDetailsController.delegate = self;
    }

    return tweetDetailsController;
}

- (NSMutableDictionary *)tweetIdToIndexDict
{
    if (!tweetIdToIndexDict)
        tweetIdToIndexDict = [[NSMutableDictionary dictionary] retain];

    return tweetIdToIndexDict;
}

- (NSMutableDictionary *)tweetIndexToIdDict
{
    if (!tweetIndexToIdDict)
        tweetIndexToIdDict = [[NSMutableDictionary dictionary] retain];

    return tweetIndexToIdDict;
}

- (NetworkAwareViewController *)newTweetDetailsWrapperController
{
    TweetViewController * tempTweetDetailsController =
        self.newTweetDetailsController;
    NetworkAwareViewController * tweetDetailsWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:tempTweetDetailsController]
        autorelease];
    tempTweetDetailsController.realParentViewController =
        tweetDetailsWrapperController;

    NSString * title = NSLocalizedString(@"tweetdetailsview.title", @"");
    tweetDetailsWrapperController.navigationItem.title = title;

    return self.lastTweetDetailsWrapperController =
        tweetDetailsWrapperController;
}

- (TweetViewController *)newTweetDetailsController
{
    TweetViewController * newTweetViewController =
        [[TweetViewController alloc] initWithNibName:@"TweetView" bundle:nil];
    newTweetViewController.delegate = self;
    self.lastTweetDetailsController = newTweetViewController;
    [newTweetViewController release];

    return newTweetViewController;
}

- (void)setUpdatingState
{
    UIBarButtonItem * buttonItem;
    if (outstandingRequests == 0)
        buttonItem = self.refreshButton;
    else
        buttonItem = [self updatingTimelineActivityView];

    if (self.refreshButton)
        [wrapperController.navigationItem setLeftBarButtonItem:buttonItem
            animated:YES];
}

- (void)fetchMentionsSinceId:(NSNumber *)updateId page:(NSNumber *)page
    numMessages:(NSNumber *)numMessages
{
    if (outstandingRequests == 0) { // only one at a time
        outstandingRequests++;
        NSLog(@"Fetching mentions from service: %@; id: %@, page: %@, qty: %@",
            service, updateId, page, numMessages);
        [service fetchMentionsSinceUpdateId:updateId page:page
            count:numMessages];
    }
}

- (void)updateTweetIndexCache
{
    [self.tweetIdToIndexDict removeAllObjects];
    [self.tweetIndexToIdDict removeAllObjects];
    NSArray * sortedTweets =
        [[[mentions allValues] sortedArrayUsingSelector:@selector(compare:)]
        arrayByReversingContents];
    for (NSInteger i = 0; i < [sortedTweets count]; i++) {
        Tweet * tweet = [sortedTweets objectAtIndex:i];
        [self.tweetIdToIndexDict setObject:[NSNumber numberWithInt:i]
            forKey:tweet.identifier];
        [self.tweetIndexToIdDict setObject:tweet.identifier
            forKey:[NSNumber numberWithInt:i]];
    }
}

- (void)updateViewWithNewMentions
{
    [self setUpdatingState];

    BOOL cachedData = receivedQueryResponse || [mentions count] > 0;
    [wrapperController setCachedDataAvailable:cachedData];
}

- (NSNumber *)currentlyViewedTweetId
{
    return self.selectedTweet.identifier;
}

- (void)pushTweetWithoutAnimation:(Tweet *)tweet
{
    [[self navigationController]
        pushViewController:self.newTweetDetailsWrapperController animated:NO];
    [self.lastTweetDetailsWrapperController setCachedDataAvailable:NO];
    [self.lastTweetDetailsWrapperController
        setUpdatingState:kConnectedAndUpdating];
    [self fetchedTweet:tweet withId:tweet.identifier];
}

- (void)setNavigationController:(UINavigationController *)navc
{
    [navc retain];
    [navigationController release];
    navigationController = navc;

    displayMgrHelper.navigationController = navc;
}

- (UIBarButtonItem *)updatingTimelineActivityView
{
    if (!updatingTimelineActivityView) {
        NSString * backgroundImageFilename =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            @"NavigationButtonBackgroundDarkTheme.png" :
            @"NavigationButtonBackground.png";
        UIView * view =
            [[UIImageView alloc]
            initWithImage:[UIImage imageNamed:backgroundImageFilename]];
        UIActivityIndicatorView * activityView =
            [[[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]
            autorelease];
        activityView.frame = CGRectMake(7, 5, 20, 20);
        [view addSubview:activityView];

        updatingTimelineActivityView =
            [[UIBarButtonItem alloc] initWithCustomView:view];

        [activityView startAnimating];

        [view release];
    }

    return updatingTimelineActivityView;
}

@end
