//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import "TimelineDisplayMgr.h"
#import "TimelineDisplayMgrFactory.h"
#import "TweetViewController.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "UserListDisplayMgrFactory.h"
#import "ErrorState.h"
#import "User+UIAdditions.h"
#import "NSArray+IterationAdditions.h"
#import "DisplayMgrHelper.h"
#import "SettingsReader.h"
#import "TwitchAppDelegate.h"

@interface TimelineDisplayMgr ()

- (BOOL)cachedDataAvailable;
- (void)replyToTweetWithMessage;
- (NetworkAwareViewController *)newTweetDetailsWrapperController;
- (TweetViewController *)newTweetDetailsController;

- (void)showNextTweet;
- (void)showPreviousTweet;
- (void)updateTweetIndexCache;

@property (nonatomic, readonly) NSMutableDictionary * tweetIdToIndexDict;
@property (nonatomic, readonly) NSMutableDictionary * tweetIndexToIdDict;

@property (nonatomic, readonly) UIBarButtonItem * updatingTimelineActivityView;

@property (nonatomic, readonly) SoundPlayer * soundPlayer;

@end

@implementation TimelineDisplayMgr

@synthesize wrapperController, timelineController, lastTweetDetailsController,
    selectedTweet, updateId, user, timeline, pagesShown, displayAsConversation,
    setUserToFirstTweeter, lastTweetDetailsWrapperController,
    currentUsername, allPagesLoaded,setUserToAuthenticatedUser,
    firstFetchReceived, tweetIdToShow, suppressTimelineFailures, credentials,
    showMentions, tweetIdToIndexDict, navigationController,
    updatingTimelineActivityView, refreshButton, needsRefresh, hasBeenDisplayed,
    autoUpdate;

- (void)dealloc
{
    [wrapperController release];
    [navigationController release];
    [timelineController release];
    [lastTweetDetailsWrapperController release];
    [lastTweetDetailsController release];
    [tweetDetailsController release];

    [displayMgrHelper release];

    [timelineSource release];
    [service release];

    [selectedTweet release];
    [currentUsername release];
    [user release];
    [timeline release];
    [updateId release];
    [baseTitle release];

    [credentials release];

    [managedObjectContext release];

    [composeTweetDisplayMgr release];

    [conversationDisplayMgrs release];

    [tweetIdToIndexDict release];

    [updatingTimelineActivityView release];

    [refreshButton release];

    [soundPlayer release];

    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    navigationController:(UINavigationController *)aNavigationController
    timelineController:(TimelineViewController *)aTimelineController
    timelineSource:(NSObject<TimelineDataSource> *)aTimelineSource
    service:(TwitterService *)aService title:(NSString *)title
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )aManagedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr
    userListDisplayMgrFactory:(UserListDisplayMgrFactory *)userListDispMgrFctry
    contactCache:(ContactCache *)aContactCache
    contactMgr:(ContactMgr *)aContactMgr
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        navigationController = [aNavigationController retain];
        timelineController = [aTimelineController retain];
        timelineSource = [aTimelineSource retain];
        service = [aService retain];
        managedObjectContext = [aManagedObjectContext retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        timeline = [[NSMutableDictionary dictionary] retain];

        TwitterService * displayHelperService =
            [[[TwitterService alloc]
            initWithTwitterCredentials:service.credentials
            context:aManagedObjectContext]
            autorelease];

        displayMgrHelper =
            [[DisplayMgrHelper alloc]
            initWithWrapperController:aWrapperController
            navigationController:navigationController
            userListDisplayMgrFactor:userListDispMgrFctry
            composeTweetDisplayMgr:composeTweetDisplayMgr
            twitterService:displayHelperService
            timelineFactory:factory
            managedObjectContext:managedObjectContext
            findPeopleBookmarkMgr:aFindPeopleBookmarkMgr
            contactCache:aContactCache contactMgr:aContactMgr];
        displayHelperService.delegate = displayMgrHelper;

        pagesShown = 1;

        [wrapperController setCachedDataAvailable:NO];
        wrapperController.title = title;
        baseTitle = [title copy];
        
        conversationDisplayMgrs = [[NSMutableArray alloc] init];

        // attempt to preload the tweet view, but not in the critical path
        [self performSelector:@selector(preloadTweetView) withObject:nil
            afterDelay:2.0];
    }

    return self;
}

