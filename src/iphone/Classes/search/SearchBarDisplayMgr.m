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

- (void)showError:(NSError *)error;

@end

@implementation SearchBarDisplayMgr

@synthesize service, networkAwareViewController;
@synthesize searchBar;
@synthesize timelineDisplayMgr, searchDisplayMgr;
@synthesize searchResults, searchQuery, searchPage;
@synthesize dataSourceDelegate, credentialsActivatedPublisher;

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
            self.networkAwareViewController.view.bounds.size.width, barHeight);
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
                               forceRefresh:NO];
        self.searchDisplayMgr.dataSourceDelegate = self.timelineDisplayMgr;
    }

    return self;
}

- (void)setCredentials:(TwitterCredentials *)credentials
{
    [self.service setCredentials:credentials];
    [self.searchDisplayMgr setCredentials:credentials];
    [self.timelineDisplayMgr setCredentials:credentials];
}

#pragma mark UISearchBarDelegate implementation

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSarchBar
{
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
                           forceRefresh:YES];
    UITableViewController * tvc = (UITableViewController *)
        self.networkAwareViewController.targetViewController;
    tvc.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    tvc.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [self.searchBar resignFirstResponder];
    [self.searchBar setShowsCancelButton:NO animated:YES];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)aSearchBar
{
    [self.searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}

#pragma mark UI helpers

- (void)showError:(NSError *)error
{
    NSString * title = NSLocalizedString(@"search.fetch.failed", @"");
    NSString * message = error.localizedDescription;

    [[UIAlertView simpleAlertViewWithTitle:title message:message] show];
    
}

@end
