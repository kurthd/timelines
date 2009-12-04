//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ProfileDisplayMgr.h"
#import "ErrorState.h"
#import "SettingsReader.h"
#import "NearbySearchDataSource.h"
#import "FavoritesTimelineDataSource.h"
#import "ArbUserTimelineDataSource.h"
#import "SearchDataSource.h"
#import "RecentSearchMgr.h"
#import "RotatableTabBarController.h"
#import "UIColor+TwitchColors.h"

@interface ProfileDisplayMgr ()

- (void)fetchUserInfo;

- (void)removeSearch:(id)sender;
- (void)saveSearch:(id)sender;
- (UIView *)saveSearchView;
- (UIView *)removeSearchView;
- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title action:(SEL)action;

@property (nonatomic, copy) NSString * username;

@property (nonatomic, retain)
    NetworkAwareViewController * nextWrapperController;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * credentialsPublisher;
@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain) UserListDisplayMgr * nextUserListDisplayMgr;

@property (nonatomic, readonly)
    LocationMapViewController * locationMapViewController;
@property (nonatomic, readonly)
    LocationInfoViewController * locationInfoViewController;
    
@property (nonatomic, retain) NSString * currentSearch;
@property (nonatomic, retain) SavedSearchMgr * generalSavedSearchMgr;
@property (nonatomic, retain) RecentSearchMgr * recentSearchMgr;

@end

@implementation ProfileDisplayMgr

@synthesize username;
@synthesize nextWrapperController, credentialsPublisher, timelineDisplayMgr,
    nextUserListDisplayMgr;
@synthesize currentSearch, generalSavedSearchMgr, recentSearchMgr;

