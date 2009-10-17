//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchBarDisplayMgr.h"
#import "SearchBookmarksDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "RegexKitLite.h"
#import "UIColor+TwitchColors.h"
#import "ErrorState.h"
#import "RotatableTabBarController.h"
#import "SettingsReader.h"

@interface SearchBarDisplayMgr ()

@property (nonatomic, retain) TwitterService * service;
@property (nonatomic, retain) NSManagedObjectContext * context;

@property (nonatomic, retain) NetworkAwareViewController *
    networkAwareViewController;
@property (nonatomic, retain) UISearchBar * searchBar;

@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain) SearchDisplayMgr * searchDisplayMgr;
@property (nonatomic, retain) SearchBookmarksDisplayMgr *
    searchBookmarksDisplayMgr;

@property (nonatomic, copy) NSArray * searchResults;
@property (nonatomic, copy) NSNumber * searchPage;

@property (nonatomic, retain) CredentialsActivatedPublisher *
    credentialsActivatedPublisher;

@property (nonatomic, retain) UIView * darkTransparentView;

@property (nonatomic, copy) NSArray * autocompleteArray;
@property (nonatomic, readonly) UIView * autocompleteView;

@property (nonatomic, readonly) UIBarButtonItem * nearbySearchProgressView;
@property (nonatomic, readonly) CLLocationManager * locationMgr;
@property (nonatomic, readonly) UIBarButtonItem * locationButton;

- (void)displayBookmarksView;

- (void)showError:(NSError *)error;
- (void)showDarkTransparentView;
- (void)hideDarkTransparentView;

- (UIView *)saveSearchView;
- (UIView *)removeSearchView;
- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title
                                   action:(SEL)action;

- (void)updateAutocompleteView;
- (void)showAutocompleteResults;
- (void)hideAutocompleteResults;

- (void)toggleNearbySearchValue;

- (void)updateSearchButtonWithDoneState;

- (void)updateAutocompleteViewFrame;

- (void)setSearchBarFrame;

@end

@implementation SearchBarDisplayMgr

@synthesize service, context;
@synthesize searchBar, networkAwareViewController;
@synthesize timelineDisplayMgr, searchDisplayMgr, searchBookmarksDisplayMgr;
@synthesize searchResults, searchQuery, searchPage;
@synthesize dataSourceDelegate, credentialsActivatedPublisher;
@synthesize darkTransparentView;
@synthesize autocompleteArray;
@synthesize nearbySearch;

#pragma mark Initialization

- (void)dealloc
{
    self.service = nil;
    self.context = nil;
    self.networkAwareViewController = nil;
    self.searchBar = nil;
    self.timelineDisplayMgr = nil;
    self.searchDisplayMgr = nil;
    self.searchBookmarksDisplayMgr = nil;
    self.searchResults = nil;
    self.searchQuery = nil;
    self.searchPage = nil;
    self.dataSourceDelegate = nil;
    self.credentialsActivatedPublisher = nil;
    self.darkTransparentView = nil;
    [autocompleteArray release];
    [autoCompleteTableView release];
    [nearbySearchProgressView release];
    [locationMgr release];
    [locationButton release];
    [super dealloc];
}