#pragma mark TimelineDataSourceDelegate implementation

- (void)timeline:(NSArray *)aTimeline
    fetchedSinceUpdateId:(NSNumber *)anUpdateId page:(NSNumber *)page
{
    NSLog(@"Timeline display manager: received timeline of size %d", 
        [aTimeline count]);
    NSLog(@"Timeline update id: %@", anUpdateId);
    NSLog(@"Timeline page: %@", page);

    if ([aTimeline count] > 0) {
        NSArray * sortedTimeline =
            [[aTimeline sortedArrayUsingSelector:@selector(compare:)]
            arrayByReversingContents];
        Tweet * mostRecentTweet = [sortedTimeline objectAtIndex:0];
        long long updateIdAsLongLong =
            [mostRecentTweet.identifier longLongValue];
        self.updateId = [NSNumber numberWithLongLong:updateIdAsLongLong];
    }

    NSInteger oldTimelineCount = [[timeline allKeys] count];
    if (!firstFetchReceived)
        [timeline removeAllObjects];
    for (Tweet * tweet in aTimeline)
        [timeline setObject:tweet forKey:tweet.identifier];

    NSInteger newTimelineCount = [[timeline allKeys] count];

    if (!refreshingTweets) { // loading more
        NSInteger pageAsInt = [page intValue];
        allPagesLoaded =
            (oldTimelineCount == newTimelineCount && firstFetchReceived &&
            pageAsInt > pagesShown) ||
            newTimelineCount == 0;
        if (allPagesLoaded) {
            NSLog(@"Timeline display manager: setting all pages loaded");
            NSLog(@"Refreshing tweets?: %d", refreshingTweets);
            NSLog(@"Old timeline count: %d", oldTimelineCount);
            NSLog(@"New timeline count: %d", newTimelineCount);
        } else if (pageAsInt != 0)
            pagesShown = pageAsInt;

        [timelineController setAllPagesLoaded:allPagesLoaded];
    } else if (aTimeline.count > 0) {
        numUnreadTweets += aTimeline.count;
        wrapperController.title =
            [NSString stringWithFormat:@"%@ (%d)", baseTitle, numUnreadTweets];
    }
    
    if (setUserToFirstTweeter) {
        timelineController.showWithoutAvatars = YES;
        if ([aTimeline count] > 0) {
            Tweet * firstTweet = [aTimeline objectAtIndex:0];
            [timelineController setUser:firstTweet.user];
            self.user = firstTweet.user;
        } else if (credentials)
            [service fetchUserInfoForUsername:self.currentUsername];
    }

    [wrapperController setCachedDataAvailable:YES];
    
    if (!refreshingTweets || aTimeline.count > 0) // only if something changed
        [timelineController setWithoutScrollingTweets:[timeline allValues]
            page:pagesShown];
    
    refreshingTweets = NO;
    [[ErrorState instance] exitErrorState];
    firstFetchReceived = YES;
    self.tweetIdToShow = nil;

    [self updateTweetIndexCache];
}

- (void)updateTweetIndexCache
{
    [self.tweetIdToIndexDict removeAllObjects];
    [self.tweetIndexToIdDict removeAllObjects];
    NSArray * sortedTweets =
        [[[timeline allValues] sortedArrayUsingSelector:@selector(compare:)]
        arrayByReversingContents];
    for (NSInteger i = 0; i < [sortedTweets count]; i++) {
        Tweet * tweet = [sortedTweets objectAtIndex:i];
        [self.tweetIdToIndexDict setObject:[NSNumber numberWithInt:i]
            forKey:tweet.identifier];
        [self.tweetIndexToIdDict setObject:tweet.identifier
            forKey:[NSNumber numberWithInt:i]];
    }
}

- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)anUpdateId
    page:(NSNumber *)page error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to fetch timeline since %@",
        anUpdateId);
    NSLog(@"Error: %@", error);
    if (!suppressTimelineFailures) {
        NSString * errorMessage =
            NSLocalizedString(@"timelinedisplaymgr.error.fetchtimeline", @"");
        [[ErrorState instance] displayErrorWithTitle:errorMessage error:error
            retryTarget:self retryAction:@selector(refreshWithLatest)];
    }

    [self.wrapperController setUpdatingState:kDisconnected];
    if (self.refreshButton)
        [self.wrapperController.navigationItem
            setLeftBarButtonItem:self.refreshButton
            animated:YES];
}

