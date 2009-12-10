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
- (void)deallocateNode;
- (void)updateUserListViewWithUsers:(NSArray *)users;

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
    [userListController release];
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
    [displayMgrHelper release];

    [super dealloc];
}

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    navigationController:(UINavigationController *)navigationController
    userListController:(UserListTableViewController *)aUserListController
    service:(TwitterService *)aService
    context:(NSManagedObjectContext *)aContext
    savedSearchMgr:(SavedSearchMgr *)aSavedSearchMgr
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    timelineFactory:(TimelineDisplayMgrFactory *)aTimelineFactory
    userListFactory:(UserListDisplayMgrFactory *)aUserListFactory
    findPeopleBookmarkMgr:(SavedSearchMgr *)findPeopleBookmarkMgr
    contactCache:(ContactCache *)aContactCache
    contactMgr:(ContactMgr *)aContactMgr
{
    if (self = [super init]) {
        netAwareController = [navc retain];
        userListController = [aUserListController retain];
        service = [aService retain];
        context = [aContext retain];
        savedSearchMgr = [aSavedSearchMgr retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        timelineDisplayMgrFactory = [aTimelineFactory retain];
        userListDisplayMgrFactory = [aUserListFactory retain];

        TwitterService * displayHelperService =
            [[[TwitterService alloc]
            initWithTwitterCredentials:service.credentials
            context:aContext]
            autorelease];

        displayMgrHelper =
            [[DisplayMgrHelper alloc]
            initWithWrapperController:navc
            navigationController:navigationController
            userListDisplayMgrFactor:aUserListFactory
            composeTweetDisplayMgr:composeTweetDisplayMgr
            twitterService:displayHelperService
            timelineFactory:aTimelineFactory
            managedObjectContext:aContext
            findPeopleBookmarkMgr:findPeopleBookmarkMgr
            contactCache:aContactCache contactMgr:aContactMgr];
        displayHelperService.delegate = displayMgrHelper;

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
        
        failedState = NO;
        cache = [[NSMutableDictionary dictionary] retain];

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
    NSLog(@"Showing find people view");
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

- (void)userSearchResultsReceived:(NSArray *)userSearchResults
    forQuery:(NSString *)query count:(NSNumber *)count page:(NSNumber *)page
{
    if ([query isEqual:self.currentSearchUsername]) {
        NSLog(@"Received %d user search results", [userSearchResults count]);
        NSInteger pageAsInt = [page intValue];
        currentPage = pageAsInt > 0 ? pageAsInt : 1;
        [self updateUserListViewWithUsers:userSearchResults];

        // HACK: forces to scroll to top
        [userListController.tableView setContentOffset:CGPointMake(0, 0)
            animated:NO];
    }
}

- (void)failedToSearchUsersForQuery:(NSString *)query count:(NSNumber *)count
    page:(NSNumber *)page error:(NSError *)error
{
    if ([query isEqual:self.currentSearchUsername]) {
        NSString * errorMessageFormatString =
            NSLocalizedString(@"findpeopledisplaymgr.error", @"");
        NSString * errorMessage =
            [NSString stringWithFormat:errorMessageFormatString, query];
        [[ErrorState instance] displayErrorWithTitle:errorMessage];

        [netAwareController setNoConnectionText:errorMessage];
        [netAwareController setUpdatingState:kDisconnected];
    }
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

    [cache removeAllObjects];

    [self.recentSearchMgr addRecentSearch:query];
    searchBar.text = query;
    self.currentSearchUsername = query;

    NSString * noConnFormatString =
        NSLocalizedString(@"findpeople.nouser", @"");
    NSString * noConnText =
        [searchBar.text isEqual:@""] ? @"" :
        [NSString stringWithFormat:noConnFormatString, query];
    NSLog(@"No conn text: %@", noConnText);
    [netAwareController setNoConnectionText:noConnText];

    loadingMore = NO;
    [service searchUsersFor:query count:nil page:nil];

    UITableViewController * tvc = (UITableViewController *)
        netAwareController.targetViewController;
    tvc.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
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

    [displayMgrHelper setCredentials:credentials];
}

#pragma mark UserListTableViewControllerDelegate implementation

- (void)showUserInfoForUser:(User *)aUser
{
    [displayMgrHelper showUserInfoForUser:aUser];
}

- (void)loadMoreUsers
{
    NSInteger nextPage = currentPage + 1;
    NSLog(@"Loading more person search results; page %d", nextPage);
    loadingMore = YES;
    [service searchUsersFor:self.currentSearchUsername count:nil
        page:[NSNumber numberWithInt:nextPage]];
}

- (void)userListViewWillAppear
{
    [self deallocateNode];
}

- (void)sendDirectMessageToCurrentUser
{
    [displayMgrHelper sendDirectMessageToCurrentUser];
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

- (NSInteger)selectedBookmarkSegment
{
    return [self.bookmarkController selectedSegment];
}

- (void)setSelectedBookmarkSegment:(NSInteger)segment
{
    [self.bookmarkController setSelectedSegment:segment];
}

- (void)deallocateNode
{
    self.timelineDisplayMgr = nil;
    self.nextUserListDisplayMgr = nil;
    self.credentialsPublisher = nil;
}

- (void)updateUserListViewWithUsers:(NSArray *)users
{
    NSLog(@"Received user list of size %d", [users count]);
    NSInteger oldCacheCount = [cache count];
    for (User * friend in users)
        [cache setObject:friend forKey:friend.username];
    BOOL allLoaded = loadingMore && [cache count] == oldCacheCount;
    [userListController setAllPagesLoaded:allLoaded];
    [userListController setUsers:[cache allValues]];
    [netAwareController setUpdatingState:kConnectedAndNotUpdating];
    [netAwareController setCachedDataAvailable:YES];
    failedState = NO;
}

@end