- (id)initWithTwitterService:(TwitterService *)aService
          netAwareController:(NetworkAwareViewController *)navc
          timelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr
                     context:(NSManagedObjectContext *)aContext
{
    if (self = [super init]) {
        self.service = aService;
        self.service.delegate = self;

        self.context = aContext;

        self.networkAwareViewController = navc;

        UINavigationItem * navItem =
            self.networkAwareViewController.navigationItem;
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];

        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchBar.showsBookmarkButton = YES;
        searchBar.delegate = self;
        searchBar.barStyle =
            [SettingsReader displayTheme] == kDisplayThemeDark ?
            UIBarStyleBlackOpaque : UIBarStyleDefault;

        navItem.titleView = searchBar;
        [self setSearchBarFrame];

        navItem.leftBarButtonItem = self.locationButton;

        self.timelineDisplayMgr = aTimelineDisplayMgr;
        searchDisplayMgr =
            [[SearchDisplayMgr alloc]
             initWithTwitterService:[self.service clone]];

        // Don't autorelease
        credentialsActivatedPublisher =
            [[CredentialsActivatedPublisher alloc]
                initWithListener:self
                          action:@selector(setCredentials:)];

        [self.timelineDisplayMgr setService:self.searchDisplayMgr
                                     tweets:nil
                                       page:0
                               forceRefresh:NO
                             allPagesLoaded:NO];
        self.searchDisplayMgr.dataSourceDelegate = self.timelineDisplayMgr;

        [self.networkAwareViewController setUpdatingState:kDisconnected];
        [self.networkAwareViewController setCachedDataAvailable:NO];
        [self.networkAwareViewController setNoConnectionText:@""];
    }

    return self;
}

- (void)setSearchBarFrame
{
    BOOL landscape = [[RotatableTabBarController instance] landscape];
    CGFloat viewWidth = landscape ? 470 : 310;
    CGFloat barHeight = landscape ? 32 : 44;
    CGRect searchBarRect = CGRectMake(0.0, 0.0, viewWidth, barHeight);
    searchBar.bounds = searchBarRect;
}

- (void)setCredentials:(TwitterCredentials *)credentials
{
    self.searchBookmarksDisplayMgr = nil;
    self.searchBar.text = @"";
    self.searchResults = nil;
    self.searchQuery = nil;
    self.searchPage = nil;
    [self.searchDisplayMgr clearDisplay];

    [self.service setCredentials:credentials];
    [self.searchDisplayMgr setCredentials:credentials];
    [self.timelineDisplayMgr setCredentials:credentials];
}

- (void)searchBarViewWillAppear:(BOOL)promptUser
{
    if (!self.searchQuery) {
        [self.networkAwareViewController setUpdatingState:kDisconnected];
        [self.networkAwareViewController setCachedDataAvailable:NO];
        [self.networkAwareViewController setNoConnectionText:@""];

        if (promptUser) {
            [self.searchBar becomeFirstResponder];
            [self showDarkTransparentView];
        }
    }
}

#pragma mark UISearchBarDelegate implementation

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSarchBar
{
    hasBeenDisplayed = YES; // bit of a hack, but force this to be set

    [self hideDarkTransparentView];
    [self hideAutocompleteResults];

    [self.searchBar resignFirstResponder];
    [self.searchBar setShowsCancelButton:NO animated:YES];

    [[ErrorState instance] exitErrorState];

    self.searchResults = nil;
    self.searchQuery = self.searchBar.text;
    self.searchPage = [NSNumber numberWithInteger:1];
    if (self.searchQuery.length)
        [self.searchBookmarksDisplayMgr addRecentSearch:self.searchQuery];

    NSLog(@"Searching Twitter for: '%@'...", self.searchQuery);
    [self.searchDisplayMgr displaySearchResults:self.searchQuery
                                      withTitle:self.searchQuery];
    [self.timelineDisplayMgr setService:self.searchDisplayMgr
                                 tweets:nil
                                   page:[self.searchPage integerValue]
                           forceRefresh:YES
                         allPagesLoaded:NO];

    if ([self.searchBookmarksDisplayMgr isSearchSaved:self.searchQuery])
        [self.timelineDisplayMgr setTimelineHeaderView:[self removeSearchView]];
    else
        [self.timelineDisplayMgr setTimelineHeaderView:[self saveSearchView]];

    UITableViewController * tvc = (UITableViewController *)
        self.networkAwareViewController.targetViewController;
    tvc.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    tvc.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);

    networkAwareViewController.navigationItem.title = self.searchQuery;
    networkAwareViewController.navigationItem.backBarButtonItem =
        [[[UIBarButtonItem alloc]
        initWithTitle:self.searchQuery style:UIBarButtonItemStyleBordered
        target:nil action:nil]
        autorelease];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [self.searchBar resignFirstResponder];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self hideDarkTransparentView];
    [self hideAutocompleteResults];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)aSearchBar
{
    editingQuery = YES;
    [self showDarkTransparentView];
    [self.searchBar setShowsCancelButton:YES animated:YES];
    [self performSelector:@selector(updateAutocompleteView) withObject:nil
        afterDelay:0.3];

    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    editingQuery = NO;
    [self.searchBar setShowsCancelButton:NO animated:YES];
    return YES;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{
    [self displayBookmarksView];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self updateAutocompleteView];
}