#pragma mark TwitterServiceDelegate implementation

- (void)fetchedTweet:(Tweet *)tweet withId:(NSNumber *)tweetId
{
    NSLog(@"Timeline display mgr: fetched tweet: %@", tweet);

    [self.lastTweetDetailsController hideFavoriteButton:NO];
    [self.lastTweetDetailsController displayTweet:tweet
         onNavigationController:nil];
}

- (void)failedToFetchTweetWithId:(NSNumber *)tweetId error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to fetch tweet %@", tweetId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchtweet", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
    [self.lastTweetDetailsWrapperController setUpdatingState:kDisconnected];
}

- (void)tweet:(Tweet *)tweet markedAsFavorite:(BOOL)favorite
{
    NSLog(@"Timeline display manager: set favorite value for tweet: %@",
        tweet.identifier);
    tweet.favorited = [NSNumber numberWithBool:favorite];

    Tweet * displayedTweet = self.lastTweetDetailsController.tweet;

    BOOL isDisplayed =
        [tweet.identifier isEqualToNumber:displayedTweet.identifier] ||
        [tweet.identifier isEqualToNumber:displayedTweet.retweet.identifier];
    if (isDisplayed)
        [self.lastTweetDetailsController setFavorited:favorite];
}

- (void)failedToMarkTweet:(NSNumber *)tweetId asFavorite:(BOOL)favorite
    error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to set favorite status for tweet: "
        "%@", tweetId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.setfavorite", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
    if ([self.lastTweetDetailsController.tweet.identifier isEqual:tweetId])
        [self.lastTweetDetailsController
        setFavorited:
        [self.lastTweetDetailsController.tweet.favorited boolValue]];
}

