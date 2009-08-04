//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "FindPeopleSearchDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface FindPeopleSearchDisplayMgr ()

@property (nonatomic, retain) UIView * darkTransparentView;

- (void)showError:(NSError *)error;
- (void)showDarkTransparentView;
- (void)hideDarkTransparentView;
- (void)displayBookmarksView;

- (void)searchForQuery:(NSString *)query;

@property (nonatomic, readonly)
    FindPeopleBookmarkViewController * bookmarkController;
@property (nonatomic, retain) RecentSearchMgr * recentSearchMgr;

@end

@implementation FindPeopleSearchDisplayMgr

@synthesize darkTransparentView;
@synthesize recentSearchMgr;

- (void)dealloc
{
    [netAwareController release];
    [searchBar release];
    [timelineDisplayMgr release];
    [dataSource release];
    [darkTransparentView release];
    [bookmarkController release];
    [recentSearchMgr release];
    [savedSearchMgr release];
    [context release];
    [super dealloc];
}

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    timelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr
    dataSource:(ArbUserTimelineDataSource *)aDataSource
    context:(NSManagedObjectContext *)aContext
    savedSearchMgr:(SavedSearchMgr *)aSavedSearchMgr
{
    if (self = [super init]) {
        netAwareController = [navc retain];
        dataSource = [aDataSource retain];
        context = [aContext retain];
        savedSearchMgr = [aSavedSearchMgr retain];
        
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

        timelineDisplayMgr = [aTimelineDisplayMgr retain];
        timelineDisplayMgr.suppressTimelineFailures = YES;

        [netAwareController setUpdatingState:kDisconnected];
        [netAwareController setCachedDataAvailable:NO];
        [netAwareController setNoConnectionText:@""];
    }

    return self;
}

#pragma mark UISearchBarDelegate implementation

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    [self hideDarkTransparentView];

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

    dataSource.username = searchName;
    timelineDisplayMgr.currentUsername = searchName;
    [timelineDisplayMgr setService:dataSource tweets:[NSDictionary dictionary]
        page:1 forceRefresh:YES allPagesLoaded:NO];
    [timelineDisplayMgr refreshWithCurrentPages];

    UITableViewController * tvc =
        (UITableViewController *)netAwareController.targetViewController;
    tvc.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    tvc.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar
{
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    [self hideDarkTransparentView];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)aSearchBar
{
    [self showDarkTransparentView];
    [searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)aSearchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    return YES;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)aSearchBar
{
    [self displayBookmarksView];
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

    [self searchForQuery:query];
}

- (void)userDidCancel
{
    [netAwareController dismissModalViewControllerAnimated:YES];
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

@end