#pragma mark Bookmarks

- (void)displayBookmarksView
{
    [self.searchBookmarksDisplayMgr
        displayBookmarksInRootView:self.networkAwareViewController];
}

- (void)saveSearch:(id)sender
{
    NSLog(@"Saving search: '%@'", self.searchQuery);
    [self.searchBookmarksDisplayMgr addSavedSearch:self.searchQuery];
    [self.timelineDisplayMgr setTimelineHeaderView:[self removeSearchView]];
}

- (void)removeSearch:(id)sender
{
    NSLog(@"Forgetting search: '%@'.", self.searchQuery);
    [self.searchBookmarksDisplayMgr removeSavedSearch:self.searchQuery];
    [self.timelineDisplayMgr setTimelineHeaderView:[self saveSearchView]];
}

#pragma mark SearchBookmarksDisplayMgrDelegate implementation

- (void)searchFor:(NSString *)query
{
    self.searchBar.text = query;
    [self searchBarSearchButtonClicked:self.searchBar];
}

- (void)savedSearchRemoved:(NSString *)query
{
    if ([self.searchQuery isEqualToString:query])
        [self.timelineDisplayMgr setTimelineHeaderView:[self saveSearchView]];
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    if (!hasBeenDisplayed) {
        hasBeenDisplayed = YES;
        if (nearbySearch) {
            self.locationButton.style = UIBarButtonItemStyleDone;
            self.searchBar.text = self.searchQuery;

            [self.locationMgr startUpdatingLocation];
            [self performSelector:@selector(updateSearchButtonWithDoneState)
                withObject:nil afterDelay:0.1];
        } else if (self.searchQuery && ![self.searchQuery isEqual:@""])
            [self searchFor:self.searchQuery];
    }
    [self performSelector:@selector(setSearchBarFrame) withObject:nil
        afterDelay:0];
}

- (void)viewWillRotateToOrientation:(UIInterfaceOrientation)orientation
{
    [self updateAutocompleteViewFrame];
    [self performSelector:@selector(setSearchBarFrame) withObject:nil
        afterDelay:0];
}

- (void)updateSearchButtonWithDoneState
{
    if (!self.locationMgr.location)
        [self.networkAwareViewController.navigationItem
            setLeftBarButtonItem:[self nearbySearchProgressView]
            animated:YES];
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
    [self.searchBookmarksDisplayMgr userDidSelectSearchQuery:query];
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
    [self.networkAwareViewController.view.superview.superview
        addSubview:self.darkTransparentView];  

    self.darkTransparentView.alpha = 0.0;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:self.darkTransparentView
                             cache:YES];

    self.darkTransparentView.alpha = 0.8;
    
    [UIView commitAnimations];
}

- (void)hideDarkTransparentView
{
    self.darkTransparentView.alpha = 0.8;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone
                           forView:self.darkTransparentView
                             cache:YES];

    self.darkTransparentView.alpha = 0.0;

    [UIView commitAnimations];

    [self.darkTransparentView removeFromSuperview];
}