- (void)dealloc
{
    [netAwareController release];
    [userInfoController release];
    [service release];
    [userListDisplayMgr release];
    [timelineDisplayMgrFactory release];
    [userListDisplayMgrFactory release];
    [context release];
    [composeTweetDisplayMgr release];
    [navigationController release];

    [username release];

    [nextWrapperController release];
    [credentialsPublisher release];
    [timelineDisplayMgr release];
    [nextUserListDisplayMgr release];

    [locationMapViewController release];
    [locationInfoViewController release];

    [currentSearch release];
    [generalSavedSearchMgr release];
    [recentSearchMgr release];

    [super dealloc];
}

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    userInfoController:(UserInfoViewController *)aUserInfoController
    service:(TwitterService *)aService
    context:(NSManagedObjectContext *)aContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    userListFactory:(UserListDisplayMgrFactory *)aUserListFactory
    navigationController:(UINavigationController *)aNavigationController
{
    if (self = [super init]) {
        netAwareController = [navc retain];
        userInfoController = [aUserInfoController retain];
        service = [aService retain];
        context = [aContext retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        timelineDisplayMgrFactory = [timelineFactory retain];
        userListDisplayMgrFactory = [aUserListFactory retain];
        navigationController = [aNavigationController retain];
    }

    return self;
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    NSLog(@"Profile view will appear");
    if (!freshProfile)
        [self fetchUserInfo];
}

#pragma mark TwitterServiceDelegate implementation

- (void)userInfo:(User *)user fetchedForUsername:(NSString *)aUsername
{
    NSLog(@"Fetched user info for '%@'", aUsername);

    if ([self.username isEqual:aUsername]) {
        [netAwareController setUpdatingState:kConnectedAndNotUpdating];
        [netAwareController setCachedDataAvailable:YES];

        // this forces the tableview to scroll to top
        [userInfoController.tableView setContentOffset:CGPointMake(0, 300)
            animated:NO];

        [userInfoController setUser:user];
        freshProfile = YES;
    }
}

- (void)failedToFetchUserInfoForUsername:(NSString *)aUsername
    error:(NSError *)error
{
    if ([aUsername isEqual:self.username]) {
        NSLog(@"Failed to fetch user info for user '%@'", aUsername);
        NSLog(@"Error: %@", error);
        NSString * errorMessageFormatString =
            NSLocalizedString(@"profiledisplaymgr.error", @"");
        NSString * errorMessage =
            [NSString stringWithFormat:errorMessageFormatString, aUsername];
        [[ErrorState instance] displayErrorWithTitle:errorMessage error:error
            retryTarget:self retryAction:@selector(refreshLists)];
        [netAwareController setUpdatingState:kDisconnected];
    }
}

- (void)startedFollowingUsername:(NSString *)username
{

}

- (void)failedToStartFollowingUsername:(NSString *)username
    error:(NSError *)error
{
    
}

- (void)stoppedFollowingUsername:(NSString *)username
{
    
}

- (void)failedToStopFollowingUsername:(NSString *)username
    error:(NSError *)error
{
    
}

#pragma mark UserInfoViewControllerDelegate implementation

- (void)showLocationOnMap:(NSString *)locationString
{
    NSLog(@"Profile display manager: showing %@ on map", locationString);

    self.locationMapViewController.navigationItem.title = @"Map";

    [netAwareController.navigationController
        pushViewController:self.locationMapViewController animated:YES];

    [self.locationMapViewController setLocation:locationString];
}

- (void)displayFollowingForUser:(NSString *)aUsername
{
    NSLog(@"Displaying 'following' list for %@", aUsername);

    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.nextUserListDisplayMgr =
        [userListDisplayMgrFactory
        createUserListDisplayMgrWithWrapperController:
        self.nextWrapperController
        navigationController:netAwareController.navigationController
        composeTweetDisplayMgr:composeTweetDisplayMgr
        showFollowing:YES
        username:aUsername];
    [self.nextUserListDisplayMgr setCredentials:credentials];

    [netAwareController.navigationController
        pushViewController:self.nextWrapperController animated:YES];    
}

- (void)displayFollowersForUser:(NSString *)aUsername
{
    NSLog(@"Displaying 'followers' list for %@", aUsername);

    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.nextUserListDisplayMgr =
        [userListDisplayMgrFactory
        createUserListDisplayMgrWithWrapperController:
        self.nextWrapperController
        navigationController:netAwareController.navigationController
        composeTweetDisplayMgr:composeTweetDisplayMgr
        showFollowing:NO
        username:aUsername];
    [self.nextUserListDisplayMgr setCredentials:credentials];

    [netAwareController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)displayFavoritesForUser:(NSString *)aUsername
{
    NSLog(@"Displaying favorites for user %@", aUsername);
    NSString * title =
        NSLocalizedString(@"timelineview.favorites.title", @"");
    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.timelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:nextWrapperController
        navigationController:netAwareController.navigationController
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
    [netAwareController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)showTweetsForUser:(NSString *)aUsername
{
    NSLog(@"Showing tweets for %@", aUsername);

    NSString * title =
        NSLocalizedString(@"timelineview.usertweets.title", @"");
    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];
    
    self.timelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:self.nextWrapperController
        navigationController:netAwareController.navigationController
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

    self.nextWrapperController.delegate = self.timelineDisplayMgr;
    
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
    [netAwareController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)startFollowingUser:(NSString *)aUsername
{
    // Don't need
}

- (void)stopFollowingUser:(NSString *)aUsername
{
    // Don't need
}

- (void)blockUser:(NSString *)aUsername
{
    // Don't need
}

- (void)unblockUser:(NSString *)aUsername
{
    // Don't need
}

- (void)showingUserInfoView
{
    self.nextWrapperController = nil;
    self.timelineDisplayMgr = nil;
    self.credentialsPublisher = nil;
    self.nextUserListDisplayMgr = nil;
}

- (void)sendDirectMessageToUser:(NSString *)aUsername
{
    [composeTweetDisplayMgr composeDirectMessageTo:aUsername animated:YES];
}

- (void)sendPublicMessageToUser:(NSString *)aUsername
{
    [composeTweetDisplayMgr
        composeTweetWithText:[NSString stringWithFormat:@"@%@ ", aUsername]
        animated:YES];
}

- (void)showResultsForSearch:(NSString *)query
{
    NSLog(@"Showing search results for '%@'", query);
    self.currentSearch = query;

    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];
    
    self.timelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:nextWrapperController
        navigationController:netAwareController.navigationController
        title:query composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.timelineDisplayMgr.displayAsConversation = NO;
    self.timelineDisplayMgr.setUserToFirstTweeter = NO;
    self.timelineDisplayMgr.currentUsername = nil;
    UIView * headerView =
        [self.generalSavedSearchMgr isSearchSaved:query] ?
        [self removeSearchView] : [self saveSearchView];
    [self.timelineDisplayMgr setTimelineHeaderView:headerView];
    [self.timelineDisplayMgr setCredentials:credentials];
    self.nextWrapperController.navigationItem.rightBarButtonItem = nil;
    
    self.nextWrapperController.delegate = self.timelineDisplayMgr;
    
    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil context:context]
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
    [netAwareController.navigationController
        pushViewController:self.nextWrapperController
        animated:YES];
}

#pragma mark LocationMapViewControllerDelegate implementation

- (void)showLocationInfo:(NSString *)locationString
    coordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"Showing location info for %@", locationString);

    [netAwareController.navigationController
        pushViewController:self.locationInfoViewController animated:YES];

    [self.locationInfoViewController setLocationString:locationString
        coordinate:coordinate];
}

#pragma mark LocationInfoViewControllerDelegate implementation

