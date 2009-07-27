//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchBarDisplayMgr.h"
#import "SearchBookmarksDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"

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
@property (nonatomic, copy) NSString * searchQuery;
@property (nonatomic, copy) NSNumber * searchPage;

@property (nonatomic, retain) CredentialsActivatedPublisher *
    credentialsActivatedPublisher;

@property (nonatomic, retain) UIView * darkTransparentView;

- (void)displayBookmarksView;

- (void)showError:(NSError *)error;
- (void)showDarkTransparentView;
- (void)hideDarkTransparentView;

- (UIView *)saveSearchView;
- (UIView *)removeSearchView;
- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title
                                   action:(SEL)action;

@end

@implementation SearchBarDisplayMgr

@synthesize service, context;
@synthesize searchBar, networkAwareViewController;
@synthesize timelineDisplayMgr, searchDisplayMgr, searchBookmarksDisplayMgr;
@synthesize searchResults, searchQuery, searchPage;
@synthesize dataSourceDelegate, credentialsActivatedPublisher;
@synthesize darkTransparentView;

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
    [self.service setCredentials:credentials];
    [self.searchDisplayMgr setCredentials:credentials];
    [self.timelineDisplayMgr setCredentials:credentials];

    self.searchBookmarksDisplayMgr = nil;
    self.searchBar.text = @"";
    self.searchResults = nil;
    self.searchQuery = nil;
    self.searchPage = nil;
    [self.searchDisplayMgr clearDisplay];
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
    [self hideDarkTransparentView];

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
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)aSearchBar
{
    [self showDarkTransparentView];
    [self.searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    [self.searchBar setShowsCancelButton:NO animated:YES];
    return YES;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar
{
    [self displayBookmarksView];
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

#pragma mark Accessors

- (SearchBookmarksDisplayMgr *)searchBookmarksDisplayMgr
{
    if (!searchBookmarksDisplayMgr) {
        NSString * accountName = self.service.credentials.username;
        searchBookmarksDisplayMgr =
            [[SearchBookmarksDisplayMgr alloc] initWithAccountName:accountName
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

@end
