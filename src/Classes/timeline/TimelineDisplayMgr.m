//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgr.h"
#import "TimelineDisplayMgrFactory.h"
#import "ArbUserTimelineDataSource.h"
#import "FavoritesTimelineDataSource.h"
#import "TweetViewController.h"
#import "SearchDataSource.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "UserListDisplayMgrFactory.h"
#import "ErrorState.h"
#import "UIColor+TwitchColors.h"
#import "User+UIAdditions.h"
#import "NearbySearchDataSource.h"
#import "SettingsReader.h"

@interface TimelineDisplayMgr ()

- (BOOL)cachedDataAvailable;
- (void)deallocateTweetDetailsNode;
- (void)replyToTweetWithMessage;
- (NetworkAwareViewController *)newTweetDetailsWrapperController;
- (TweetViewController *)newTweetDetailsController;

- (void)removeSearch:(NSString *)search;
- (void)saveSearch:(NSString *)search;

- (UIView *)saveSearchView;
- (UIView *)removeSearchView;
- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title
    action:(SEL)action;

- (void)showNextTweet;
- (void)showPreviousTweet;
- (void)updateTweetIndexCache;

+ (NSInteger)retweetFormat;
+ (BOOL)scrollToTop;

@property (nonatomic, retain) SavedSearchMgr * savedSearchMgr;
@property (nonatomic, retain) NSString * currentSearch;

@property (nonatomic, readonly)
    LocationMapViewController * locationMapViewController;
@property (nonatomic, readonly)
    LocationInfoViewController * locationInfoViewController;
    
@property (nonatomic, readonly) NSMutableDictionary * tweetIdToIndexDict;
@property (nonatomic, readonly) NSMutableDictionary * tweetIndexToIdDict;

@end

enum {
    kRetweetFormatVia,
    kRetweetFormatRT
} RetweetFormat;

@implementation TimelineDisplayMgr

static NSInteger retweetFormat;
static NSInteger retweetFormatValueAlredyRead;

static BOOL scrollToTop;
static BOOL scrollToTopValueAlreadyRead;

@synthesize wrapperController, timelineController, userInfoController,
    selectedTweet, updateId, user, timeline, pagesShown, displayAsConversation,
    setUserToFirstTweeter, tweetDetailsTimelineDisplayMgr,
    tweetDetailsNetAwareViewController, tweetDetailsCredentialsPublisher,
    lastTweetDetailsWrapperController, lastTweetDetailsController,
    currentUsername, allPagesLoaded,setUserToAuthenticatedUser,
    firstFetchReceived, tweetIdToShow, suppressTimelineFailures, credentials,
    savedSearchMgr, currentSearch, userListDisplayMgr,
    userListNetAwareViewController, showMentions, tweetIdToIndexDict;