- (void)retweetSentSuccessfully:(Tweet *)retweet tweetId:(NSNumber *)tweetId
{
    NSLog(@"Successfully posted retweet; id: %@", tweetId);
    if ([self.lastTweetDetailsController.tweet.identifier
        isEqual:tweetId]) {
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
    NSLog(@"Timeline display manager: failed to delete tweet");
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.deletetweet", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
}

#pragma mark TimelineViewControllerDelegate implementation

- (void)selectedTweet:(Tweet *)tweet
{
    if ([[tweet searchResult] boolValue]) {
        [self loadNewTweetWithId:tweet.identifier username:tweet.user.username
            animated:YES];
        return;
    }

    displayedATweet = YES;
    // HACK: forces to scroll to top
    [self.tweetDetailsController.tableView setContentOffset:CGPointMake(0, 300)
        animated:NO];

    NSLog(@"Timeline display manager: selected tweet(%@): %@: %@",
        tweet.identifier, tweet.user.username, tweet.text);
    self.selectedTweet = tweet;

    BOOL tweetByUser = [tweet.user.username isEqual:credentials.username];
    self.tweetDetailsController.navigationItem.rightBarButtonItem.enabled =
        !tweetByUser;
    [self.tweetDetailsController setUsersTweet:tweetByUser];

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
    self.tweetDetailsController.navigationItem.rightBarButtonItem =
        rightBarButtonItem;

    [self.tweetDetailsController hideFavoriteButton:NO];
    [self.tweetDetailsController displayTweet:tweet
        onNavigationController:[self navigationController]];
    self.tweetDetailsController.allowDeletion =
        [tweet.user.username isEqual:credentials.username];
        
    NSInteger tweetIndex =
        [[self.tweetIdToIndexDict objectForKey:selectedTweet.identifier]
        intValue];
    NSString * titleFormatString =
        NSLocalizedString(@"tweetdetailsview.titleformat", @"");
    self.tweetDetailsController.navigationItem.title =
        [NSString stringWithFormat:titleFormatString, tweetIndex + 1,
        [timeline count]];
    [segmentedControl setEnabled:tweetIndex != 0 forSegmentAtIndex:0];
    [segmentedControl setEnabled:tweetIndex != [timeline count] - 1
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
    NSLog(@"Timeline display manager: showing next tweet");
    NSNumber * tweetIndex =
        [self.tweetIdToIndexDict objectForKey:selectedTweet.identifier];
    NSLog(@"Selected tweet index: %@", tweetIndex);

    NSNumber * nextIndex = [NSNumber numberWithInt:[tweetIndex intValue] + 1];
    NSLog(@"Next tweet index: %@", nextIndex);

    NSString * nextTweetId = [self.tweetIndexToIdDict objectForKey:nextIndex];
    Tweet * nextTweet = [timeline objectForKey:nextTweetId];

    [timelineController selectTweetId:nextTweetId];
    [self selectedTweet:nextTweet];
}

- (void)showPreviousTweet
{
    NSLog(@"Timeline display manager: showing previous tweet");
    NSNumber * tweetIndex =
        [self.tweetIdToIndexDict objectForKey:selectedTweet.identifier];
    NSLog(@"Selected tweet index: %@", tweetIndex);

    NSNumber * previousIndex =
        [NSNumber numberWithInt:[tweetIndex intValue] - 1];
    NSLog(@"Previous tweet index: %@", previousIndex);
        
    NSString * previousTweetId =
        [self.tweetIndexToIdDict objectForKey:previousIndex];
    Tweet * previousTweet = [timeline objectForKey:previousTweetId];

    [timelineController selectTweetId:previousTweetId];
    [self selectedTweet:previousTweet];
}

- (void)loadMoreTweets
{
    NSLog(@"Timeline display manager: loading more tweets...");
    if ([timelineSource credentials]) {
        NSInteger nextPage = pagesShown + 1;
        [timelineSource fetchTimelineSince:[NSNumber numberWithInt:0]
            page:[NSNumber numberWithInt:nextPage]];
        NSLog(@"Timeline display manager: sent request for page %d",
            nextPage);
    }
    [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
}

- (void)userViewedNewestTweets
{
    numUnreadTweets = 0;
    wrapperController.title = baseTitle;
}

- (void)deleteTweet:(NSNumber *)tweetId
{
    NSLog(@"Removing tweet with id %@", tweetId);
    [timeline removeObjectForKey:tweetId];
    [timelineController performSelector:@selector(deleteTweet:)
        withObject:tweetId afterDelay:0.5];

    // Delete the tweet from Twitter after a longer delay than used for the
    // deleteTweet: method above. The Tweet object is deleted when we receive
    // confirmation from Twitter that they've deleted it. If this happens before
    // deleteTweet: executes, the method will crash because the Tweet object is
    // expected to be alive.
    [service performSelector:@selector(deleteTweet:) withObject:tweetId
        afterDelay:1.0];

    [self updateTweetIndexCache];
}

#pragma mark TweetDetailsViewDelegate implementation

- (void)setFavorite:(BOOL)favorite
{
    Tweet * effectiveTweet =
        selectedTweet.retweet ? selectedTweet.retweet : selectedTweet;
    NSLog(@"Timeline display manager: setting tweet %@ by %@ to '%@'",
        effectiveTweet.identifier, effectiveTweet.user.username,
        favorite ? @"favorite" : @"not favorite");
    [[ErrorState instance] exitErrorState];
    [service markTweet:effectiveTweet.identifier asFavorite:favorite];
}

- (void)replyToTweet
{
    NSLog(@"Timeline display manager: reply to tweet selected");
    [composeTweetDisplayMgr
        composeReplyToTweet:selectedTweet.identifier
        fromUser:selectedTweet.user.username];
}

- (void)showingTweetDetails:(TweetViewController *)tweetController
{
    NSLog(@"Timeline display manager: showing tweet details...");
    self.selectedTweet = tweetController.tweet;
    self.lastTweetDetailsController = tweetController;
}

- (void)sendDirectMessageToUser:(NSString *)username
{
    NSLog(@"Timeline display manager: sending direct message to %@", username);
    [composeTweetDisplayMgr composeDirectMessageTo:username animated:YES];
}

- (void)sendPublicMessageToUser:(NSString *)username
{
    NSLog(@"Timeline display manager: sending public message to %@", username);
    [composeTweetDisplayMgr
        composeTweetWithText:[NSString stringWithFormat:@"@%@ ", username]
        animated:YES];
}

- (void)sendDirectMessageToCurrentUser
{
    NSLog(@"Timeline display manager: sending direct message to %@",
        user.username);
    [composeTweetDisplayMgr composeDirectMessageTo:self.currentUsername
        animated:YES];
}

- (void)loadNewTweetWithId:(NSNumber *)tweetId
    username:(NSString *)replyToUsername animated:(BOOL)animated
{
    NSLog(@"Timeline display manager: showing tweet details for tweet %@",
        tweetId);

    [service fetchTweet:tweetId];
    [[self navigationController]
        pushViewController:self.newTweetDetailsWrapperController
        animated:animated];
    [self.lastTweetDetailsWrapperController setCachedDataAvailable:NO];
    [self.lastTweetDetailsWrapperController
        setUpdatingState:kConnectedAndUpdating];
}

- (void)loadConversationFromTweetId:(NSNumber *)tweetId
{
    UINavigationController * navController = [self navigationController];

    ConversationDisplayMgr * mgr =
        [[ConversationDisplayMgr alloc]
        initWithTwitterService:[service clone]
        context:managedObjectContext];
    [conversationDisplayMgrs addObject:mgr];
    [mgr release];

    mgr.delegate = self;
    [mgr displayConversationFrom:tweetId navigationController:navController];
}

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

- (void)showLocationOnMap:(NSString *)location
{
    [displayMgrHelper showLocationOnMap:location];
}

- (void)tweetViewController:(TweetViewController *)controller
       finishedLoadingTweet:(Tweet *)tweet
{
    if (controller == self.lastTweetDetailsController) {
        if (self.refreshButton)
            [wrapperController.navigationItem
                setLeftBarButtonItem:self.refreshButton
                animated:YES];
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
    [controller displayTweet:tweet
        onNavigationController:[self navigationController]];
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    NSLog(@"Timeline display manager: showing timeline view...");

    if (((!hasBeenDisplayed && [timelineSource credentials]) || needsRefresh) &&
        [timelineSource readyForQuery]) {

        NSLog(@"Timeline display manager:\
            fetching new timeline when shown for first time...");
        if (self.refreshButton && [wrapperController cachedDataAvailable])
            [wrapperController.navigationItem
                setLeftBarButtonItem:[self updatingTimelineActivityView]
                animated:NO];
        [timelineSource fetchTimelineSince:[NSNumber numberWithInt:0]
            page:[NSNumber numberWithInt:pagesShown]];
        
        if (autoUpdate && !autoUpdateStarted) {
            autoUpdateStarted = YES;
            [self performSelector:@selector(refreshAndReschedule) withObject:nil
                afterDelay:45];
        }
    }
    
    hasBeenDisplayed = YES;
    needsRefresh = NO;
    self.selectedTweet = nil;

    [conversationDisplayMgrs removeAllObjects];
}

- (void)refreshAndReschedule
{
    [self refreshWithLatest];
    [self performSelector:@selector(refreshAndReschedule) withObject:nil
        afterDelay:45];
}

#pragma mark TimelineDisplayMgr implementation

- (void)refreshWithLatest
{
    NSLog(@"Timeline display manager: refreshing timeline with latest...");
    if([timelineSource credentials]) {
        refreshingTweets = YES;
        [[ErrorState instance] exitErrorState];
        [timelineSource fetchTimelineSince:self.updateId
            page:[NSNumber numberWithInt:0]];
    } else
        NSLog(@"Timeline display manager: not updating due to nil credentials");
    if (self.refreshButton && [wrapperController cachedDataAvailable])
        [wrapperController.navigationItem
            setLeftBarButtonItem:[self updatingTimelineActivityView]
            animated:YES];
    [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
}

- (void)refreshWithCurrentPages
{
    NSLog(@"Timeline display manager: refreshing with current pages...");
    if([timelineSource credentials]) {
        refreshingTweets = YES;
        hasBeenDisplayed = YES;
        [timelineSource fetchTimelineSince:[NSNumber numberWithInt:0] page:
            [NSNumber numberWithInt:pagesShown]];
        if (self.refreshButton && [wrapperController cachedDataAvailable])
            [wrapperController.navigationItem
                setLeftBarButtonItem:[self updatingTimelineActivityView]
                animated:YES];
        [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
    } else
        NSLog(@"Timeline display manager: not updating due to nil credentials");
}

- (CGFloat)tableViewContentOffset
{
    return self.timelineController.tableView.contentOffset.y;
}

- (void)setTableViewContentOffset:(CGFloat)contentOffset
{
    CGPoint offset = CGPointMake(0, contentOffset);
    [self.timelineController.tableView setContentOffset:offset animated:NO];
}

- (CGFloat)timelineContentHeight
{
    return [self.timelineController contentHeight];
}

- (void)addTweet:(Tweet *)tweet
{
    NSLog(@"Timeline display manager: adding tweet");
    [timeline setObject:tweet forKey:tweet.identifier];

    [timelineController addTweet:tweet];

    [self.soundPlayer
        performSelectorInBackground:@selector(playSoundInMainBundle:)
        withObject:@"Bloop.wav"];
}

- (BOOL)cachedDataAvailable
{
    return !!timeline && [timeline count] > 0;
}

- (void)replyToTweetWithMessage
{
    NSLog(@"Timeline display manager: replying to tweet with direct message");
    [composeTweetDisplayMgr composeDirectMessageTo:selectedTweet.user.username
        animated:YES];
}

- (void)reTweetSelected
{
    NSLog(@"Timeline display manager: composing retweet");
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

#pragma mark Accessors

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

- (void)preloadTweetView
{
    if (!displayedATweet) {
        Tweet * someTweet =
            [[timeline allKeys] count] > 0 ?
            [[timeline allValues] objectAtIndex:0] : nil;
        if (someTweet) {
            [self.tweetDetailsController displayTweet:someTweet
                onNavigationController:nil];

            UIView * tweetView = self.tweetDetailsController.view;
            UIGraphicsBeginImageContext(tweetView.bounds.size);
            [tweetView.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIGraphicsEndImageContext();
        }
    }
}

- (void)setService:(NSObject<TimelineDataSource> *)aTimelineSource
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
    forceRefresh:(BOOL)refresh allPagesLoaded:(BOOL)newAllPagesLoaded
{
    CGFloat headerHeight =
        timelineController.tableView.tableHeaderView.frame.size.height;
    [self setService:aTimelineSource tweets:someTweets page:page
        forceRefresh:refresh allPagesLoaded:newAllPagesLoaded
        verticalOffset:headerHeight];
}

- (void)setService:(NSObject<TimelineDataSource> *)aTimelineSource
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
    forceRefresh:(BOOL)refresh allPagesLoaded:(BOOL)newAllPagesLoaded
    verticalOffset:(CGFloat)verticalOffset
{
    NSLog(@"Setting service; page: %d", page);
    [aTimelineSource retain];
    [timelineSource release];
    timelineSource = aTimelineSource;

    // in case in the middle of updating while switched
    if (self.refreshButton)
        [wrapperController.navigationItem
            setLeftBarButtonItem:self.refreshButton
            animated:YES];

    [timeline removeAllObjects];
    [timeline addEntriesFromDictionary:someTweets];

    BOOL cachedDataAvailable = [[timeline allKeys] count] > 0;
    if (cachedDataAvailable)
        NSLog(@"Setting cached data available");
    [self.wrapperController setCachedDataAvailable:cachedDataAvailable];

    pagesShown = page;
    allPagesLoaded = newAllPagesLoaded;

    [aTimelineSource setCredentials:credentials];

    [timelineController setTweets:[timeline allValues] page:pagesShown
        verticalOffset:verticalOffset visibleTweetId:self.tweetIdToShow];
    [timelineController setAllPagesLoaded:allPagesLoaded];

    if (refresh || [[someTweets allKeys] count] == 0) {
        NSLog(@"Timeline display manager: \
            refreshing current pages due to new service");
        [self refreshWithCurrentPages];
    }

    [self.wrapperController
        setCachedDataAvailable:[[someTweets allKeys] count] > 0];

    firstFetchReceived = firstFetchReceived && !refresh;

    [self updateTweetIndexCache];
}

- (void)setTweets:(NSDictionary *)someTweets
{
    NSInteger page = [someTweets count]/ [SettingsReader fetchQuantity];
    page = page > 0 ? page : 1;
    [self setService:timelineSource tweets:someTweets page:page forceRefresh:NO
        allPagesLoaded:NO];
}

- (void)credentialsSetChanged:(TwitterCredentials *)changedCredentials
                        added:(NSNumber *)added
{
    NSLog(@"Timeline display manager: credentials set changed: %@: %@",
        changedCredentials.username, [added boolValue] ? @"added" : @"removed");

    if (![added boolValue] && [changedCredentials isEqual:credentials]) {
        [service setCredentials:nil];

        [timeline removeAllObjects];
        [timelineController setTweets:[NSArray array] page:0
            visibleTweetId:nil];

        [credentials release];
        credentials = nil;
    }
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Timeline display manager: credentials changing to: '%@'",
        someCredentials.username);

    // HACK: When accounts are switched, this function is called twice via the
    // search tab. The first time, the credentials are different and the code
    // executes correctly. The second time, the old credentials are the same as
    // the new credentials. This triggers the
    // [timelineSource fetchTimelineSince:page:] to be called at the end of the
    // function. In the case of the search bar, this causes an empty query to be
    // submitted (the query was cleared as part of the account switching), which
    // in turn generates an error from Twitter which is displayed to the user.
    if (credentials == someCredentials)
        return;

    TwitterCredentials * oldCredentials = credentials;

    [someCredentials retain];
    [credentials autorelease];
    credentials = someCredentials;
    
    if (displayAsConversation) {
        NSArray * invertedCellUsernames =
            [NSArray arrayWithObject:someCredentials.username];
        self.timelineController.invertedCellUsernames = invertedCellUsernames;
    }

    if (setUserToAuthenticatedUser)
        self.currentUsername = credentials.username;
    if (showMentions)
        self.timelineController.mentionUsername = credentials.username;

    [service setCredentials:credentials];
    [displayMgrHelper setCredentials:credentials];
    [timelineSource setCredentials:credentials];

    if (oldCredentials && oldCredentials != credentials) {
        // Changed accounts (as opposed to setting it for the first time)

        NSLog(@"Timeline display manager: changing accounts (%@)",
            credentials.username);

        [timeline removeAllObjects];
        if (user)
            [service fetchUserInfoForUsername:credentials.username];

        needsRefresh = YES;
        pagesShown = 1;

        [timelineController.tableView setContentOffset:CGPointMake(0, 300)
            animated:NO];
    } else if (hasBeenDisplayed) {// set for first time and persisted data shown
        NSLog(@"Timeline display manager: setting account for first time; \
            fetching timeline with page parameter %d", pagesShown);
        [timelineSource fetchTimelineSince:[NSNumber numberWithInt:0]
            page:[NSNumber numberWithInt:pagesShown]];
    }
}

- (void)setUser:(User *)aUser
{
    NSLog(@"Timeline display manager: setting display user to: %@",
        aUser.username);

    [aUser retain];
    [user release];
    user = aUser;

    [self.timelineController setUser:aUser];
}

- (NSMutableDictionary *)timeline
{
    return [[timeline copy] autorelease];
}

- (void)setDisplayAsConversation:(BOOL)conversation
{
    if (conversation)
        NSLog(@"Timeline display manager: displaying as conversation");
    else
        NSLog(@"Timeline display manager: not displaying as conversation");

    displayAsConversation = conversation;
    NSArray * invertedCellUsernames =
        conversation && !!credentials ?
        [NSArray arrayWithObject:credentials.username] : [NSArray array];
    self.timelineController.invertedCellUsernames = invertedCellUsernames;
}

- (NSNumber *)mostRecentTweetId
{
    return [self.timelineController mostRecentTweetId];
}

- (NSNumber *)currentlyViewedTweetId
{
    return self.selectedTweet.identifier;
}

// HACK: Added to get "Save Search" button in header view.
- (void)setTimelineHeaderView:(UIView *)view
{
    [timelineController setTimelineHeaderView:view];
}

- (void)setShowMentions:(BOOL)show
{
    showMentions = show;
    self.timelineController.mentionUsername = show ? credentials.username : nil;
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

- (void)pushTweetWithoutAnimation:(Tweet *)tweet
{
    [[self navigationController]
        pushViewController:self.newTweetDetailsWrapperController animated:NO];
    [self.lastTweetDetailsWrapperController setCachedDataAvailable:NO];
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

- (SoundPlayer *)soundPlayer
{
    if (!soundPlayer)
        soundPlayer = [[SoundPlayer alloc] init];

    return soundPlayer;
}

@end