- (void)updateAutocompleteView
{
    if (searchBar.text.length > 0) {
        NSMutableArray * matchingSavedSearches = [NSMutableArray array];
        for (SavedSearch * search in
            [self.searchBookmarksDisplayMgr savedSearches]) {
            NSString * regex =
                [NSString stringWithFormat:@"\\b%@.*", searchBar.text];
            NSRange range = NSMakeRange(0, search.query.length);
            if ([search.query isMatchedByRegex:regex options:RKLCaseless
                inRange:range error:NULL])
                [matchingSavedSearches addObject:search.query];
        }

        for (SavedSearch * search in
            [self.searchBookmarksDisplayMgr recentSearches]) {
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
    [networkAwareViewController.view.superview.superview
        addSubview:self.autocompleteView];
    [self updateAutocompleteViewFrame];
}

- (void)hideAutocompleteResults
{
    showingAutocompleteResults = NO;
    [self.autocompleteView removeFromSuperview];
}

#pragma mark CLLocationManagerDelegate implementation

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
    fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"Search display manager: obtained location");
    [manager stopUpdatingLocation];
    self.searchDisplayMgr.nearbySearchLocation = newLocation;
    [self.networkAwareViewController.navigationItem
        setLeftBarButtonItem:self.locationButton animated:YES];
    [self searchBarSearchButtonClicked:searchBar];
}

- (void)locationManager:(CLLocationManager *)manager
    didFailWithError:(NSError *)error
{
    [manager stopUpdatingLocation];
    [self.networkAwareViewController.navigationItem
        setLeftBarButtonItem:self.locationButton animated:YES];
    locationButton.style = UIBarButtonItemStyleBordered;
    NSString * title = NSLocalizedString(@"search.location.failed", @"");
    [[ErrorState instance] displayErrorWithTitle:title error:error];
}

#pragma mark Accessors

- (SearchBookmarksDisplayMgr *)searchBookmarksDisplayMgr
{
    if (!searchBookmarksDisplayMgr) {
        NSString * accountName = self.service.credentials.username;
        searchBookmarksDisplayMgr =
            [[SearchBookmarksDisplayMgr alloc] initWithAccountName:accountName
                                                           service:service
                                                           context:context];
        searchBookmarksDisplayMgr.delegate = self;
    }

    return searchBookmarksDisplayMgr;
}

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
        [UIColor blackColor] : [UIColor twitchLightGrayColor];
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
    return [self.searchBookmarksDisplayMgr selectedSegment];
}

- (void)setSelectedBookmarkSegment:(NSInteger)segment
{
    [self.searchBookmarksDisplayMgr setSelectedSegment:segment];
}

- (void)toggleNearbySearchValue
{
    nearbySearch = !nearbySearch;
    self.locationButton.style =
        nearbySearch ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;

    if (!nearbySearch)
        self.searchDisplayMgr.nearbySearchLocation = nil;

    if (searchBar.text && ![searchBar.text isEqual:@""] && !nearbySearch) {
        [self searchBarSearchButtonClicked:searchBar];
    } else if (nearbySearch) {
        if (!self.locationMgr.location) {
            [self.locationMgr startUpdatingLocation];
            [self.networkAwareViewController.navigationItem
                setLeftBarButtonItem:[self nearbySearchProgressView]
                animated:YES];
        } else {
            [self.networkAwareViewController.navigationItem
                setLeftBarButtonItem:self.locationButton animated:YES];
            self.searchDisplayMgr.nearbySearchLocation =
                self.locationMgr.location;
           [self searchBarSearchButtonClicked:searchBar];
        }
    }
}

- (UIBarButtonItem *)nearbySearchProgressView
{
    if (!nearbySearchProgressView) {
        UIActivityIndicatorView * view =
            [[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

        nearbySearchProgressView =
            [[UIBarButtonItem alloc] initWithCustomView:view];

        [view startAnimating];

        [view release];
    }

    return nearbySearchProgressView;
}

- (CLLocationManager *)locationMgr
{
    if (!locationMgr) {
        locationMgr = [[CLLocationManager alloc] init];
        locationMgr.delegate = self;
    }

    return locationMgr;
}

- (UIBarButtonItem *)locationButton
{
    if (!locationButton)
        locationButton =
            [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"Location.png"]
            style:UIBarButtonItemStyleBordered target:self
            action:@selector(toggleNearbySearchValue)];

    return locationButton;
}

@end
