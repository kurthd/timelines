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

@end

@implementation FindPeopleSearchDisplayMgr

@synthesize darkTransparentView;

- (void)dealloc
{
    [netAwareController release];
    [searchBar release];
    [timelineDisplayMgr release];
    [dataSource release];
    [darkTransparentView release];
    [super dealloc];
}

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    timelineDisplayMgr:(TimelineDisplayMgr *)aTimelineDisplayMgr
    dataSource:(ArbUserTimelineDataSource *)aDataSource
{
    if (self = [super init]) {
        netAwareController = [navc retain];
        dataSource = [aDataSource retain];

        searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];

        searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
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

- (void)searchBarViewWillAppear:(BOOL)promptUser
{
    // if (!self.searchQuery) {
    //     [netAwareController setUpdatingState:kDisconnected];
    //     [netAwareController setCachedDataAvailable:NO];
    //     [netAwareController setNoConnectionText:@""];
    // 
    //     if (promptUser) {
    //         [self.searchBar becomeFirstResponder];
    //         // [self showDarkTransparentView];
    //     }
    // }
}

#pragma mark UISearchBarDelegate implementation

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    [self hideDarkTransparentView];

    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];

    [netAwareController setUpdatingState:kConnectedAndUpdating];
    [netAwareController setCachedDataAvailable:NO];
    NSString * noConnFormatString =
        NSLocalizedString(@"findpeople.nouser", @"");
    NSString * noConnText =
        [searchBar.text isEqual:@""] ? @"" :
        [NSString stringWithFormat:noConnFormatString, searchBar.text];
    NSLog(@"No conn text: %@", noConnText);
    [netAwareController setNoConnectionText:noConnText];

    dataSource.username = searchBar.text;
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
