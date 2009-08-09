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

@interface TweetDetailsViewLoader : NSObject <UIWebViewDelegate>
{
    TweetInfo * tweetInfo;
    UIImage * avatar;
    TweetViewController * controller;
    UINavigationController * navigationController;

    UIWebView * webView;
}

@property (nonatomic, retain) TweetInfo * tweetInfo;
@property (nonatomic, retain) UIImage * avatar;
@property (nonatomic, retain) TweetViewController * controller;
@property (nonatomic, retain) UINavigationController * navigationController;

- (void)setTweet:(TweetInfo *)tweet avatar:(UIImage *)image
   intoController:(TweetViewController *)tvc
   navigationController:(UINavigationController *)navController;
@end

@implementation TweetDetailsViewLoader
@synthesize tweetInfo, avatar, controller, navigationController;

- (void)dealloc
{
    self.tweetInfo = nil;
    self.avatar = nil;
    self.controller = nil;
    self.navigationController = nil;
    [webView release];
    [super dealloc];
}

- (void)setTweet:(TweetInfo *)tweet avatar:(UIImage *)image
    intoController:(TweetViewController *)tvc
    navigationController:(UINavigationController *)navController
{
    self.tweetInfo = tweet;
    self.avatar = image;
    self.controller = tvc;
    self.navigationController = navController;

    CGRect frame = CGRectMake(5, 0, 290, 20);
    webView = [[UIWebView alloc] initWithFrame:frame];
    webView.delegate = self;
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    webView.dataDetectorTypes = UIDataDetectorTypeAll;

    // The view must be added as the subview of a visible view, otherwise the
    // height will not be calculated when -sizeToFit: is called. Adding it here
    // seems to have no effect on the display at all. Is there a better way to
    // do this?
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:webView];

    NSString * html = [self.tweetInfo textAsHtml];
    [webView loadHTMLStringRelativeToMainBundle:html];
}

#pragma mark UIWebViewDelegate implementation

- (void)webViewDidFinishLoad:(UIWebView *)view
{
    CGSize size = [webView sizeThatFits:CGSizeZero];

    CGRect frame = webView.frame;
    frame.size.width = size.width;
    frame.size.height = size.height;
    webView.frame = frame;

    if (navigationController)
        [navigationController pushViewController:controller animated:YES];
    [self.controller displayTweet:self.tweetInfo avatar:self.avatar
        withPreLoadedView:webView];

    [webView removeFromSuperview];
    [webView autorelease];
    webView = nil;
}

@end

@interface TimelineDisplayMgr ()

- (BOOL)cachedDataAvailable;
- (void)updateUserListViewWithUsers:(NSArray *)users page:(NSNumber *)page
    cache:(NSMutableDictionary *)cache;
- (void)deallocateTweetDetailsNode;
- (void)displayErrorWithTitle:(NSString *)title;
- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error;
- (void)replyToTweetWithMessage;
- (NetworkAwareViewController *)newTweetDetailsWrapperController;
//- (TweetDetailsViewController *)newTweetDetailsController;
- (TweetViewController *)newTweetDetailsController;
- (void)replyToCurrentTweetDetailsUser;
- (void)presentTweetActions;

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
    lastFollowingUsername, lastTweetDetailsWrapperController,
    lastTweetDetailsController, currentTweetDetailsUser, currentUsername,
    allPagesLoaded, setUserToAuthenticatedUser, firstFetchReceived,
    tweetIdToShow, suppressTimelineFailures, credentials, savedSearchMgr,
    currentSearch;

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

    [timelineSource release];
    [service release];

    [selectedTweet release];
    [currentUsername release];
    [user release];
    [timeline release];
    [updateId release];

    [followingUsers release];
    [followers release];
    [lastFollowingUsername release];

    [credentials release];

    [timelineDisplayMgrFactory release];
    [tweetDetailsTimelineDisplayMgr release];
    [tweetDetailsNetAwareViewController release];
    [managedObjectContext release];

    [userListNetAwareViewController release];
    [userListController release];

    [composeTweetDisplayMgr release];

    [savedSearchMgr release];
    [currentSearch release];

    [tweetDetailsViewLoader release];

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

        timeline = [[NSMutableDictionary dictionary] retain];
        followingUsers = [[NSMutableDictionary dictionary] retain];
        followers = [[NSMutableDictionary dictionary] retain];

        pagesShown = 1;
        followingUsersPagesShown = 1;
        followersPagesShown = 1;

        [wrapperController setUpdatingState:kConnectedAndUpdating];
        [wrapperController setCachedDataAvailable:NO];
        wrapperController.title = title;

        tweetDetailsViewLoader = [[TweetDetailsViewLoader alloc] init];
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

