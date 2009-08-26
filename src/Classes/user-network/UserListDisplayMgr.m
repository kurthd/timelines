//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserListDisplayMgr.h"
#import "ArbUserTimelineDataSource.h"
#import "FavoritesTimelineDataSource.h"
#import "ErrorState.h"
#import "SearchDataSource.h"

@interface UserListDisplayMgr ()

@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain) UserListDisplayMgr * nextUserListDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * nextWrapperController;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * credentialsPublisher;
@property (readonly) UserInfoViewController * userInfoController;
@property (nonatomic, copy) NSString * userInfoUsername;
@property (nonatomic, copy) NSString * currentSearch;
@property (nonatomic, retain) SavedSearchMgr * savedSearchMgr;

@property (nonatomic, readonly)
    LocationMapViewController * locationMapViewController;
@property (nonatomic, readonly)
    LocationInfoViewController * locationInfoViewController;

- (void)deallocateNode;
- (void)updateUserListViewWithUsers:(NSArray *)users page:(NSNumber *)page;
- (void)sendDirectMessageToCurrentUser;
- (void)removeSearch:(id)sender;
- (void)saveSearch:(id)sender;
- (UIView *)saveSearchView;
- (UIView *)removeSearchView;
- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title
    action:(SEL)action;

@end

@implementation UserListDisplayMgr

@synthesize timelineDisplayMgr, nextUserListDisplayMgr, nextWrapperController,
    credentialsPublisher, userInfoUsername, currentSearch, savedSearchMgr;

- (void)dealloc
{
    [wrapperController release];
    [userListController release];
    [service release];
    [userListDisplayMgrFactory release];
    [timelineDisplayMgrFactory release];
    [context release];
    [composeTweetDisplayMgr release];
    [findPeopleBookmarkMgr release];
    [username release];

    [timelineDisplayMgr release];
    [nextUserListDisplayMgr release];
    [nextWrapperController release];
    [credentialsPublisher release];
    [credentials release];
    [cache release];
    [userInfoController release];
    [currentSearch release];
    [savedSearchMgr release];

    [locationMapViewController release];
    [locationInfoViewController release];

    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    userListController:(UserListTableViewController *)aUserListController
    service:(TwitterService *)aService
    factory:(UserListDisplayMgrFactory *)userListFactory
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr
    showFollowing:(BOOL)showFollowingValue username:(NSString *)aUsername
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        userListController = [aUserListController retain];
        service = [aService retain];

        userListDisplayMgrFactory = [userListFactory retain];
        timelineDisplayMgrFactory = [timelineFactory retain];
        context = [managedObjectContext retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        findPeopleBookmarkMgr = [aFindPeopleBookmarkMgr retain];
        showFollowing = showFollowingValue;
        username = [aUsername retain];

        pagesShown = 1;
        failedState = NO;
        cache = [[NSMutableDictionary dictionary] retain];

        NSString * title =
            showFollowing ? 
            NSLocalizedString(@"userlisttableview.following.title", @"") :
            NSLocalizedString(@"userlisttableview.followers.title", @"");
        wrapperController.navigationItem.title = title;
    }

    return self;
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    if (!alreadyBeenDisplayed) {
        NSLog(@"Showing user list for first time");
        if (showFollowing) {
            NSLog(@"Querying for friends list");
            [service fetchFriendsForUser:username
                page:[NSNumber numberWithInt:pagesShown]];
        } else {
            NSLog(@"Querying for followers list");
            [service fetchFollowersForUser:username
                page:[NSNumber numberWithInt:pagesShown]];
        }

        [wrapperController setUpdatingState:kConnectedAndUpdating];
        alreadyBeenDisplayed = YES;
    }
}

#pragma mark UserListTableViewControllerDelegate implementation