- (void)dealloc
{
    [wrapperController release];
    [timelineController release];
    [lastTweetDetailsWrapperController release];
    [lastTweetDetailsController release];
    [tweetDetailsController release];
    [findPeopleBookmarkMgr release];
    [userListDisplayMgrFactory release];

    [timelineSource release];
    [service release];

    [selectedTweet release];
    [currentUsername release];
    [user release];
    [timeline release];
    [updateId release];

    [credentials release];

    [timelineDisplayMgrFactory release];
    [tweetDetailsTimelineDisplayMgr release];
    [tweetDetailsNetAwareViewController release];
    [managedObjectContext release];

    [userListDisplayMgr release];
    [userListNetAwareViewController release];

    [composeTweetDisplayMgr release];

    [savedSearchMgr release];
    [currentSearch release];

    [userInfoControllerWrapper release];
    [userInfoRequestAdapter release];
    [userInfoTwitterService release];

    [conversationDisplayMgrs release];

    [locationMapViewController release];
    [locationInfoViewController release];

    [tweetIdToIndexDict release];

    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    timelineSource:(NSObject<TimelineDataSource> *)aTimelineSource
    service:(TwitterService *)aService title:(NSString *)title
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )aManagedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr
    userListDisplayMgrFactory:(UserListDisplayMgrFactory *)userListDispMgrFctry
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        timelineController = [aTimelineController retain];
        timelineSource = [aTimelineSource retain];
        service = [aService retain];
        timelineDisplayMgrFactory = [factory retain];
        managedObjectContext = [aManagedObjectContext retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        findPeopleBookmarkMgr = [aFindPeopleBookmarkMgr retain];
        userListDisplayMgrFactory = [userListDispMgrFctry retain];
        timeline = [[NSMutableDictionary dictionary] retain];

        pagesShown = 1;

        [wrapperController setUpdatingState:kConnectedAndUpdating];
        [wrapperController setCachedDataAvailable:NO];
        wrapperController.title = title;

        conversationDisplayMgrs = [[NSMutableArray alloc] init];
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
            [aTimeline sortedArrayUsingSelector:@selector(compare:)];
        TweetInfo * mostRecentTweetInfo = [sortedTimeline objectAtIndex:0];
        long long updateIdAsLongLong =
            [mostRecentTweetInfo.identifier longLongValue];
        self.updateId = [NSNumber numberWithLongLong:updateIdAsLongLong];
    }

    NSInteger oldTimelineCount = [[timeline allKeys] count];
    if (!firstFetchReceived)
        [timeline removeAllObjects];
    for (TweetInfo * tweet in aTimeline)
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
    }

    if (setUserToFirstTweeter) {
        timelineController.showWithoutAvatars = YES;
        if ([aTimeline count] > 0) {
            TweetInfo * firstTweet = [aTimeline objectAtIndex:0];
            [timelineController setUser:firstTweet.user];
            self.user = firstTweet.user;
        } else if (credentials)
            [service fetchUserInfoForUsername:self.currentUsername];
    }

    BOOL scrollToTop = [[self class] scrollToTop];
    NSString * scrollId =
        scrollToTop ? [anUpdateId description] : self.tweetIdToShow;
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    [wrapperController setCachedDataAvailable:YES];
    [timelineController setTweets:[timeline allValues] page:pagesShown
        visibleTweetId:scrollId];
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
        [[timeline allValues] sortedArrayUsingSelector:@selector(compare:)];
    for (NSInteger i = 0; i < [sortedTweets count]; i++) {
        TweetInfo * tweetInfo = [sortedTweets objectAtIndex:i];
        [self.tweetIdToIndexDict setObject:[NSNumber numberWithInt:i]
            forKey:tweetInfo.identifier];
        [self.tweetIndexToIdDict setObject:tweetInfo.identifier
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
        [self.wrapperController setUpdatingState:kDisconnected];
    } else
        [wrapperController setUpdatingState:kDisconnected];
}

#pragma mark TwitterServiceDelegate implementation

- (void)userInfo:(User *)aUser fetchedForUsername:(NSString *)username
{
    NSLog(@"Timeline display manager received user info for %@", username);
    [timelineController setUser:aUser];
    self.user = aUser;
    [[ErrorState instance] exitErrorState];
}

- (void)failedToFetchUserInfoForUsername:(NSString *)username
    error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to fetch user info for %@",
        username);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchuserinfo", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
    [self.wrapperController setUpdatingState:kDisconnected];
}

- (void)startedFollowingUsername:(NSString *)username
{
    NSLog(@"Timeline display manager: started following %@", username);
    if ([self.currentUsername isEqual:username])
        [self.userInfoController setFollowing:YES];
}

- (void)failedToStartFollowingUsername:(NSString *)username
{
    NSLog(@"Timeline display manager: failed to start following %@", username);
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.startfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, username];
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)stoppedFollowingUsername:(NSString *)username
{
    NSLog(@"Timeline display manager: stopped following %@", username);
    if ([self.currentUsername isEqual:username])
        [userInfoController setFollowing:NO];
}

- (void)failedToStopFollowingUsername:(NSString *)username
{
    NSLog(@"Timeline display manager: failed to stop following %@", username);
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.stopfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, username];
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)user:(NSString *)username isFollowing:(NSString *)followee
{
    NSLog(@"Timeline display manager: %@ is following %@", username, followee);
    if ([self.currentUsername isEqual:followee])
        [self.userInfoController setFollowing:YES];
}

