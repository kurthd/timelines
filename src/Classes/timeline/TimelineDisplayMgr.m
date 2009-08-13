//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgr.h"
#import "TimelineDisplayMgrFactory.h"
#import "ArbUserTimelineDataSource.h"
#import "FavoritesTimelineDataSource.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "TweetViewController.h"
#import "SearchDataSource.h"
#import "UIWebView+FileLoadingAdditions.h"
#import "UserListDisplayMgrFactory.h"

@interface TimelineDisplayMgr ()

- (BOOL)cachedDataAvailable;
- (void)deallocateTweetDetailsNode;
- (void)displayErrorWithTitle:(NSString *)title;
- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error;
- (void)replyToTweetWithMessage;
- (NetworkAwareViewController *)newTweetDetailsWrapperController;
- (TweetViewController *)newTweetDetailsController;
- (void)presentActionsForCurrentTweetDetailsUser;

- (void)presentTweetActions;
- (void)presentActionsForCurrentTweetDetailsUser;
- (void)presentTweetActionsForTarget:(id)target;

- (void)removeSearch:(NSString *)search;
- (void)saveSearch:(NSString *)search;

- (UIView *)saveSearchView;
- (UIView *)removeSearchView;
- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title
    action:(SEL)action;

+ (NSInteger)retweetFormat;

@property (nonatomic, retain) SavedSearchMgr * savedSearchMgr;
@property (nonatomic, retain) NSString * currentSearch;

@end

enum {
    kRetweetFormatVia,
    kRetweetFormatRT
} RetweetFormat;

@implementation TimelineDisplayMgr

static NSInteger retweetFormat;
static NSInteger retweetFormatValueAlredyRead;

@synthesize wrapperController, timelineController, userInfoController,
    selectedTweet, updateId, user, timeline, pagesShown, displayAsConversation,
    setUserToFirstTweeter, tweetDetailsTimelineDisplayMgr,
    tweetDetailsNetAwareViewController, tweetDetailsCredentialsPublisher,
    lastTweetDetailsWrapperController, lastTweetDetailsController,
    currentUsername, allPagesLoaded,setUserToAuthenticatedUser,
    firstFetchReceived, tweetIdToShow, suppressTimelineFailures, credentials,
    savedSearchMgr, currentSearch, userListDisplayMgr,
    userListNetAwareViewController;

- (void)dealloc
{
    [wrapperController release];
    [timelineController release];
    [lastTweetDetailsWrapperController release];
    [lastTweetDetailsController release];
    [tweetDetailsController release];
    [browserController release];
    [photoBrowser release];
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

    [timelineController setTweets:[timeline allValues] page:pagesShown
        visibleTweetId:self.tweetIdToShow];
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    [wrapperController setCachedDataAvailable:YES];
    refreshingTweets = NO;
    failedState = NO;
    firstFetchReceived = YES;
    self.tweetIdToShow = nil;
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
        [self displayErrorWithTitle:errorMessage error:error];
    } else
        [wrapperController setUpdatingState:kDisconnected];
}

#pragma mark TwitterServiceDelegate implementation

- (void)userInfo:(User *)aUser fetchedForUsername:(NSString *)username
{
    NSLog(@"Timeline display manager received user info for %@", username);
    [timelineController setUser:aUser];
    self.user = aUser;
    failedState = NO;
}

- (void)failedToFetchUserInfoForUsername:(NSString *)username
    error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to fetch user info for %@",
        username);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchuserinfo", @"");
    [self displayErrorWithTitle:errorMessage error:error];
}

- (void)startedFollowingUsername:(NSString *)username
{
    NSLog(@"Timeline display manager: started following %@", username);
}

- (void)failedToStartFollowingUsername:(NSString *)username
{
    NSLog(@"Timeline display manager: failed to start following %@", username);
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.startfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, username];
    [self displayErrorWithTitle:errorMessage];
}

- (void)stoppedFollowingUsername:(NSString *)username
{
    NSLog(@"Timeline display manager: stopped following %@", username);
}

- (void)failedToStopFollowingUsername:(NSString *)username
{
    NSLog(@"Timeline display manager: failed to stop following %@", username);
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.stopfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, username];
    [self displayErrorWithTitle:errorMessage];
}

- (void)user:(NSString *)username isFollowing:(NSString *)followee
{
    NSLog(@"Timeline display manager: %@ is following %@", username, followee);
    [self.userInfoController setFollowing:YES];
}

- (void)user:(NSString *)username isNotFollowing:(NSString *)followee
{
    NSLog(@"Timeline display manager: %@ is not following %@", username,
        followee);
    [self.userInfoController setFollowing:NO];
}