- (void)showResultsForNearbySearchWithLatitude:(NSNumber *)latitude
    longitude:(NSNumber *)longitude
{
    NSLog(@"Showing results for nearby search");
    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    NSString * title =
        NSLocalizedString(@"timelinedisplaymgr.nearbysearch", @"");
    self.timelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:nextWrapperController
        navigationController:netAwareController.navigationController
        title:title composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.timelineDisplayMgr.displayAsConversation = NO;
    self.timelineDisplayMgr.setUserToFirstTweeter = NO;
    self.timelineDisplayMgr.currentUsername = nil;

    [self.timelineDisplayMgr setCredentials:credentials];
    self.nextWrapperController.navigationItem.rightBarButtonItem =
        nil;

    self.nextWrapperController.delegate = self.timelineDisplayMgr;

    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil context:context]
        autorelease];

    NSNumber * radius =
        [NSNumber numberWithInt:[SettingsReader nearbySearchRadius]];

    NearbySearchDataSource * dataSource =
        [[[NearbySearchDataSource alloc]
        initWithTwitterService:twitterService
        latitude:latitude longitude:longitude radiusInKm:radius]
        autorelease];

    self.credentialsPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];

    twitterService.delegate = dataSource;
    [self.timelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO allPagesLoaded:NO];
    dataSource.delegate = self.timelineDisplayMgr;

    [dataSource setCredentials:credentials];
    [netAwareController.navigationController
        pushViewController:self.nextWrapperController
        animated:YES];
}

#pragma mark ProfileDisplayMgr implementation

- (void)setNewProfileUsername:(NSString *)aUsername user:(User *)user
{
    freshProfile = NO;
    self.username = aUsername;
    [netAwareController setCachedDataAvailable:!!user];
}

- (void)refreshProfile
{
    [[ErrorState instance] exitErrorState];
    [self fetchUserInfo];
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;
}

#pragma mark Private helper methods

- (void)fetchUserInfo
{
    if (self.username) {
        [netAwareController setUpdatingState:kConnectedAndUpdating];
        [service fetchUserInfoForUsername:self.username];
    }
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

- (RecentSearchMgr *)recentSearchMgr
{
    if (!recentSearchMgr)
        recentSearchMgr =
            [[RecentSearchMgr alloc] initWithAccountName:@"recent.people"
            context:context];

    return recentSearchMgr;
}

- (void)removeSearch:(id)sender
{
    [self.timelineDisplayMgr
        setTimelineHeaderView:[self saveSearchView]];
    [self.generalSavedSearchMgr removeSavedSearchForQuery:self.currentSearch];
}

- (void)saveSearch:(id)sender
{
    [self.timelineDisplayMgr
        setTimelineHeaderView:[self removeSearchView]];
    [self.generalSavedSearchMgr addSavedSearch:self.currentSearch];
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

- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title action:(SEL)action
{
    BOOL landscape = [[RotatableTabBarController instance] landscape];

    CGFloat viewWidth = landscape ? 480 : 320;
    CGRect viewFrame = CGRectMake(0, 0, viewWidth, 51);
    UIView * view = [[UIView alloc] initWithFrame:viewFrame];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    CGFloat buttonWidth = landscape ? 440 : 280;
    CGRect buttonFrame = CGRectMake(20, 7, buttonWidth, 37);
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = buttonFrame;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    CGRect grayLineFrame = CGRectMake(0, 50, viewWidth, 1);
    UIView * grayLineView =
        [[[UIView alloc] initWithFrame:grayLineFrame] autorelease];
    grayLineView.backgroundColor =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor twitchDarkDarkGrayColor] : [UIColor twitchLightGrayColor];
    grayLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    NSString * backgroundImageName =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        @"SaveSearchDarkThemeButtonBackground.png" :
        @"SaveSearchButtonBackground.png";
    UIImage * background =
        [[UIImage imageNamed:backgroundImageName]
        stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    NSString * highlightedBackgroundImageName =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        @"SaveSearchDarkThemeButtonBackgroundHighlighted.png" :
        @"SaveSearchButtonBackgroundHighlighted.png";
    UIImage * selectedBackground =
        [[UIImage imageNamed:highlightedBackgroundImageName]
        stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    [button setBackgroundImage:background forState:UIControlStateNormal];
    [button setBackgroundImage:selectedBackground
                      forState:UIControlStateHighlighted];

    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
    button.enabled = self.currentSearch && ![self.currentSearch isEqual:@""];

    UIColor * color =
        [SettingsReader displayTheme] == kDisplayThemeDark ?
        [UIColor twitchBlueOnDarkBackgroundColor] :
        [UIColor colorWithRed:.353 green:.4 blue:.494 alpha:1.0];
    [button setTitleColor:color forState:UIControlStateNormal];

    button.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    button.titleLabel.lineBreakMode = UILineBreakModeTailTruncation;

    UIControlEvents events = UIControlEventTouchUpInside;
    [button addTarget:self action:action forControlEvents:events];

    [view addSubview:button];
    [view addSubview:grayLineView];
    
    return [view autorelease];
}

@end