- (void)showUserInfoForUser:(User *)aUser
{
    self.userInfoUsername = aUser.username;
    [userInfoController release];
    userInfoController = nil; // Forces to scroll to top
    self.userInfoController.navigationItem.title = aUser.username;
    [wrapperController.navigationController
        pushViewController:self.userInfoController animated:YES];
    self.userInfoController.followingEnabled =
        ![credentials.username isEqual:aUser.username];
    [self.userInfoController setUser:aUser];
    if (self.userInfoController.followingEnabled)
        [service isUser:credentials.username following:aUser.username];
}

- (void)loadMoreUsers
{
    // Screw polymorphism -- too much work
    if (showFollowing)
        [service fetchFriendsForUser:username
            page:[NSNumber numberWithInt:++pagesShown]];
    else
        [service fetchFollowersForUser:username
            page:[NSNumber numberWithInt:++pagesShown]];

    [wrapperController setUpdatingState:kConnectedAndUpdating];
}

- (void)userListViewWillAppear
{
    [self deallocateNode];
}

#pragma mark TwitterServiceDelegate implementation

- (void)startedFollowingUsername:(NSString *)aUsername
{
    NSLog(@"Started following %@", aUsername);
    [userInfoController setFollowing:YES];
}

- (void)failedToStartFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.startfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, aUsername];
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)stoppedFollowingUsername:(NSString *)aUsername
{
    NSLog(@"Stopped following %@", aUsername);
    [userInfoController setFollowing:NO];
}

- (void)failedToStopFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.stopfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, aUsername];
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)friends:(NSArray *)friends fetchedForUsername:(NSString *)username
    page:(NSNumber *)page
{
    NSLog(@"Received friends list of size %d", [friends count]);
    if (showFollowing)
        [self updateUserListViewWithUsers:friends page:page];
}

- (void)failedToFetchFriendsForUsername:(NSString *)aUsername
    page:(NSNumber *)page error:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchfriends", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
    [wrapperController setUpdatingState:kDisconnected];
}

- (void)followers:(NSArray *)friends fetchedForUsername:(NSString *)aUsername
    page:(NSNumber *)page
{
    NSLog(@"Received followers list of size %d", [friends count]);
    if (!showFollowing)
        [self updateUserListViewWithUsers:friends page:page];
}

- (void)failedToFetchFollowersForUsername:(NSString *)aUsername
    page:(NSNumber *)page error:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchfollowers", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
    [wrapperController setUpdatingState:kDisconnected];
}

- (void)user:(NSString *)aUsername isFollowing:(NSString *)followee
{
    NSLog(@"%@ is following %@", aUsername, followee);
    [self.userInfoController setFollowing:YES];
}

- (void)user:(NSString *)aUsername isNotFollowing:(NSString *)followee
{
    NSLog(@"%@ is not following %@", aUsername, followee);
    [self.userInfoController setFollowing:NO];
}

- (void)failedToQueryIfUser:(NSString *)aUsername
    isFollowing:(NSString *)followee error:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.followingstatus", @"");

    [self.userInfoController setFailedToQueryFollowing];

    [self.userInfoController setFollowing:NO];
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

#pragma mark UserInfoViewControllerDelegate implementation

- (void)showTweetsForUser:(NSString *)aUsername
{
    NSLog(@"Timeline display manager: showing tweets for %@", aUsername);

    NSString * title =
        NSLocalizedString(@"timelineview.usertweets.title", @"");
    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.timelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:self.nextWrapperController
        title:title composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.timelineDisplayMgr.displayAsConversation = NO;
    self.timelineDisplayMgr.setUserToFirstTweeter = YES;
    [self.timelineDisplayMgr setTimelineHeaderView:nil];
    self.timelineDisplayMgr.currentUsername = aUsername;
    [self.timelineDisplayMgr setCredentials:credentials];
    
    UIBarButtonItem * sendDMButton =
        [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
        target:self.timelineDisplayMgr
        action:@selector(sendDirectMessageToCurrentUser)];
    
    self.nextWrapperController.navigationItem.rightBarButtonItem = sendDMButton;

    wrapperController.delegate = self.timelineDisplayMgr;
    
    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context] autorelease];
    
    ArbUserTimelineDataSource * dataSource =
        [[[ArbUserTimelineDataSource alloc]
        initWithTwitterService:twitterService
        username:aUsername]
        autorelease];
    
    self.credentialsPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];
    
    twitterService.delegate = dataSource;
    [self.timelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO allPagesLoaded:NO];
    dataSource.delegate = self.timelineDisplayMgr;

    [dataSource setCredentials:credentials];
    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)showLocationOnMap:(NSString *)locationString
{
    NSLog(@"User list display manager: showing %@ on map", locationString);

    self.locationMapViewController.navigationItem.title = @"Map";
    
    [wrapperController.navigationController
        pushViewController:self.locationMapViewController animated:YES];

    [self.locationMapViewController setLocation:locationString];
}