- (void)friends:(NSArray *)friends fetchedForUsername:(NSString *)username
    page:(NSNumber *)page
{
    NSLog(@"Timeline display manager received friends list of size %d",
        [friends count]);
    if (showingFollowing)
        [self updateUserListViewWithUsers:friends page:page
            cache:followingUsers];
}

- (void)failedToFetchFriendsForUsername:(NSString *)username
    page:(NSNumber *)page error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to fetch friends for %@",
        username);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchfriends", @"");
    [self displayErrorWithTitle:errorMessage error:error];
    [self.userListNetAwareViewController setUpdatingState:kDisconnected];
}

- (void)followers:(NSArray *)friends fetchedForUsername:(NSString *)username
    page:(NSNumber *)page
{
    NSLog(@"Timeline display manager received followers list of size %d",
        [friends count]);
    if (!showingFollowing)
        [self updateUserListViewWithUsers:friends page:page cache:followers];
}

- (void)failedToFetchFollowersForUsername:(NSString *)username
    page:(NSNumber *)page error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to fetch followers for %@",
        username);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchfollowers", @"");
    [self displayErrorWithTitle:errorMessage error:error];
    [self.userListNetAwareViewController setUpdatingState:kDisconnected];
}

- (void)updateUserListViewWithUsers:(NSArray *)users page:(NSNumber *)page
    cache:(NSMutableDictionary *)cache
{
    NSLog(@"Timeline display manager received user list of size %d",
        [users count]);
    NSInteger oldCacheSize = [[cache allKeys] count];
    for (User * friend in users)
        [cache setObject:friend forKey:friend.username];
    NSInteger newCacheSize = [[cache allKeys] count];
    BOOL allLoaded = oldCacheSize == newCacheSize;
    [self.userListController setAllPagesLoaded:allLoaded];
    [self.userListController setUsers:[cache allValues] page:[page intValue]];
    [self.userListNetAwareViewController setCachedDataAvailable:YES];
    [self.userListNetAwareViewController
        setUpdatingState:kConnectedAndNotUpdating];
    failedState = NO;
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

    // jad
    [tweetDetailsViewLoader setTweet:tweetInfo avatar:nil
        intoController:self.lastTweetDetailsController
        navigationController:nil];
    //[self.lastTweetDetailsController setTweet:tweetInfo avatar:nil];
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

- (void)selectedTweet:(TweetInfo *)tweet avatarImage:(UIImage *)avatarImage
{
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

    // jad
    [tweetDetailsViewLoader setTweet:tweet avatar:nil
        intoController:self.tweetDetailsController
        navigationController:self.wrapperController.navigationController];
    //[self.wrapperController.navigationController
    //  pushViewController:self.tweetDetailsController animated:YES];
    //[self.tweetDetailsController setTweet:tweet avatar:avatarImage];
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

- (void)showUserInfoWithAvatar:(UIImage *)avatar
{
    NSLog(@"Timeline display manager: showing user info for %@", user);
    userInfoController.navigationItem.title = user.name;
    [self.wrapperController.navigationController
        pushViewController:self.userInfoController animated:YES];
    self.userInfoController.followingEnabled =
        ![credentials.username isEqual:user.username];
    [self.userInfoController setUser:user avatarImage:avatar];
    if (self.userInfoController.followingEnabled)
        [service isUser:credentials.username following:user.username];
    // HACK: this is called twice to make sure it gets displayed the first time
    userInfoController.navigationItem.title = user.name;
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
    NSString * cancel =
        NSLocalizedString(@"tweetdetailsview.actions.cancel", @"");
    NSString * browser =
        NSLocalizedString(@"tweetdetailsview.actions.browser", @"");
    NSString * email =
        NSLocalizedString(@"tweetdetailsview.actions.email", @"");

    UIActionSheet * sheet =
        [[UIActionSheet alloc]
        initWithTitle:nil delegate:self.tweetDetailsController
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

    self.currentTweetDetailsUser = replyToUsername;

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

    [self.wrapperController.navigationController
        pushViewController:self.userListNetAwareViewController animated:YES];
    [self.userListController.tableView
        scrollRectToVisible:self.userListController.tableView.frame
        animated:NO];
    NSString * title =
        NSLocalizedString(@"userlisttableview.following.title", @"");
    self.userListNetAwareViewController.navigationItem.title = title;

    if (![username isEqual:lastFollowingUsername] || !showingFollowing) {
        [followingUsers removeAllObjects];
        followingUsersPagesShown = 1;

        [service fetchFriendsForUser:username
            page:[NSNumber numberWithInt:followingUsersPagesShown]];
        [self.userListNetAwareViewController setCachedDataAvailable:NO];
        [self.userListNetAwareViewController
            setUpdatingState:kConnectedAndUpdating];
    }

    self.lastFollowingUsername = username;
    showingFollowing = YES;
}

- (void)displayFollowersForUser:(NSString *)username
{
    NSLog(@"Timeline display manager: displaying 'followers' list for %@",
        username);

    [self.wrapperController.navigationController
        pushViewController:self.userListNetAwareViewController animated:YES];
    [self.userListController.tableView
        scrollRectToVisible:self.userListController.tableView.frame
        animated:NO];
    NSString * title =
        NSLocalizedString(@"userlisttableview.followers.title", @"");
    self.userListNetAwareViewController.navigationItem.title = title;

    if (![username isEqual:lastFollowingUsername] || showingFollowing) {
        [followers removeAllObjects];
        followersPagesShown = 1;

        [self.userListNetAwareViewController setCachedDataAvailable:NO];
        [self.userListNetAwareViewController
            setUpdatingState:kConnectedAndUpdating];
        [service fetchFollowersForUser:username
            page:[NSNumber numberWithInt:followersPagesShown]];
    }

    self.lastFollowingUsername = username;
    showingFollowing = NO;
}

- (void)displayFavoritesForUser:(NSString *)username
{
    NSLog(@"Timeline display manager: displaying favorites for user %@",
        username);
    // create a tweetDetailsTimelineDisplayMgr
    // push corresponding view controller for tweet details timeline display mgr
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

#pragma mark UserListTableViewControllerDelegate implementation

- (void)loadMoreUsers
{
    NSLog(@"Timeline display manager: loading more users...");
    if (showingFollowing)
        [service fetchFriendsForUser:user.username
            page:[NSNumber numberWithInt:++followingUsersPagesShown]];
    else
        [service fetchFollowersForUser:user.username
            page:[NSNumber numberWithInt:++followersPagesShown]];
    [self.userListNetAwareViewController
        setUpdatingState:kConnectedAndUpdating];
}

- (void)userListViewWillAppear
{
    NSLog(@"Timeline display manager: user list view will appear...");
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

- (void)replyToCurrentTweetDetailsUser
{
    NSLog(@"Timeline display manager: reply to tweet selected");
    [composeTweetDisplayMgr
        composeReplyToTweet:selectedTweet.identifier
        fromUser:self.currentTweetDetailsUser];
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
    NetworkAwareViewController * tweetDetailsWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:self.newTweetDetailsController]
        autorelease];

    UIBarButtonItem * replyButton =
        [[[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self
        action:@selector(replyToCurrentTweetDetailsUser)]
        autorelease];
    [tweetDetailsWrapperController.navigationItem
        setRightBarButtonItem:replyButton];

    NSString * title = NSLocalizedString(@"tweetdetailsview.title", @"");
    tweetDetailsWrapperController.navigationItem.title = title;

    return self.lastTweetDetailsWrapperController =
        tweetDetailsWrapperController;
}

//- (TweetDetailsViewController *)newTweetDetailsController
- (TweetViewController *)newTweetDetailsController
{
    /*
    TweetDetailsViewController * newTweetDetailsController =
        [[TweetDetailsViewController alloc]
        initWithNibName:@"TweetDetailsView" bundle:nil];

    newTweetDetailsController.delegate = self;

    return self.lastTweetDetailsController = newTweetDetailsController;
     */

    TweetViewController * newTweetViewController =
        [[TweetViewController alloc] initWithNibName:@"TweetView" bundle:nil];
    newTweetViewController.delegate = self;
    self.lastTweetDetailsController = newTweetViewController;
    [newTweetViewController release];

    return newTweetViewController;
}

//- (TweetDetailsViewController *)tweetDetailsController
- (TweetViewController *)tweetDetailsController
{
    if (!tweetDetailsController) {
        /*
        tweetDetailsController =
            [[TweetDetailsViewController alloc]
            initWithNibName:@"TweetDetailsView" bundle:nil];
         */

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

- (NetworkAwareViewController *)userListNetAwareViewController
{
    if (!userListNetAwareViewController) {
        userListNetAwareViewController =
            [[NetworkAwareViewController alloc]
            initWithTargetViewController:self.userListController];
    }

    return userListNetAwareViewController;
}

- (UserListTableViewController *)userListController
{
    if (!userListController) {
        userListController =
            [[UserListTableViewController alloc]
            initWithNibName:@"UserListTableView" bundle:nil];
        userListController.delegate = self;
    }

    return userListController;
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
