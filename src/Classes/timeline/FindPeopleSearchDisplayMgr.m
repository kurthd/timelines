//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "FindPeopleSearchDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "FavoritesTimelineDataSource.h"
#import "ArbUserTimelineDataSource.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "ErrorState.h"
#import "SearchDataSource.h"
#import "RegexKitLite.h"
#import "SettingsReader.h"
#import "NearbySearchDataSource.h"
#import "UIColor+TwitchColors.h"
#import "RotatableTabBarController.h"

@interface FindPeopleSearchDisplayMgr ()

@property (nonatomic, retain) UIView * darkTransparentView;

- (void)showError:(NSError *)error;
- (void)showDarkTransparentView;
- (void)hideDarkTransparentView;
- (void)displayBookmarksView;
- (void)searchForQuery:(NSString *)query;
- (void)sendDirectMessageToCurrentUser;
- (void)removeSearch:(id)sender;
- (void)saveSearch:(id)sender;
- (UIView *)saveSearchView;
- (UIView *)removeSearchView;
- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title action:(SEL)action;
- (void)updateAutocompleteView;
- (void)showAutocompleteResults;
- (void)hideAutocompleteResults;
- (void)updateAutocompleteViewFrame;
- (void)setSearchBarFrameWithLandscape:(BOOL)landscape;
- (void)setSearchBarFrame;

@property (nonatomic, readonly)
    FindPeopleBookmarkViewController * bookmarkController;
@property (nonatomic, retain) RecentSearchMgr * recentSearchMgr;

@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * nextWrapperController;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * credentialsPublisher;
@property (nonatomic, retain) UserListDisplayMgr * nextUserListDisplayMgr;
@property (nonatomic, retain) NSString * currentSearch;
@property (nonatomic, retain) SavedSearchMgr * generalSavedSearchMgr;
@property (nonatomic, copy) NSArray * autocompleteArray;
@property (nonatomic, readonly) UIView * autocompleteView;

@property (nonatomic, readonly)
    LocationMapViewController * locationMapViewController;
@property (nonatomic, readonly)
    LocationInfoViewController * locationInfoViewController;

@end

@implementation FindPeopleSearchDisplayMgr

@synthesize darkTransparentView;
@synthesize recentSearchMgr;
@synthesize timelineDisplayMgr, nextWrapperController, credentialsPublisher,
    nextUserListDisplayMgr;
@synthesize currentSearchUsername;
@synthesize currentSearch;
@synthesize generalSavedSearchMgr;
@synthesize autocompleteArray;

- (void)dealloc
{
    [netAwareController release];
    [userInfoController release];
    [searchBar release];
    [service release];
    [timelineDisplayMgrFactory release];
    [userListDisplayMgrFactory release];
    [darkTransparentView release];
    [bookmarkController release];
    [recentSearchMgr release];
    [savedSearchMgr release];
    [context release];
    [composeTweetDisplayMgr release];
    [timelineDisplayMgr release];
    [nextWrapperController release];
    [credentials release];
    [credentialsPublisher release];
    [nextUserListDisplayMgr release];
    [currentSearchUsername release];
    [currentSearch release];
    [generalSavedSearchMgr release];
    [autocompleteArray release];
    [autoCompleteTableView release];
    [locationMapViewController release];
    [locationInfoViewController release];

    [super dealloc];
}

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    userInfoController:(UserInfoViewController *)aUserInfoController
    service:(TwitterService *)aService
    context:(NSManagedObjectContext *)aContext
    savedSearchMgr:(SavedSearchMgr *)aSavedSearchMgr
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    timelineFactory:(TimelineDisplayMgrFactory *)aTimelineFactory
    userListFactory:(UserListDisplayMgrFactory *)aUserListFactory
{
    if (self = [super init]) {
        netAwareController = [navc retain];
        userInfoController = [aUserInfoController retain];
        service = [aService retain];
        context = [aContext retain];
        savedSearchMgr = [aSavedSearchMgr retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        timelineDisplayMgrFactory = [aTimelineFactory retain];
        userListDisplayMgrFactory = [aUserListFactory retain];

        searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];

        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchBar.showsBookmarkButton = YES;
        searchBar.placeholder =
            NSLocalizedString(@"findpeople.placeholder", @"");
        searchBar.delegate = self;
        searchBar.barStyle =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            UIBarStyleBlackOpaque : UIBarStyleDefault;

        UINavigationItem * navItem = netAwareController.navigationItem;
        navItem.titleView = searchBar;
        [self setSearchBarFrame];

        [netAwareController setUpdatingState:kDisconnected];
        [netAwareController setCachedDataAvailable:NO];
        [netAwareController setNoConnectionText:@""];
    }

    return self;
}