- (void)showLocationInfo:(NSString *)locationString
    coordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"User list display manager: showing location info for %@",
        locationString);

    [wrapperController.navigationController
        pushViewController:self.locationInfoViewController animated:YES];

    [self.locationInfoViewController setLocationString:locationString
        coordinate:coordinate];
}

- (void)displayFollowingForUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: displaying 'following' list for %@",
        aUsername);

    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.nextUserListDisplayMgr =
        [userListDisplayMgrFactory
        createUserListDisplayMgrWithWrapperController:
        self.nextWrapperController
        composeTweetDisplayMgr:composeTweetDisplayMgr
        showFollowing:YES
        username:aUsername];
    [self.nextUserListDisplayMgr setCredentials:credentials];

    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)displayFollowersForUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: displaying 'followers' list for %@",
        aUsername);

    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.nextUserListDisplayMgr =
        [userListDisplayMgrFactory
        createUserListDisplayMgrWithWrapperController:
        self.nextWrapperController
        composeTweetDisplayMgr:composeTweetDisplayMgr
        showFollowing:NO
        username:aUsername];
    [self.nextUserListDisplayMgr setCredentials:credentials];

    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)displayFavoritesForUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: displaying favorites for user %@",
        aUsername);
    NSString * title =
        NSLocalizedString(@"timelineview.favorites.title", @"");
    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.timelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:nextWrapperController
        title:title composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.timelineDisplayMgr.displayAsConversation = YES;
    self.timelineDisplayMgr.setUserToFirstTweeter = NO;
    [self.timelineDisplayMgr setCredentials:credentials];

    self.nextWrapperController.delegate = self.timelineDisplayMgr;

    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil context:context]
        autorelease];

    FavoritesTimelineDataSource * dataSource =
        [[[FavoritesTimelineDataSource alloc]
        initWithTwitterService:twitterService username:aUsername]
        autorelease];

    self.credentialsPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];

    twitterService.delegate = dataSource;
    [self.timelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO allPagesLoaded:NO];
    dataSource.delegate = self.timelineDisplayMgr;

    [dataSource setCredentials:credentials];
    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)startFollowingUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: sending 'follow user' request for %@",
        aUsername);
    [service followUser:aUsername];
}

- (void)stopFollowingUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: sending 'stop following' request for %@",
        aUsername);
    [service stopFollowingUser:aUsername];
}

- (void)showingUserInfoView
{
    // do nothing
}

- (void)sendDirectMessageToUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: sending direct message to %@",
        aUsername);
    [composeTweetDisplayMgr composeDirectMessageTo:aUsername];
}

- (void)sendPublicMessageToUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: sending public message to %@",
        aUsername);
    [composeTweetDisplayMgr
        composeTweetWithText:[NSString stringWithFormat:@"@%@ ", aUsername]];
}

