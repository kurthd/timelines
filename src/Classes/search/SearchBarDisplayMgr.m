//
//  Copyright High Order Bit, Inc. 2009. All rights reserved.
//

#import "SearchBarDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface SearchBarDisplayMgr ()

@property (nonatomic, retain) TwitterService * service;

@property (nonatomic, retain) NetworkAwareViewController *
    networkAwareViewController;
@property (nonatomic, retain) UISearchBar * searchBar;

@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain) SearchDisplayMgr * searchDisplayMgr;

@property (nonatomic, copy) NSArray * searchResults;
@property (nonatomic, copy) NSString * searchQuery;
@property (nonatomic, copy) NSNumber * searchPage;

@property (nonatomic, retain) CredentialsActivatedPublisher *
    credentialsActivatedPublisher;

@property (nonatomic, retain) UIView * darkTransparentView;

- (void)showError:(NSError *)error;
- (void)showDarkTransparentView;
- (void)hideDarkTransparentView;

@end

@implementation SearchBarDisplayMgr

@synthesize service, networkAwareViewController;
@synthesize searchBar;
@synthesize timelineDisplayMgr, searchDisplayMgr;
@synthesize searchResults, searchQuery, searchPage;
@synthesize dataSourceDelegate, credentialsActivatedPublisher;
@synthesize darkTransparentView;

#pragma mark Initialization

- (void)dealloc
{
    self.service = nil;
    self.networkAwareViewController = nil;
    self.searchBar = nil;
    self.timelineDisplayMgr = nil;
    self.searchDisplayMgr = nil;
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
{
    if (self = [super init]) {
        self.service = aService;
        self.service.delegate = self;

        self.networkAwareViewController = navc;
        
        UINavigationItem * navItem =
            self.networkAwareViewController.navigationItem;
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];

        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
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
            initWithListener:searchDisplayMgr
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

    NSLog(@"Searching Twitter for: '%@'...", self.searchQuery);
    [self.searchDisplayMgr displaySearchResults:self.searchQuery
                                      withTitle:self.searchQuery];
    [self.timelineDisplayMgr setService:self.searchDisplayMgr
                                 tweets:nil
                                   page:[self.searchPage integerValue]
                           forceRefresh:YES
                         allPagesLoaded:NO];
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

@end
