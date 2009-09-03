//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchBarDisplayMgr.h"
#import "SearchBookmarksDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "RegexKitLite.h"
#import "UIColor+TwitchColors.h"

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

@end

@implementation SearchBarDisplayMgr

@synthesize service, context;
@synthesize searchBar, networkAwareViewController;
@synthesize timelineDisplayMgr, searchDisplayMgr, searchBookmarksDisplayMgr;
@synthesize searchResults, searchQuery, searchPage;
@synthesize dataSourceDelegate, credentialsActivatedPublisher;
@synthesize darkTransparentView;
@synthesize autocompleteArray;

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

        navItem.titleView = searchBar;
        CGFloat barHeight = navItem.titleView.superview.bounds.size.height;
        CGRect searchBarRect =
            CGRectMake(0.0, 0.0,
            self.networkAwareViewController.view.bounds.size.width - 10.0,
            barHeight);
        searchBar.bounds = searchBarRect;

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

    [self.networkAwareViewController setUpdatingState:kConnectedAndUpdating];
    [self.networkAwareViewController setCachedDataAvailable:NO];

    self.searchResults = nil;
    self.searchQuery = self.searchBar.text;
    self.searchPage = [NSNumber numberWithInteger:1];
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
    if (!hasBeenDisplayed && self.searchQuery) {
        hasBeenDisplayed = YES;
        [self searchFor:self.searchQuery];
    }
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
}

- (void)hideAutocompleteResults
{
    showingAutocompleteResults = NO;
    [self.autocompleteView removeFromSuperview];
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
        CGRect darkTransparentViewFrame = CGRectMake(0, 0, 320, 480);
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
    CGRect viewFrame = CGRectMake(0, 0, 320, 51);
    UIView * view = [[UIView alloc] initWithFrame:viewFrame];

    CGRect buttonFrame = CGRectMake(20, 7, 280, 37);
    UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = buttonFrame;

    CGRect grayLineFrame = CGRectMake(0, 50, 320, 1);
    UIView * grayLineView =
        [[[UIView alloc] initWithFrame:grayLineFrame] autorelease];
    grayLineView.backgroundColor = [UIColor twitchLightGrayColor];

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
    [view addSubview:grayLineView];

    return [view autorelease];
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

- (NSInteger)selectedBookmarkSegment
{
    return [self.searchBookmarksDisplayMgr selectedSegment];
}

- (void)setSelectedBookmarkSegment:(NSInteger)segment
{
    [self.searchBookmarksDisplayMgr setSelectedSegment:segment];
}

@end