- (void)setSearchBarFrameWithLandscape:(BOOL)landscape
{
    CGFloat viewWidth = landscape ? 470 : 310;
    CGFloat barHeight = landscape ? 32 : 44;

    // this shortens the search field to avoid weird adjustment animations when
    // there's a back button
    NSArray * viewControllers =
        [netAwareController.navigationController viewControllers];
    UIViewController * topViewController = [viewControllers objectAtIndex:0];
    if (netAwareController != topViewController)
        viewWidth -= 57;

    CGRect searchBarRect = CGRectMake(0.0, 0.0, viewWidth, barHeight);
    searchBar.bounds = searchBarRect;
}

- (void)setSearchBarFrame
{
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    [self setSearchBarFrameWithLandscape:landscape];
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    if (!hasBeenDisplayed && self.currentSearchUsername) {
        hasBeenDisplayed = YES;
        if (self.currentSearchUsername &&
            ![self.currentSearchUsername isEqual:@""])
            [self userDidSelectSearchQuery:self.currentSearchUsername];
    }
    [self performSelector:@selector(setSearchBarFrame) withObject:nil
        afterDelay:0];
}

- (void)viewWillRotateToOrientation:(UIInterfaceOrientation)orientation
{
    NSLog(@"Find people tab changing orientation");
    [self updateAutocompleteViewFrame];
    [self performSelector:@selector(setSearchBarFrame) withObject:nil
        afterDelay:0];
}

#pragma mark TwitterServiceDelegate implementation

- (void)userInfo:(User *)user fetchedForUsername:(NSString *)username
{
    NSLog(@"Fetched user info for '%@'", username);

    if ([self.currentSearchUsername isEqual:username]) {
        [netAwareController setUpdatingState:kConnectedAndNotUpdating];
        [netAwareController setCachedDataAvailable:YES];

        // this forces the tableview to scroll to top
        [userInfoController.tableView setContentOffset:CGPointMake(0, 300)
            animated:NO];

        [userInfoController setUser:user];

        netAwareController.navigationItem.title = username;
        netAwareController.navigationItem.backBarButtonItem =
            [[[UIBarButtonItem alloc]
            initWithTitle:username style:UIBarButtonItemStyleBordered target:nil
            action:nil]
            autorelease];
    }
}

- (void)failedToFetchUserInfoForUsername:(NSString *)username
    error:(NSError *)error
{
    NSLog(@"Unable to find user '%@'", username);
    self.currentSearchUsername = nil;

    [netAwareController setUpdatingState:kDisconnected];
    [netAwareController setCachedDataAvailable:NO];
}

- (void)user:(NSString *)username isFollowing:(NSString *)followee
{
    NSLog(@"Find people display manager: %@ is following %@", username,
        followee);
    if ([[self.currentSearchUsername lowercaseString]
        isEqual:[followee lowercaseString]])
        [userInfoController setFollowing:YES];
    else if ([[self.currentSearchUsername lowercaseString] 
        isEqual:[username lowercaseString]])
        [userInfoController setFollowedBy:YES];
}

- (void)user:(NSString *)username isNotFollowing:(NSString *)followee
{
    NSLog(@"Find people display manager: %@ is not following %@", username,
        followee);
    if ([[self.currentSearchUsername lowercaseString]
        isEqual:[followee lowercaseString]])
        [userInfoController setFollowing:NO];
    else if ([[self.currentSearchUsername lowercaseString] 
        isEqual:[username lowercaseString]])
        [userInfoController setFollowedBy:NO];
}

- (void)failedToQueryIfUser:(NSString *)username
    isFollowing:(NSString *)followee error:(NSError *)error
{
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.followingstatus", @"");

    if ([[self.currentSearchUsername lowercaseString]
        isEqual:[followee lowercaseString]])
        [userInfoController setFailedToQueryFollowing];
    else if ([[self.currentSearchUsername lowercaseString] 
        isEqual:[username lowercaseString]])
        [userInfoController setFailedToQueryFollowedBy];

    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)userIsBlocked:(NSString *)username
{
    if ([self.currentSearchUsername isEqual:username])
        [userInfoController setBlocked:YES];
}