- (void)user:(NSString *)username isNotFollowing:(NSString *)followee
{
    NSLog(@"Timeline display manager: %@ is not following %@", username,
        followee);
    if ([self.currentUsername isEqual:followee])
        [self.userInfoController setFollowing:NO];
}

- (void)userIsBlocked:(NSString *)username
{
    NSLog(@"Timeline display manager: %@ is blocked", username);
    if ([self.currentUsername isEqual:username])
        [self.userInfoController setBlocked:YES];
}

- (void)userIsNotBlocked:(NSString *)username
{
    NSLog(@"Timeline display manager: %@ is not blocked", username);
    if ([self.currentUsername isEqual:username])
        [self.userInfoController setBlocked:NO];
}

- (void)failedToCheckIfUserIsBlocked:(NSString *)username
                               error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to check if %@ is blocked; %@",
        username, error);
}

- (void)blockedUser:(User *)user withUsername:(NSString *)username
{
    if ([self.currentUsername isEqual:username])
        [self.userInfoController setBlocked:YES];
}

- (void)failedToBlockUserWithUsername:(NSString *)username
    error:(NSError *)error
{
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.block", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, username];
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)unblockedUser:(User *)user withUsername:(NSString *)username
{
    if ([self.currentUsername isEqual:username])
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

- (void)failedToQueryIfUser:(NSString *)username
    isFollowing:(NSString *)followee error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to query if %@ is following %@",
        username, followee);
    NSLog(@"Error: %@", error);

    if ([self.currentUsername isEqual:followee])
        [self.userInfoController setFailedToQueryFollowing];

    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.followingstatus", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, username];
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
}

- (void)fetchedTweet:(Tweet *)tweet withId:(NSString *)tweetId
{
    NSLog(@"Timeline display mgr: fetched tweet: %@", tweet);
    TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];

    [self.lastTweetDetailsController hideFavoriteButton:NO];
    self.lastTweetDetailsController.showsExtendedActions = YES;
    [self.lastTweetDetailsController displayTweet:tweetInfo
         onNavigationController:nil];
    [self.lastTweetDetailsWrapperController setCachedDataAvailable:YES];
    [self.lastTweetDetailsWrapperController
        setUpdatingState:kConnectedAndNotUpdating];
}

- (void)failedToFetchTweetWithId:(NSString *)tweetId error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to fetch tweet %@", tweetId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchtweet", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
    [self.lastTweetDetailsWrapperController setUpdatingState:kDisconnected];
}

- (void)tweet:(Tweet *)tweet markedAsFavorite:(BOOL)favorite
{
    NSLog(@"Timeline display manager: set favorite value for tweet");
    TweetInfo * tweetInfo = [timeline objectForKey:tweet.identifier];
    tweetInfo.favorited = [NSNumber numberWithBool:favorite];
    if ([self.lastTweetDetailsController.tweet.identifier
        isEqual:tweet.identifier])
        [self.lastTweetDetailsController setFavorited:favorite];
}

- (void)failedToMarkTweet:(NSString *)tweetId asFavorite:(BOOL)favorite
    error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to set favorite");
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.setfavorite", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
    if ([self.lastTweetDetailsController.tweet.identifier isEqual:tweetId])
        [self.lastTweetDetailsController
        setFavorited:
        [self.lastTweetDetailsController.tweet.favorited boolValue]];
}

- (void)failedToDeleteTweetWithId:(NSString *)tweetId error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to delete tweet");
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.deletetweet", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
}

#pragma mark TimelineViewControllerDelegate implementation

