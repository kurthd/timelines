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

        UINavigationItem * navItem = netAwareController.navigationItem;
        navItem.titleView = searchBar;

        CGFloat barHeight = navItem.titleView.superview.bounds.size.height;
        CGRect searchBarRect =
            CGRectMake(0.0, 0.0,
            netAwareController.view.bounds.size.width - 10.0,
            barHeight);
        searchBar.bounds = searchBarRect;

        [netAwareController setUpdatingState:kDisconnected];
        [netAwareController setCachedDataAvailable:NO];
        [netAwareController setNoConnectionText:@""];
    }

    return self;
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    if (!hasBeenDisplayed && self.currentSearchUsername) {
        hasBeenDisplayed = YES;
        [self userDidSelectSearchQuery:self.currentSearchUsername];
    }
}

#pragma mark TwitterServiceDelegate implementation

- (void)userInfo:(User *)user fetchedForUsername:(NSString *)username
{
    NSLog(@"Fetched user info for '%@'", username);
    self.currentSearchUsername = username;
    
    [netAwareController setUpdatingState:kConnectedAndNotUpdating];
    [netAwareController setCachedDataAvailable:YES];

    // this forces the tableview to scroll to top
    [userInfoController.tableView setContentOffset:CGPointMake(0, -300)
        animated:NO];

    [userInfoController setUser:user];
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
    [userInfoController setFollowing:YES];
}

- (void)user:(NSString *)username isNotFollowing:(NSString *)followee
{
    NSLog(@"Find people display manager: %@ is not following %@", username,
        followee);
    [userInfoController setFollowing:NO];
}

- (void)failedToQueryIfUser:(NSString *)username
    isFollowing:(NSString *)followee error:(NSError *)error
{
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.followingstatus", @"");

    [userInfoController setFailedToQueryFollowing];

    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)startedFollowingUsername:(NSString *)aUsername
{
    NSLog(@"Find people display manager: started following '%@'", aUsername);
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

    netAwareController.delegate = self.timelineDisplayMgr;
    
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
    [composeTweetDisplayMgr composeDirectMessageTo:self.currentSearchUsername];
}

- (void)sendDirectMessageToUser:(NSString *)aUsername
{
    [composeTweetDisplayMgr composeDirectMessageTo:aUsername];
}

- (void)sendPublicMessageToUser:(NSString *)aUsername
{
    [composeTweetDisplayMgr
        composeTweetWithText:[NSString stringWithFormat:@"@%@ ", aUsername]];
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
    [netAwareController setUpdatingState:kConnectedAndUpdating];
    [netAwareController setCachedDataAvailable:NO];
    NSCharacterSet * validUsernameCharSet =
        [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString * searchName =
        [[query stringByTrimmingCharactersInSet:validUsernameCharSet] 
        stringByReplacingOccurrencesOfString:@" " withString:@""];
    [self.recentSearchMgr addRecentSearch:searchName];
    searchBar.text = searchName;
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
    if (userInfoController.followingEnabled)
        [service isUser:credentials.username following:searchName];

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

#pragma mark TwitchBrowserViewControllerDelegate implementation

- (void)composeTweetWithText:(NSString *)text
{
    NSLog(@"Find people display manager: composing tweet with text'%@'", text);
    [composeTweetDisplayMgr composeTweetWithText:text];
}

- (void)readLater:(NSString *)url
{
    // TODO: implement me
}

#pragma mark FindPeopleSearchDisplayMgr implementation

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Find people display manager: setting credentials: %@",
        someCredentials);

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
        CGRect darkTransparentViewFrame = CGRectMake(0, 0, 320, 480);
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
        static const CGFloat HEIGHT = 200;
        static const CGFloat WIDTH = 320;

        CGRect frame = CGRectMake(0, 64, WIDTH, HEIGHT);
        autocompleteView = [[UIView alloc] initWithFrame:frame];

        CGRect tableViewFrame = CGRectMake(0, 0, WIDTH, HEIGHT);
        autoCompleteTableView =
            [[UITableView alloc]
            initWithFrame:tableViewFrame style:UITableViewStylePlain];
        autoCompleteTableView.dataSource = self;
        autoCompleteTableView.delegate = self;
        [autocompleteView addSubview:autoCompleteTableView];

        UIImage * shadowImage = [UIImage imageNamed:@"DropShadow.png"];
        UIImageView * shadowView =
            [[[UIImageView alloc] initWithImage:shadowImage] autorelease];
        [autocompleteView addSubview:shadowView];
    }

    return autocompleteView;
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