- (void)userIsNotBlocked:(NSString *)username
{
    if ([self.currentSearchUsername isEqual:username])
        [userInfoController setBlocked:NO];
}

- (void)blockedUser:(User *)user withUsername:(NSString *)username
{
    if ([self.currentSearchUsername isEqual:username])
        [userInfoController setBlocked:YES];
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
    if ([self.currentSearchUsername isEqual:username])
        [userInfoController setBlocked:NO];
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

- (void)startedFollowingUsername:(NSString *)aUsername
{
    NSLog(@"Find people display manager: started following '%@'", aUsername);
    if ([self.currentSearchUsername isEqual:aUsername])
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
    NSLog(@"Find people display manager: stopped following '%@'", aUsername);
    if ([self.currentSearchUsername isEqual:aUsername])
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
                                
#pragma mark UserInfoViewControllerDelegate implementation

- (void)showTweetsForUser:(NSString *)aUsername
{
    NSLog(@"Find people display manager: showing tweets for %@", aUsername);

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

- (void)showLocationOnMap:(NSString *)locationString
{
    NSLog(@"Find people display manager: showing %@ on map", locationString);

    self.locationMapViewController.navigationItem.title = @"Map";
    
    [netAwareController.navigationController
        pushViewController:self.locationMapViewController animated:YES];

    [self.locationMapViewController setLocation:locationString];
}

- (void)showLocationInfo:(NSString *)locationString
    coordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"Find people display manager: showing location info for %@",
        locationString);

    [netAwareController.navigationController
        pushViewController:self.locationInfoViewController animated:YES];

    [self.locationInfoViewController setLocationString:locationString
        coordinate:coordinate];
}

- (void)displayFollowingForUser:(NSString *)aUsername
{
    NSLog(@"Find people display manager: displaying 'following' list for %@",
        aUsername);

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
    NSLog(@"Find people display manager: displaying 'followers' list for %@",
        aUsername);

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
    NSLog(@"Find people display manager: displaying favorites for user %@",
        aUsername);
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

- (void)startFollowingUser:(NSString *)aUsername
{
    [service followUser:aUsername];
}

- (void)stopFollowingUser:(NSString *)aUsername
{
    [service stopFollowingUser:aUsername];
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
    self.nextWrapperController = nil;
    self.timelineDisplayMgr = nil;
    self.credentialsPublisher = nil;
    self.nextUserListDisplayMgr = nil;
}

- (void)sendDirectMessageToCurrentUser
{
    [composeTweetDisplayMgr composeDirectMessageTo:self.currentSearchUsername
        animated:YES];
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
    NSLog(@"Find people display manager: showing search results for '%@'",
        query);
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

- (void)showResultsForNearbySearchWithLatitude:(NSNumber *)latitude
    longitude:(NSNumber *)longitude
{
    NSLog(@"Find people display manager: showing results for nearby search");
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

#pragma mark UISearchBarDelegate implementation

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    [self hideDarkTransparentView];
    [self hideAutocompleteResults];

    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];

    [self searchForQuery:searchBar.text];
}

// helper
- (void)searchForQuery:(NSString *)query
{
    hasBeenDisplayed = YES; // bit of a hack, but force this to be set
        
    [netAwareController setUpdatingState:kConnectedAndUpdating];
    [netAwareController setCachedDataAvailable:NO];
    NSCharacterSet * validUsernameCharSet =
        [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString * searchName =
        [[query stringByTrimmingCharactersInSet:validUsernameCharSet] 
        stringByReplacingOccurrencesOfString:@" " withString:@""];
    [self.recentSearchMgr addRecentSearch:searchName];

    searchBar.text = searchName;
    self.currentSearchUsername = searchName;

    NSString * noConnFormatString =
        NSLocalizedString(@"findpeople.nouser", @"");
    NSString * noConnText =
        [searchBar.text isEqual:@""] ? @"" :
        [NSString stringWithFormat:noConnFormatString, searchName];
    NSLog(@"No conn text: %@", noConnText);
    [netAwareController setNoConnectionText:noConnText];

    [userInfoController showingNewUser];
    [service fetchUserInfoForUsername:searchName];
    userInfoController.followingEnabled =
        ![credentials.username isEqual:searchName];
    if (userInfoController.followingEnabled) {
        [service isUser:credentials.username following:searchName];
        [service isUser:searchName following:credentials.username];
        [userInfoController setQueryingFollowedBy];
    }

    [service isUserBlocked:searchName];

    UITableViewController * tvc = (UITableViewController *)
        netAwareController.targetViewController;
    tvc.tableView.contentInset = UIEdgeInsetsMake(-300.0, 0, 0, 0);
    tvc.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    [self hideDarkTransparentView];
    [self hideAutocompleteResults];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)aSearchBar
{
    editingQuery = YES;
    [self showDarkTransparentView];
    [searchBar setShowsCancelButton:YES animated:YES];
    [self performSelector:@selector(updateAutocompleteView) withObject:nil
        afterDelay:0.3];

    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)aSearchBar
{
    editingQuery = NO;
    [searchBar setShowsCancelButton:NO animated:YES];

    return YES;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)aSearchBar
{
    [self displayBookmarksView];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self updateAutocompleteView];
}

#pragma mark SearchBookmarksViewControllerDelegate implementation

- (NSArray *)savedSearches
{
    return [savedSearchMgr savedSearches];
}

- (BOOL)removeSavedSearchWithQuery:(NSString *)query
{
    [savedSearchMgr removeSavedSearchForQuery:query];

    return YES;
}

- (void)setSavedSearchOrder:(NSArray *)savedSearches
{
    [savedSearchMgr setSavedSearchOrder:savedSearches];
}

- (NSArray *)recentSearches
{
    return [self.recentSearchMgr recentSearches];
}

- (void)clearRecentSearches
{
    [self.recentSearchMgr clear];
}

- (void)userDidSelectSearchQuery:(NSString *)query
{
    [netAwareController dismissModalViewControllerAnimated:YES];

    [self hideDarkTransparentView];

    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];

    [self searchForQuery:query];
}

- (void)userDidCancel
{
    [netAwareController dismissModalViewControllerAnimated:YES];
}

#pragma mark FindPeopleSearchDisplayMgr implementation

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Find people display manager: setting credentials: %@",
        someCredentials.username);

    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:someCredentials];
    self.generalSavedSearchMgr.accountName = someCredentials.username;
}