- (void)selectedTweet:(TweetInfo *)tweet
{
    // HACK: forces to scroll to top
    [self.tweetDetailsController.tableView setContentOffset:CGPointMake(0, 300)
        animated:NO];

    NSLog(@"Timeline display manager: selected tweet: %@", tweet);
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
    self.tweetDetailsController.showsExtendedActions = YES;
    [self.tweetDetailsController displayTweet:tweet
        onNavigationController:self.wrapperController.navigationController];
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
    TweetInfo * nextTweet = [timeline objectForKey:nextTweetId];

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
    TweetInfo * previousTweet = [timeline objectForKey:previousTweetId];

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
    [wrapperController setUpdatingState:kConnectedAndUpdating];
    [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
}

- (void)showUserInfo
{
    [self showUserInfoForUser:user];
}

- (void)showUserInfoForUser:(User *)aUser
{
    if ([aUser isComplete]) {
        NSLog(@"Timeline display manager: showing user info for user: %@",
            aUser.username);
        self.currentUsername = aUser.username;

        // HACK: forces to scroll to top
        [self.userInfoController.tableView setContentOffset:CGPointMake(0, 300)
            animated:NO];

        self.userInfoController.navigationItem.title = aUser.username;
        [self.wrapperController.navigationController
            pushViewController:self.userInfoController animated:YES];
        self.userInfoController.followingEnabled =
            ![credentials.username isEqual:aUser.username];
        [self.userInfoController setUser:aUser];
        if (self.userInfoController.followingEnabled)
            [service isUser:credentials.username following:aUser.username];
        [service isUserBlocked:aUser.username];
    } else
        [self showUserInfoForUsername:aUser.username];
}

- (void)showUserInfoForUsername:(NSString *)aUsername
{
    NSLog(@"Timeline display manager: showing user info for username '%@'",
        aUsername);
    self.currentUsername = aUsername;

    // HACK: forces to scroll to top
    [self.userInfoController.tableView setContentOffset:CGPointMake(0, 300)
        animated:NO];

    [self.userInfoController showingNewUser];
    self.userInfoControllerWrapper.navigationItem.title = aUsername;
    [self.userInfoControllerWrapper setCachedDataAvailable:NO];
    [self.userInfoControllerWrapper setUpdatingState:kConnectedAndUpdating];
    [self.wrapperController.navigationController
        pushViewController:self.userInfoControllerWrapper animated:YES];
    self.userInfoController.followingEnabled =
        ![credentials.username isEqual:aUsername];

    if (self.userInfoController.followingEnabled)
        [service isUser:credentials.username following:aUsername];
    [service isUserBlocked:aUsername];

    [self.userInfoTwitterService fetchUserInfoForUsername:aUsername];
}

- (void)deleteTweet:(NSString *)tweetId
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
    [service performSelector:@selector(deleteTweet:)
        withObject:tweetId afterDelay:1.0];

    [self updateTweetIndexCache];
}

#pragma mark TweetDetailsViewDelegate implementation

- (void)showTweetsForUser:(NSString *)username
{
    NSLog(@"Timeline display manager: showing tweets for %@", username);

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
    [self.wrapperController.navigationController
        pushViewController:self.tweetDetailsNetAwareViewController
        animated:YES];
}

- (void)showResultsForSearch:(NSString *)query
{
    NSLog(@"Timeline display manager: showing search results for '%@'", query);
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
    [self.wrapperController.navigationController
        pushViewController:self.tweetDetailsNetAwareViewController
        animated:YES];
}

- (void)showResultsForNearbySearchWithLatitude:(NSNumber *)latitude
    longitude:(NSNumber *)longitude
{
    NSLog(@"Timeline display manager: showing results for nearby search");
    self.tweetDetailsNetAwareViewController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    NSString * title =
        NSLocalizedString(@"timelinedisplaymgr.nearbysearch", @"");
    self.tweetDetailsTimelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        tweetDetailsNetAwareViewController
        title:title composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.tweetDetailsTimelineDisplayMgr.displayAsConversation = NO;
    self.tweetDetailsTimelineDisplayMgr.setUserToFirstTweeter = NO;
    self.tweetDetailsTimelineDisplayMgr.currentUsername = nil;

    [self.tweetDetailsTimelineDisplayMgr setCredentials:credentials];
    self.tweetDetailsNetAwareViewController.navigationItem.rightBarButtonItem =
        nil;

    self.tweetDetailsNetAwareViewController.delegate =
        self.tweetDetailsTimelineDisplayMgr;

    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:managedObjectContext]
        autorelease];

    NSNumber * radius =
        [NSNumber numberWithInt:[SettingsReader nearbySearchRadius]];

    NearbySearchDataSource * dataSource =
        [[[NearbySearchDataSource alloc]
        initWithTwitterService:twitterService
        latitude:latitude longitude:longitude radiusInKm:radius]
        autorelease];

    self.tweetDetailsCredentialsPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];

    twitterService.delegate = dataSource;
    [self.tweetDetailsTimelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO allPagesLoaded:NO];
    dataSource.delegate = self.tweetDetailsTimelineDisplayMgr;

    [dataSource setCredentials:credentials];
    [self.wrapperController.navigationController
        pushViewController:self.tweetDetailsNetAwareViewController
        animated:YES];
}

