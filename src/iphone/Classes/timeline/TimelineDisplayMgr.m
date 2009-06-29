//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgr.h"
#import "TimelineDisplayMgrFactory.h"
#import "TwitterService.h"
#import "ArbUserTimelineDataSource.h"
#import "FavoritesTimelineDataSource.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface TimelineDisplayMgr ()

- (BOOL)cachedDataAvailable;
- (void)updateUserListViewWithUsers:(NSArray *)users page:(NSNumber *)page
    cache:(NSMutableDictionary *)cache;
- (void)deallocateTweetDetailsNode;
- (void)displayErrorWithTitle:(NSString *)title;
- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error;
- (void)replyToTweetWithMessage;
- (NetworkAwareViewController *)newTweetDetailsWrapperController;
- (TweetDetailsViewController *)newTweetDetailsController;
- (void)replyToCurrentTweetDetailsUser;

@end

@implementation TimelineDisplayMgr

@synthesize wrapperController, timelineController, userInfoController,
    selectedTweet, updateId, user, timeline, pagesShown, displayAsConversation,
    setUserToFirstTweeter, tweetDetailsTimelineDisplayMgr,
    tweetDetailsNetAwareViewController, tweetDetailsCredentialsPublisher,
    lastFollowingUsername, lastTweetDetailsWrapperController,
    lastTweetDetailsController, currentTweetDetailsUser, currentUsername;

- (void)dealloc
{
    [wrapperController release];
    [timelineController release];
    [lastTweetDetailsWrapperController release];
    [lastTweetDetailsController release];
    [tweetDetailsController release];

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

    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    timelineController:(TimelineViewController *)aTimelineController
    service:(NSObject<TimelineDataSource> *)aService title:(NSString *)title
    factory:(TimelineDisplayMgrFactory *)factory
    managedObjectContext:(NSManagedObjectContext* )aManagedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        timelineController = [aTimelineController retain];
        service = [aService retain];
        timelineDisplayMgrFactory = [factory retain];
        managedObjectContext = [aManagedObjectContext retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];

        timeline = [[NSMutableDictionary dictionary] retain];
        followingUsers = [[NSMutableDictionary dictionary] retain];
        followers = [[NSMutableDictionary dictionary] retain];

        pagesShown = 1;
        followingUsersPagesShown = 1;
        followersPagesShown = 1;

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
    NSLog(@"Timeline display manager received timeline of size %d", 
        [aTimeline count]);
    self.updateId = anUpdateId;
    NSInteger oldTimelineCount = [[timeline allKeys] count];
    for (TweetInfo * tweet in aTimeline)
        [timeline setObject:tweet forKey:tweet.identifier];
    NSInteger newTimelineCount = [[timeline allKeys] count];
    BOOL allLoaded =
        (!refreshingTweets && oldTimelineCount == newTimelineCount) ||
        newTimelineCount == 0;
    [timelineController setAllPagesLoaded:allLoaded];
    if (setUserToFirstTweeter) {
        timelineController.showWithoutAvatars = YES;
        if ([aTimeline count] > 0) {
            TweetInfo * firstTweet = [aTimeline objectAtIndex:0];
            [timelineController setUser:firstTweet.user];
            self.user = firstTweet.user;
        } else if (credentials)
            [service fetchUserInfoForUsername:self.currentUsername];
    }
    [timelineController setTweets:[timeline allValues] page:pagesShown];
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    [wrapperController setCachedDataAvailable:YES];
    refreshingTweets = NO;
    failedState = NO;
}

- (void)failedToFetchTimelineSinceUpdateId:(NSNumber *)anUpdateId
    page:(NSNumber *)page error:(NSError *)error
{
    NSLog(@"Timeline display manager: failed to fetch timeline since %@",
        anUpdateId);
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchtimeline", @"");
    [self displayErrorWithTitle:errorMessage error:error];
}

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
    NSLog(@"Timeline display mgr: fetched tweet %@", tweetId);
    TweetInfo * tweetInfo = [TweetInfo createFromTweet:tweet];

    [self.lastTweetDetailsController setTweet:tweetInfo avatar:nil];
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

    self.tweetDetailsController.navigationItem.rightBarButtonItem.enabled =
        ![tweet.user.username isEqual:credentials.username];
    if (tweet.recipient) {
        self.tweetDetailsController.navigationItem.rightBarButtonItem.action =
            @selector(replyToTweetWithMessage);
        self.tweetDetailsController.navigationItem.title =
            NSLocalizedString(@"tweetdetailsview.title.directmessage", @"");
    } else {
        self.tweetDetailsController.navigationItem.rightBarButtonItem.action =
            @selector(replyToTweet);
        self.tweetDetailsController.navigationItem.title =
            NSLocalizedString(@"tweetdetailsview.title", @"");
    }
    
    [self.wrapperController.navigationController
        pushViewController:self.tweetDetailsController animated:YES];
    [self.tweetDetailsController setTweet:tweet avatar:avatarImage];
}