- (void)failedToQueryIfUser:(NSString *)username
    isFollowing:(NSString *)followee error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to query if %@ is following %@",
        username, followee);
    NSLog(@"Error: %@", error);
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.userquery", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, username];
    [self displayErrorWithTitle:errorMessage];
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
    [self displayErrorWithTitle:errorMessage];
    [self.lastTweetDetailsWrapperController setUpdatingState:kDisconnected];
}

#pragma mark TimelineViewControllerDelegate implementation

- (void)selectedTweet:(TweetInfo *)tweet
{
    // HACK: Release and then re-recreate the view for every tweet so the view
    // is properly scrolled to top when it appears. I have not been able to get
    // the view to scroll to top programmatically.
    [tweetDetailsController release];
    tweetDetailsController = nil;

    NSLog(@"Timeline display manager: selected tweet: %@", tweet);
    self.selectedTweet = tweet;

    BOOL tweetByUser = [tweet.user.username isEqual:credentials.username];
    self.tweetDetailsController.navigationItem.rightBarButtonItem.enabled =
        !tweetByUser;
    [self.tweetDetailsController setUsersTweet:tweetByUser];
    if (tweet.recipient) { // direct message
        UIBarButtonItem * rightBarButtonItem =
            [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self
            action:@selector(replyToTweetWithMessage)];
        self.tweetDetailsController.navigationItem.rightBarButtonItem =
            rightBarButtonItem;
        self.tweetDetailsController.navigationItem.title =
            NSLocalizedString(@"tweetdetailsview.title.directmessage", @"");
        [self.tweetDetailsController setUsersTweet:YES];
    } else {
        UIBarButtonItem * rightBarButtonItem =
            [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self
            action:@selector(presentTweetActions)];
        self.tweetDetailsController.navigationItem.rightBarButtonItem =
            rightBarButtonItem;
        self.tweetDetailsController.navigationItem.title =
            NSLocalizedString(@"tweetdetailsview.title", @"");
    }

    [self.tweetDetailsController hideFavoriteButton:NO];
    self.tweetDetailsController.showsExtendedActions = YES;
    [self.tweetDetailsController displayTweet:tweet
        onNavigationController:self.wrapperController.navigationController];
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
    // HACK: forces to scroll to top
    [userInfoController release];
    userInfoController = nil;
    self.userInfoController.navigationItem.title = aUser.username;
    [self.wrapperController.navigationController
        pushViewController:self.userInfoController animated:YES];
    self.userInfoController.followingEnabled =
        ![credentials.username isEqual:aUser.username];
    [self.userInfoController setUser:aUser];
    if (self.userInfoController.followingEnabled)
        [service isUser:credentials.username following:aUser.username];
}

- (void)showUserInfoForUsername:(NSString *)aUsername
{
    // HACK: forces to scroll to top
    // All dependencies must also be recreated
    [userInfoController release];
    userInfoController = nil;
    [userInfoControllerWrapper release];
    userInfoControllerWrapper = nil;
    [userInfoRequestAdapter release];
    userInfoRequestAdapter = nil;
    [userInfoTwitterService release];
    userInfoTwitterService = nil;

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

    [self.userInfoTwitterService fetchUserInfoForUsername:aUsername];
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

- (void)setFavorite:(BOOL)favorite
{
    if (favorite)
        NSLog(@"Timeline display manager: setting tweet to 'favorite'");
    else
        NSLog(@"Timeline display manager: setting tweet to 'not favorite'");

    [service markTweet:selectedTweet.identifier asFavorite:favorite];
}

- (void)replyToTweet
{
    NSLog(@"Timeline display manager: reply to tweet selected");
    [composeTweetDisplayMgr
        composeReplyToTweet:selectedTweet.identifier
        fromUser:selectedTweet.user.username];
}

- (void)presentTweetActions
{   
    [self presentTweetActionsForTarget:self.tweetDetailsController];
}

- (void)presentActionsForCurrentTweetDetailsUser
{
    NSLog(@"Presenting actions for current tweet details user");
    NetworkAwareViewController * topNetworkAwareViewController =
        (NetworkAwareViewController *)
        [wrapperController.navigationController topViewController];
    [self presentTweetActionsForTarget:
        topNetworkAwareViewController.targetViewController];
}

- (void)presentTweetActionsForTarget:(id)target
{
    NSString * cancel =
        NSLocalizedString(@"tweetdetailsview.actions.cancel", @"");
    NSString * browser =
        NSLocalizedString(@"tweetdetailsview.actions.browser", @"");
    NSString * email =
        NSLocalizedString(@"tweetdetailsview.actions.email", @"");

    UIActionSheet * sheet =
        [[UIActionSheet alloc]
        initWithTitle:nil delegate:target
        cancelButtonTitle:cancel destructiveButtonTitle:nil
        otherButtonTitles:browser, email, nil];

    // The alert sheet needs to be displayed in the UITabBarController's view.
    // If it's displayed in a child view, the action sheet will appear to be
    // modal on top of the tab bar, but it will not intercept any touches that
    // occur within the tab bar's bounds. Thus about 3/4 of the 'Cancel' button
    // becomes unusable. Reaching for the UITabBarController in this way is
    // definitely a hack, but fixes the problem for now.
    UIView * rootView =
        self.wrapperController.parentViewController.parentViewController.view;
    [sheet showInView:rootView];
}

- (void)showingTweetDetails
{
    NSLog(@"Timeline display manager: showing tweet details...");
    [self deallocateTweetDetailsNode];
}

- (void)sendDirectMessageToUser:(NSString *)username
{
    NSLog(@"Timeline display manager: sending direct message to %@", username);
    [composeTweetDisplayMgr composeDirectMessageTo:username];
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
}

#pragma mark UserInfoViewControllerDelegate implementation

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
    NSLog(@"Timeline display manager: visiting webpage: %@", webpageUrl);
    [self.wrapperController presentModalViewController:self.browserController
        animated:YES];
    [self.browserController setUrl:webpageUrl];
}