- (void)setFavorite:(BOOL)favorite
{
    if (favorite)
        NSLog(@"Timeline display manager: setting tweet to 'favorite'");
    else
        NSLog(@"Timeline display manager: setting tweet to 'not favorite'");
    [[ErrorState instance] exitErrorState];
    [service markTweet:selectedTweet.identifier asFavorite:favorite];
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
    [self deallocateTweetDetailsNode];
}

- (void)sendDirectMessageToUser:(NSString *)username
{
    NSLog(@"Timeline display manager: sending direct message to %@", username);
    [composeTweetDisplayMgr composeDirectMessageTo:username];
}

- (void)sendPublicMessageToUser:(NSString *)username
{
    NSLog(@"Timeline display manager: sending public message to %@", username);
    [composeTweetDisplayMgr
        composeTweetWithText:[NSString stringWithFormat:@"@%@ ", username]];
}

- (void)sendDirectMessageToCurrentUser
{
    NSLog(@"Timeline display manager: sending direct message to %@",
        user.username);
    [composeTweetDisplayMgr composeDirectMessageTo:self.currentUsername];
}

- (void)loadNewTweetWithId:(NSString *)tweetId
    username:(NSString *)replyToUsername
{
    NSLog(@"Timeline display manager: showing tweet details for tweet %@",
        tweetId);

    [service fetchTweet:tweetId];
    [self.wrapperController.navigationController
        pushViewController:self.newTweetDetailsWrapperController animated:YES];
    [self.lastTweetDetailsWrapperController setCachedDataAvailable:NO];
    [self.lastTweetDetailsWrapperController
        setUpdatingState:kConnectedAndNotUpdating];
}

- (void)loadConversationFromTweetId:(NSString *)tweetId
{
    UINavigationController * navController =
        self.wrapperController.navigationController;

    ConversationDisplayMgr * mgr =
        [[ConversationDisplayMgr alloc]
        initWithTwitterService:[service clone]
        context:managedObjectContext];
    [conversationDisplayMgrs addObject:mgr];
    [mgr release];

    mgr.delegate = self;
    [mgr displayConversationFrom:tweetId navigationController:navController];
}

#pragma mark ConversationDisplayMgrDelegate implementation

- (void)displayTweetFromConversation:(TweetInfo *)tweet
{
    TweetViewController * controller = [self newTweetDetailsController];

    self.selectedTweet = tweet;

    [controller hideFavoriteButton:NO];
    controller.showsExtendedActions = YES;
    [controller displayTweet:tweet
        onNavigationController:self.wrapperController.navigationController];
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    NSLog(@"Timeline display manager: showing timeline view...");
    if (((!hasBeenDisplayed && [timelineSource credentials]) || needsRefresh) &&
        [timelineSource readyForQuery]) {

        NSLog(@"Timeline display manager: fetching new timeline when shown...");
        [self.wrapperController setUpdatingState:kConnectedAndUpdating];
        [timelineSource fetchTimelineSince:[NSNumber numberWithInt:0]
            page:[NSNumber numberWithInt:pagesShown]];
    }

    hasBeenDisplayed = YES;
    needsRefresh = NO;

    [conversationDisplayMgrs removeAllObjects];
}

#pragma mark UserInfoViewControllerDelegate implementation