- (void)loadMoreTweets
{
    NSLog(@"Timeline display manager: loading more tweets...");
    if ([service credentials])
        [service fetchTimelineSince:[NSNumber numberWithInt:0]
            page:[NSNumber numberWithInt:++pagesShown]];
    [wrapperController setUpdatingState:kConnectedAndUpdating];
    [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
}

- (void)showUserInfoWithAvatar:(UIImage *)avatar
{
    NSLog(@"Timeline display manager: showing user info for %@", user);
    [self.wrapperController.navigationController
        pushViewController:self.userInfoController animated:YES];
    self.userInfoController.followingEnabled =
        ![credentials.username isEqual:user.username];
    [self.userInfoController setUser:user avatarImage:avatar];
    if (self.userInfoController.followingEnabled)
        [service isUser:credentials.username following:user.username];
}

#pragma mark TweetDetailsViewDelegate implementation

- (void)showTweetsForUser:(NSString *)username
{
    NSLog(@"Timeline display manager: showing tweets for %@", username);
    // create a tweetDetailsTimelineDisplayMgr
    // push corresponding view controller for tweet details timeline display mgr
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
        [[UIBarButtonItem alloc] initWithTitle:@"Message"
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
        forceRefresh:NO];
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
    if ((!hasBeenDisplayed && [service credentials]) || needsRefresh) {
        NSLog(@"Timeline display manager: fetching new timeline when shown...");
        [service fetchTimelineSince:[NSNumber numberWithInt:0]
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
        title:title managedObjectContext:managedObjectContext
        composeTweetDisplayMgr:composeTweetDisplayMgr];
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
        forceRefresh:NO];
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
    if([service credentials]) {
        refreshingTweets = YES;
        [service fetchTimelineSince:self.updateId
            page:[NSNumber numberWithInt:0]];
    }
    [wrapperController setUpdatingState:kConnectedAndUpdating];
    [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
}

- (void)refreshWithCurrentPages
{
    if([service credentials]) {
        refreshingTweets = YES;
        hasBeenDisplayed = YES;
        [service fetchTimelineSince:[NSNumber numberWithInt:0] page:
        [NSNumber numberWithInt:pagesShown]];
    }
    [wrapperController setUpdatingState:kConnectedAndUpdating];
    [wrapperController setCachedDataAvailable:[self cachedDataAvailable]];
}

- (void)addTweet:(Tweet *)tweet displayImmediately:(BOOL)displayImmediately
{
    TweetInfo * info = [TweetInfo createFromTweet:tweet];
    [timeline setObject:info forKey:info.identifier];

    if (displayImmediately)
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

- (TweetDetailsViewController *)newTweetDetailsController
{
    TweetDetailsViewController * newTweetDetailsController =
        [[TweetDetailsViewController alloc]
        initWithNibName:@"TweetDetailsView" bundle:nil];

    newTweetDetailsController.delegate = self;

    return self.lastTweetDetailsController = newTweetDetailsController;
}

- (TweetDetailsViewController *)tweetDetailsController
{
    if (!tweetDetailsController) {
        tweetDetailsController =
            [[TweetDetailsViewController alloc]
            initWithNibName:@"TweetDetailsView" bundle:nil];

        UIBarButtonItem * replyButton =
            [[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self
            action:@selector(replyToTweet)]
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

        NSString * title = NSLocalizedString(@"userinfoview.title", @"");
        userInfoController.navigationItem.title = title;

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
    }

    return browserController;
}

- (void)setService:(NSObject<TimelineDataSource> *)aService
    tweets:(NSDictionary *)someTweets page:(NSUInteger)page
    forceRefresh:(BOOL)refresh
{
    [aService retain];
    [service release];
    service = aService;

    // in case in the middle of updating while switched
    [self.wrapperController setUpdatingState:kConnectedAndNotUpdating];

    [timeline removeAllObjects];
    [timeline addEntriesFromDictionary:someTweets];

    pagesShown = page;

    [aService setCredentials:credentials];

    [self.timelineController.tableView
        scrollRectToVisible:self.timelineController.tableView.frame
        animated:NO];

    [timelineController setTweets:[timeline allValues] page:pagesShown];

    if (refresh || [[someTweets allKeys] count] == 0)
        [self refreshWithCurrentPages];

    [self.wrapperController
        setCachedDataAvailable:[[someTweets allKeys] count] > 0];
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

    [service setCredentials:credentials];

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

        // if we're currently displaying direct messages for the current user
        // set the username to match the new credentials
        if (self.timelineController.segregatedSenderUsername)
            [self.timelineController
                setSegregateTweetsFromUser:credentials.username];
            
        [self.wrapperController setCachedDataAvailable:NO];
        [self.wrapperController setUpdatingState:kConnectedAndUpdating];
    } else if (hasBeenDisplayed) {// set for first time and persisted data shown
        NSLog(@"Timeline display manager: setting account for first time");
        [service fetchTimelineSince:[NSNumber numberWithInt:0]
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

- (void)setShowInboxOutbox:(BOOL)show
{
    if (show) {
        NSLog(@"Showing as inbox/outbox; username: %@", credentials.username);
        [self.timelineController
            setSegregateTweetsFromUser:credentials.username];
    } else {
        NSLog(@"Not showing as inbox/outbox; username: %@",
            credentials.username);
        [self.timelineController setSegregateTweetsFromUser:nil];
    }
}

@end