- (void)showPhotoInBrowser:(RemotePhoto *)remotePhoto
{
    NSLog(@"Timeline display manager: showing photo: %@", remotePhoto);

    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackTranslucent
        animated:YES];

    [self.wrapperController presentModalViewController:self.photoBrowser
        animated:YES];
    [self.photoBrowser addRemotePhoto:remotePhoto];
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
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
    } else
        NSLog(@"Timeline display manager: not updating due to nil credentials");
    [wrapperController setUpdatingState:kConnectedAndUpdating];
    [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
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

- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error
{
    NSLog(@"Timeline display manager: displaying error: %@", error);
    if (!failedState) {
        NSString * message = error.localizedDescription;
        UIAlertView * alertView =
            [UIAlertView simpleAlertViewWithTitle:title message:message];
        [alertView show];

        failedState = YES;
    }
    [self.wrapperController setUpdatingState:kDisconnected];
}

- (void)displayErrorWithTitle:(NSString *)title
{
    NSLog(@"Timeline display manager: displaying error with title: %@", title);

    UIAlertView * alertView =
        [UIAlertView simpleAlertViewWithTitle:title message:nil];
    [alertView show];
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

#pragma mark TwitchBrowserViewControllerDelegate implementation

- (void)composeTweetWithText:(NSString *)text
{
    NSLog(@"Timeline display manager: composing tweet with text'%@'", text);
    [composeTweetDisplayMgr composeTweetWithText:text];
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

        UIBarButtonItem * rightBarButton =
            [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self
            action:@selector(sendDirectMessageToCurrentUser)];
        userInfoController.navigationItem.rightBarButtonItem = rightBarButton;

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

        UIBarButtonItem * rightBarButton =
            [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self
            action:@selector(sendDirectMessageToCurrentUser)];
        userInfoControllerWrapper.navigationItem.rightBarButtonItem =
            rightBarButton;
    }

    return userInfoControllerWrapper;
}

- (UserInfoRequestAdapter *)userInfoRequestAdapter
{
    if (!userInfoRequestAdapter) {
        userInfoRequestAdapter =
            [[UserInfoRequestAdapter alloc]
            initWithTarget:self.userInfoController action:@selector(setUser:)
            wrapperController:self.userInfoControllerWrapper];
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

- (void)setService:(NSObject<TimelineDataSource> *)aTimelineSource
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
    forceRefresh:(BOOL)refresh allPagesLoaded:(BOOL)newAllPagesLoaded
{
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

    [self.timelineController.tableView
        scrollRectToVisible:self.timelineController.tableView.frame
        animated:NO];

    [timelineController setTweets:[timeline allValues] page:pagesShown
        visibleTweetId:nil];
    [timelineController setAllPagesLoaded:allPagesLoaded];

    if (refresh || [[someTweets allKeys] count] == 0)
        [self refreshWithCurrentPages];

    [self.wrapperController
        setCachedDataAvailable:[[someTweets allKeys] count] > 0];

    firstFetchReceived = !refresh;
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Timeline display manager: setting new credentials to: %@",
        someCredentials);

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
    } else if (hasBeenDisplayed) {// set for first time and persisted data shown
        NSLog(@"Timeline display manager: setting account for first time");
        [timelineSource fetchTimelineSince:[NSNumber numberWithInt:0]
            page:[NSNumber numberWithInt:pagesShown]];
    }

    [self.timelineController.tableView
        scrollRectToVisible:self.timelineController.tableView.frame
        animated:NO];
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

+ (NSInteger)retweetFormat
{
    if (!retweetFormatValueAlredyRead) {
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        retweetFormat = [defaults integerForKey:@"retweet_format"];
    }

    retweetFormatValueAlredyRead = YES;

    return retweetFormat;
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
            initWithAccountName:self.credentials.username
            context:managedObjectContext];

    return savedSearchMgr;
}

@end