- (void)showLocationOnMap:(NSString *)locationString
{
    NSLog(@"Timeline display manager: showing %@ on map", locationString);

    self.locationMapViewController.navigationItem.title = @"Map";
    
    [wrapperController.navigationController
        pushViewController:self.locationMapViewController animated:YES];

    [self.locationMapViewController setLocation:locationString];
}

- (void)showLocationInfo:(NSString *)locationString
    coordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"Timeline display manager: showing location info for %@",
        locationString);

    [wrapperController.navigationController
        pushViewController:self.locationInfoViewController animated:YES];

    [self.locationInfoViewController setLocationString:locationString
        coordinate:coordinate];
}

- (void)displayFollowingForUser:(NSString *)username
{
    NSLog(@"Timeline display manager: displaying 'following' list for %@",
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
    NSLog(@"Timeline display manager: displaying 'followers' list for %@",
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

- (void)displayFavoritesForUser:(NSString *)username
{
    NSLog(@"Timeline display manager: displaying favorites for user %@",
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
    [self.wrapperController.navigationController
        pushViewController:self.tweetDetailsNetAwareViewController
        animated:YES];
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

- (void)showingUserInfoView
{
    NSLog(@"Timeline display manager: showing user info view");
    [self deallocateTweetDetailsNode];
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
    [wrapperController setUpdatingState:kConnectedAndUpdating];
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
        [wrapperController setUpdatingState:kConnectedAndUpdating];
        [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
    } else
        NSLog(@"Timeline display manager: not updating due to nil credentials");
}

- (void)addTweet:(Tweet *)tweet
{
    NSLog(@"Timeline display manager: adding tweet");
    TweetInfo * info = [TweetInfo createFromTweet:tweet];
    [timeline setObject:info forKey:info.identifier];

    [timelineController addTweet:info];
}

- (BOOL)cachedDataAvailable
{
    return !!timeline && [timeline count] > 0;
}

- (void)deallocateTweetDetailsNode
{
    self.tweetDetailsCredentialsPublisher = nil;
    self.tweetDetailsTimelineDisplayMgr = nil;
    self.tweetDetailsNetAwareViewController = nil;
    self.currentSearch = nil;
    self.userListDisplayMgr = nil;
    self.userListNetAwareViewController = nil;
}

- (void)replyToTweetWithMessage
{
    NSLog(@"Timeline display manager: replying to tweet with direct message");
    [composeTweetDisplayMgr composeDirectMessageTo:selectedTweet.user.username];
}

- (void)reTweetSelected
{
    NSLog(@"Timeline display manager: composing retweet");
    NSString * reTweetMessage;
    switch ([[self class] retweetFormat]) {
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

    [composeTweetDisplayMgr composeTweetWithText:reTweetMessage];
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

    UIBarButtonItem * replyButton =
        [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self
        action:@selector(presentActionsForCurrentTweetDetailsUser)]
        autorelease];
    [tweetDetailsWrapperController.navigationItem
        setRightBarButtonItem:replyButton];

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

- (UserInfoViewController *)userInfoController
{
    if (!userInfoController) {
        NSLog(@"Timeline display manager: creating new user info display mgr");
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

- (void)setService:(NSObject<TimelineDataSource> *)aTimelineSource
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
    forceRefresh:(BOOL)refresh allPagesLoaded:(BOOL)newAllPagesLoaded
{
    NSLog(@"Setting service; page: %d", page);
    [aTimelineSource retain];
    [timelineSource release];
    timelineSource = aTimelineSource;

    // in case in the middle of updating while switched
    [self.wrapperController setUpdatingState:kConnectedAndNotUpdating];

    [timeline removeAllObjects];
    [timeline addEntriesFromDictionary:someTweets];

    BOOL cachedDataAvailable = [[timeline allKeys] count] > 0;
    if (cachedDataAvailable)
        NSLog(@"Setting cached data available");
    [self.wrapperController setCachedDataAvailable:cachedDataAvailable];

    pagesShown = page;
    allPagesLoaded = newAllPagesLoaded;

    [aTimelineSource setCredentials:credentials];

    // HACK: forces timeline to scroll to top
    [timelineController.tableView setContentOffset:CGPointMake(0, 300)
        animated:NO];

    [timelineController setTweets:[timeline allValues] page:pagesShown
        visibleTweetId:self.tweetIdToShow];
    [timelineController setAllPagesLoaded:allPagesLoaded];

    if (refresh || [[someTweets allKeys] count] == 0)
        [self refreshWithCurrentPages];

    [self.wrapperController
        setCachedDataAvailable:[[someTweets allKeys] count] > 0];

    firstFetchReceived = firstFetchReceived && !refresh;

    [self updateTweetIndexCache];
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Timeline display manager: setting new credentials to: %@",
        someCredentials.username);

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

    self.savedSearchMgr.accountName = credentials.username;

    [service setCredentials:credentials];
    [userInfoTwitterService setCredentials:credentials];
    [timelineSource setCredentials:credentials];

    // check for pointer equality rather than string equality against username
    // in case 'oldCredentials' has already been physically deleted (e.g. we're
    // changing accounts b/c the old active acount was deleted and another
    // account selected)
    if (oldCredentials && oldCredentials != credentials) {
        // Changed accounts (as opposed to setting it for the first time)

        NSLog(@"Timeline display manager: changing accounts (%@)",
            credentials.username);

        [timeline removeAllObjects];
        if (user)
            [service fetchUserInfoForUsername:credentials.username];
        [wrapperController.navigationController
            popToRootViewControllerAnimated:NO];

        needsRefresh = YES;
        pagesShown = 1;

        // HACK: forces timeline to scroll to top
        [timelineController.tableView setContentOffset:CGPointMake(0, 300)
            animated:NO];
    } else if (hasBeenDisplayed) {// set for first time and persisted data shown
        NSLog(@"Timeline display manager: setting account for first time");
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
        NSLog(@"Timeline display manager init: displaying as conversation");
    else
        NSLog(@"Timeline display manager init: not displaying as conversation");

    displayAsConversation = conversation;
    NSArray * invertedCellUsernames =
        conversation && !!credentials ?
        [NSArray arrayWithObject:credentials.username] : [NSArray array];
    self.timelineController.invertedCellUsernames = invertedCellUsernames;
}

- (NSString *)mostRecentTweetId
{
    return [self.timelineController mostRecentTweetId];
}

// HACK: Added to get "Save Search" button in header view.
- (void)setTimelineHeaderView:(UIView *)view
{
    [timelineController setTimelineHeaderView:view];
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
    
    CGRect grayLineFrame = CGRectMake(0, 50, 320, 1);
    UIView * grayLineView =
        [[[UIView alloc] initWithFrame:grayLineFrame] autorelease];
    grayLineView.backgroundColor = [UIColor twitchLightGrayColor];
    grayLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UIImage * background =
        [[UIImage imageNamed:@"SaveSearchButtonBackground.png"]
        stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    UIImage * selectedBackground =
        [[UIImage imageNamed:@"SaveSearchButtonBackgroundHighlighted.png"]
        stretchableImageWithLeftCapWidth:10 topCapHeight:0];
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
    [view addSubview:grayLineView];

    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    return [view autorelease];
}

- (SavedSearchMgr *)savedSearchMgr
{
    if (!savedSearchMgr)
        savedSearchMgr =
            [[SavedSearchMgr alloc]
            initWithAccountName:self.credentials.username
            context:managedObjectContext];

    return savedSearchMgr;
}

- (void)setShowMentions:(BOOL)show
{
    showMentions = show;
    self.timelineController.mentionUsername = show ? credentials.username : nil;
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

+ (NSInteger)retweetFormat
{
    if (!retweetFormatValueAlredyRead) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        retweetFormat = [defaults integerForKey:@"retweet_format"];
        retweetFormatValueAlredyRead = YES;
    }

    return retweetFormat;
}

+ (BOOL)scrollToTop
{
    if (!scrollToTopValueAlreadyRead) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        scrollToTop = [defaults boolForKey:@"scroll_to_top"];
        scrollToTopValueAlreadyRead = YES;
    }

    return scrollToTop;
}

@end