#pragma mark UITableViewDataSource implementation

- (UITableViewCell *)tableView:(UITableView *)tableView
    cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"UITableViewCell";

    UITableViewCell * cell =
        [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell)
        cell =
            [[[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:cellIdentifier]
            autorelease];

    cell.textLabel.text = [self.autocompleteArray objectAtIndex:indexPath.row];

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    return [self.autocompleteArray count];
}

#pragma mark UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self hideAutocompleteResults];
    NSString * query = [self.autocompleteArray objectAtIndex:indexPath.row];
    [self userDidSelectSearchQuery:query];
}

#pragma mark UI helpers

- (void)showError:(NSError *)error
{
    NSString * title = NSLocalizedString(@"search.fetch.failed", @"");
    NSString * message = error.localizedDescription;

    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
}

- (void)showDarkTransparentView
{
    [netAwareController.view.superview.superview
        addSubview:self.darkTransparentView];  

    self.darkTransparentView.alpha = 0.0;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:self.darkTransparentView cache:YES];

    self.darkTransparentView.alpha = 0.8;

    [UIView commitAnimations];
}

- (void)hideDarkTransparentView
{
    self.darkTransparentView.alpha = 0.8;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
        forView:self.darkTransparentView cache:YES];

    self.darkTransparentView.alpha = 0.0;

    [UIView commitAnimations];

    [self.darkTransparentView removeFromSuperview];
}

- (void)displayBookmarksView
{
    [netAwareController presentModalViewController:self.bookmarkController
        animated:YES];
}

