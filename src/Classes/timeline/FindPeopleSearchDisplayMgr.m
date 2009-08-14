//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "FindPeopleSearchDisplayMgr.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "FavoritesTimelineDataSource.h"
#import "ArbUserTimelineDataSource.h"
#import "UIAlertView+InstantiationAdditions.h"

@interface FindPeopleSearchDisplayMgr ()

@property (nonatomic, retain) UIView * darkTransparentView;

- (void)showError:(NSError *)error;
- (void)showDarkTransparentView;
- (void)hideDarkTransparentView;
- (void)displayBookmarksView;
- (void)searchForQuery:(NSString *)query;
- (void)displayErrorWithTitle:(NSString *)title;

@property (nonatomic, readonly)
    FindPeopleBookmarkViewController * bookmarkController;
@property (nonatomic, retain) RecentSearchMgr * recentSearchMgr;

@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * nextWrapperController;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * credentialsPublisher;
@property (nonatomic, retain) UserListDisplayMgr * nextUserListDisplayMgr;

@end

@implementation FindPeopleSearchDisplayMgr

@synthesize darkTransparentView;
@synthesize recentSearchMgr;
@synthesize timelineDisplayMgr, nextWrapperController, credentialsPublisher,
    nextUserListDisplayMgr;

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

#pragma mark TwitterServiceDelegate implementation

- (void)userInfo:(User *)user fetchedForUsername:(NSString *)username
{
    NSLog(@"Fetched user info for '%@'", username);
    [netAwareController setUpdatingState:kConnectedAndNotUpdating];
    [netAwareController setCachedDataAvailable:YES];
    [userInfoController setUser:user];
}

- (void)failedToFetchUserInfoForUsername:(NSString *)username
    error:(NSError *)error
{
    NSLog(@"Unable to find user '%@'", username);
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
    NSLog(@"Find people display manager: failed to query if %@ is following %@",
        username, followee);
    NSLog(@"Error: %@", error);
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.userquery", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, username];
    [self displayErrorWithTitle:errorMessage];
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
    NSString * locationWithoutCommas =
        [locationString stringByReplacingOccurrencesOfString:@"iPhone:"
        withString:@""];
    NSString * urlString =
        [[NSString
        stringWithFormat:@"http://maps.google.com/maps?q=%@",
        locationWithoutCommas]
        stringByAddingPercentEscapesUsingEncoding:
        NSUTF8StringEncoding];
    NSURL * url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url];
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

- (void)showingUserInfoView
{
    self.nextWrapperController = nil;
    self.timelineDisplayMgr = nil;
    self.credentialsPublisher = nil;
    self.nextUserListDisplayMgr = nil;
}

- (void)sendDirectMessageToUser:(NSString *)aUsername
{
    [composeTweetDisplayMgr composeDirectMessageTo:aUsername];
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

#pragma mark FindPeopleSearchDisplayMgr implementation

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"Find people display manager: setting credentials: %@",
        someCredentials);

    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:someCredentials];
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

- (void)displayErrorWithTitle:(NSString *)title
{
    NSLog(@"Timeline display manager: displaying error with title: %@", title);

    UIAlertView * alertView =
        [UIAlertView simpleAlertViewWithTitle:title message:nil];
    [alertView show];
}

@end