- (void)showResultsForSearch:(NSString *)query
{
    NSLog(@"User list display manager: showing search results for '%@'", query);
    self.currentSearch = query;
    
    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];
    
    self.timelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        self.nextWrapperController
        title:query composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.timelineDisplayMgr.displayAsConversation = NO;
    self.timelineDisplayMgr.setUserToFirstTweeter = NO;
    self.timelineDisplayMgr.currentUsername = nil;
    UIView * headerView =
        [self.savedSearchMgr isSearchSaved:query] ?
        [self removeSearchView] : [self saveSearchView];
    [self.timelineDisplayMgr setTimelineHeaderView:headerView];
    [self.timelineDisplayMgr setCredentials:credentials];
    self.nextWrapperController.navigationItem.rightBarButtonItem = nil;
    
    self.nextWrapperController.delegate = self.timelineDisplayMgr;
    
    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];
    
    SearchDataSource * dataSource =
        [[[SearchDataSource alloc]
        initWithTwitterService:twitterService
        query:query]
        autorelease];
    
    self.credentialsPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];
    
    twitterService.delegate = dataSource;
    [self.timelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO allPagesLoaded:NO];
    dataSource.delegate = self.timelineDisplayMgr;
    
    [dataSource setCredentials:credentials];
    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

#pragma mark TwitchBrowserViewControllerDelegate implementation

- (void)composeTweetWithText:(NSString *)text
{
    NSLog(@"Timeline display manager: composing tweet with text'%@'", text);
    [composeTweetDisplayMgr composeTweetWithText:text];
}

#pragma mark UserListDisplayMgr implementation

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"User list display manager: setting credentials: %@",
        someCredentials.username);

    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:someCredentials];

    self.savedSearchMgr.accountName = credentials.username;
}

- (void)refreshWithCurrentPages
{
    NSLog(@"User list display manager: refreshing with current pages...");
    if([service credentials] && username) {
        alreadyBeenDisplayed = YES;
        if (showFollowing)
            [service fetchFriendsForUser:username
                page:[NSNumber numberWithInt:pagesShown]];
        else
            [service fetchFollowersForUser:username
                page:[NSNumber numberWithInt:pagesShown]];
    } else
        NSLog(@"User list display manager: not updating - nil credentials");
    [wrapperController setUpdatingState:kConnectedAndUpdating];
}

#pragma mark Private helper methods

- (void)deallocateNode
{
    self.timelineDisplayMgr = nil;
    self.nextUserListDisplayMgr = nil;
    self.nextWrapperController = nil;
    self.credentialsPublisher = nil;
    self.currentSearch = nil;
}

- (void)updateUserListViewWithUsers:(NSArray *)users page:(NSNumber *)page
{
    NSLog(@"Received user list of size %d", [users count]);
    NSInteger oldCacheSize = [[cache allKeys] count];
    for (User * friend in users)
        [cache setObject:friend forKey:friend.username];
    NSInteger newCacheSize = [[cache allKeys] count];
    BOOL allLoaded = oldCacheSize == newCacheSize;
    [userListController setAllPagesLoaded:allLoaded];
    [userListController setUsers:[cache allValues] page:[page intValue]];
    [wrapperController setCachedDataAvailable:YES];
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    failedState = NO;
}

- (UserInfoViewController *)userInfoController
{
    if (!userInfoController) {
        userInfoController =
            [[UserInfoViewController alloc]
            initWithNibName:@"UserInfoView" bundle:nil];

        userInfoController.findPeopleBookmarkMgr = findPeopleBookmarkMgr;
        userInfoController.delegate = self;
    }

    return userInfoController;
}

- (void)sendDirectMessageToCurrentUser
{
    NSLog(@"User list display manager: sending direct message to %@",
        self.userInfoUsername);
    [composeTweetDisplayMgr composeDirectMessageTo:self.userInfoUsername];
}

- (void)removeSearch:(id)sender
{
    [self.timelineDisplayMgr
        setTimelineHeaderView:[self saveSearchView]];
    [self.savedSearchMgr removeSavedSearchForQuery:self.currentSearch];
}

- (void)saveSearch:(id)sender
{
    [self.timelineDisplayMgr
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
            initWithAccountName:credentials.username context:context];

    return savedSearchMgr;
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

@end