- (void)updateAutocompleteView
{
    if (searchBar.text.length > 0) {
        NSMutableArray * matchingSavedSearches = [NSMutableArray array];
        for (SavedSearch * search in [self savedSearches]) {
            NSString * regex =
                [NSString stringWithFormat:@"\\b%@.*", searchBar.text];
            NSRange range = NSMakeRange(0, search.query.length);
            if ([search.query isMatchedByRegex:regex options:RKLCaseless
                inRange:range error:NULL])
                [matchingSavedSearches addObject:search.query];
        }

        for (SavedSearch * search in [self recentSearches]) {
            NSString * regex =
                [NSString stringWithFormat:@"\\b%@.*", searchBar.text];
            NSRange range = NSMakeRange(0, search.query.length);
            if ([search.query isMatchedByRegex:regex options:RKLCaseless
                inRange:range error:NULL] &&
                ![matchingSavedSearches containsObject:search.query])
                [matchingSavedSearches addObject:search.query];
        }

        self.autocompleteArray =
            [matchingSavedSearches
            sortedArrayUsingSelector:@selector(compare:)];
    } else
        self.autocompleteArray = [NSArray array];

    if ([self.autocompleteArray count] > 0 && !showingAutocompleteResults &&
        editingQuery)
        [self showAutocompleteResults];
    else if ([self.autocompleteArray count] == 0 && showingAutocompleteResults)
        [self hideAutocompleteResults];

    [autoCompleteTableView reloadData];
}

- (void)showAutocompleteResults
{
    showingAutocompleteResults = YES;
    [netAwareController.view.superview.superview
        addSubview:self.autocompleteView];
    [self updateAutocompleteViewFrame];
}

- (void)hideAutocompleteResults
{
    showingAutocompleteResults = NO;
    [self.autocompleteView removeFromSuperview];
}

#pragma mark Accessors

- (UIView *)darkTransparentView
{
    if (!darkTransparentView) {
        CGRect darkTransparentViewFrame = CGRectMake(0, 0, 480, 480);
        darkTransparentView =
            [[UIView alloc] initWithFrame:darkTransparentViewFrame];
        darkTransparentView.backgroundColor = [UIColor blackColor];
        darkTransparentView.alpha = 0.0;
    }

    return darkTransparentView;
}

- (FindPeopleBookmarkViewController *)bookmarkController
{
    if (!bookmarkController) {
        bookmarkController =
            [[FindPeopleBookmarkViewController alloc]
            initWithNibName:@"FindPeopleBookmarkView" bundle:nil];
        bookmarkController.delegate = self;

        bookmarkController.username = service.credentials.username;

        // Don't autorelease
        [[CredentialsActivatedPublisher alloc]
            initWithListener:bookmarkController
            action:@selector(setCredentials:)];
    }

    return bookmarkController;
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
    
    button.enabled = searchBar.text && ![searchBar.text isEqual:@""];

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

- (SavedSearchMgr *)generalSavedSearchMgr
{
    if (!generalSavedSearchMgr)
        generalSavedSearchMgr =
            [[SavedSearchMgr alloc]
            initWithAccountName:credentials.username
            context:context];

    return generalSavedSearchMgr;
}

- (UIView *)autocompleteView
{
    if (!autocompleteView) {
        autocompleteView = [[UIView alloc] initWithFrame:CGRectZero];

        autoCompleteTableView =
            [[UITableView alloc]
            initWithFrame:CGRectZero style:UITableViewStylePlain];
        autoCompleteTableView.dataSource = self;
        autoCompleteTableView.delegate = self;
        autoCompleteTableView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [autocompleteView addSubview:autoCompleteTableView];

        UIImage * shadowImage = [UIImage imageNamed:@"DropShadow.png"];
        UIImageView * shadowView =
            [[[UIImageView alloc] initWithImage:shadowImage] autorelease];
        shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [autocompleteView addSubview:shadowView];
    }

    return autocompleteView;
}

- (void)updateAutocompleteViewFrame
{
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    CGRect autocompleteViewFrame = self.autocompleteView.frame;
    autocompleteViewFrame.size.width = !landscape ? 320 : 480;
    autocompleteViewFrame.size.height = !landscape ? 200 : 108;
    autocompleteViewFrame.origin.y = !landscape ? 64 : 50;
    self.autocompleteView.frame = autocompleteViewFrame;
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

- (NSInteger)selectedBookmarkSegment
{
    return [self.bookmarkController selectedSegment];
}

- (void)setSelectedBookmarkSegment:(NSInteger)segment
{
    [self.bookmarkController setSelectedSegment:segment];
}

@end
