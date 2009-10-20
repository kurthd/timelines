//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "DisplayMgrHelper.h"
#import "FavoritesTimelineDataSource.h"
#import "ArbUserTimelineDataSource.h"
#import "SearchDataSource.h"
#import "RotatableTabBarController.h"
#import "SettingsReader.h"
#import "UIColor+TwitchColors.h"
#import "NearbySearchDataSource.h"

@interface DisplayMgrHelper ()

@property (nonatomic, readonly)
    LocationMapViewController * locationMapViewController;
@property (nonatomic, readonly)
    LocationInfoViewController * locationInfoViewController;
@property (nonatomic, readonly) SavedSearchMgr * savedSearchMgr;

@property (nonatomic, retain)
    NetworkAwareViewController * userListNetAwareViewController;
@property (nonatomic, retain) UserListDisplayMgr * userListDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * nextWrapperController;
@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * credentialsPublisher;
@property (nonatomic, copy) NSString * currentSearch;

- (UIView *)saveSearchView;
- (UIView *)removeSearchView;
- (UIView *)toggleSaveSearchViewWithTitle:(NSString *)title action:(SEL)action;

@end

@implementation DisplayMgrHelper

@synthesize userListNetAwareViewController, userListDisplayMgr,
    nextWrapperController, timelineDisplayMgr, credentialsPublisher,
    currentSearch;

- (void)dealloc
{
    [wrapperController release];
    [userListDisplayMgrFactory release];
    [composeTweetDisplayMgr release];
    [timelineDisplayMgrFactory release];
    [context release];

    [credentials release];

    [locationMapViewController release];
    [locationInfoViewController release];
    [savedSearchMgr release];

    [userListNetAwareViewController release];
    [userListDisplayMgr release];
    [nextWrapperController release];
    [timelineDisplayMgr release];
    [credentialsPublisher release];
    [currentSearch release];

    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)wrapperCtrlr
    userListDisplayMgrFactor:(UserListDisplayMgrFactory *)userListDispMgrFctry
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    twitterService:(TwitterService *)aService
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (self = [super init]) {
        wrapperController = [wrapperCtrlr retain];
        userListDisplayMgrFactory = [userListDispMgrFctry retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        service = [aService retain];
        timelineDisplayMgrFactory = [timelineFactory retain];
        context = [managedObjectContext retain];
    }

    return self;
}

#pragma mark UserInfoViewControllerDelegate implementation

- (void)showLocationOnMap:(NSString *)locationString
{
    NSLog(@"Showing %@ on map", locationString);

    self.locationMapViewController.navigationItem.title = @"Map";

    [wrapperController.navigationController
        pushViewController:self.locationMapViewController animated:YES];

    [self.locationMapViewController setLocation:locationString];
}

- (void)displayFollowingForUser:(NSString *)aUsername
{
    NSLog(@"Displaying 'following' list for %@", aUsername);

    self.userListNetAwareViewController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.userListDisplayMgr =
        [userListDisplayMgrFactory
        createUserListDisplayMgrWithWrapperController:
        self.userListNetAwareViewController
        composeTweetDisplayMgr:composeTweetDisplayMgr
        showFollowing:YES
        username:aUsername];
    [self.userListDisplayMgr setCredentials:credentials];

    [wrapperController.navigationController
        pushViewController:self.userListNetAwareViewController animated:YES];
}

- (void)displayFollowersForUser:(NSString *)aUsername
{
    NSLog(@"Displaying 'followers' list for %@", aUsername);

    self.userListNetAwareViewController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    self.userListDisplayMgr =
        [userListDisplayMgrFactory
        createUserListDisplayMgrWithWrapperController:
        self.userListNetAwareViewController
        composeTweetDisplayMgr:composeTweetDisplayMgr
        showFollowing:NO
        username:aUsername];
    [self.userListDisplayMgr setCredentials:credentials];

    [wrapperController.navigationController
        pushViewController:self.userListNetAwareViewController animated:YES];
}

- (void)displayFavoritesForUser:(NSString *)aUsername
{
    NSLog(@"Displaying 'followers' list for %@", aUsername);
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
    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)showTweetsForUser:(NSString *)aUsername
{
    NSLog(@"Showing tweets for %@", aUsername);

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

    wrapperController.delegate = self.timelineDisplayMgr;
    
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
    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)startFollowingUser:(NSString *)aUsername
{
    NSLog(@"Sending 'follow user' request for %@", aUsername);
    [service followUser:aUsername];
}

- (void)stopFollowingUser:(NSString *)aUsername
{
    NSLog(@"Sending 'stop following' request for %@", aUsername);
    [service stopFollowingUser:aUsername];
}

- (void)blockUser:(NSString *)aUsername
{
    [service blockUserWithUsername:aUsername];
}

- (void)unblockUser:(NSString *)aUsername
{
    [service unblockUserWithUsername:aUsername];
}

- (void)showingUserInfoView
{

}

- (void)sendDirectMessageToUser:(NSString *)aUsername
{
    NSLog(@"Sending direct message to %@", aUsername);
    [composeTweetDisplayMgr composeDirectMessageTo:aUsername];
}

- (void)sendPublicMessageToUser:(NSString *)aUsername
{
    NSLog(@"Sending public message to %@", aUsername);
    [composeTweetDisplayMgr
        composeTweetWithText:[NSString stringWithFormat:@"@%@ ", aUsername]];
}

- (void)showResultsForSearch:(NSString *)query
{
    NSLog(@"Showing search results for '%@'", query);
    self.currentSearch = query;

    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];
    
    self.timelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:
        self.nextWrapperController
        title:query composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.timelineDisplayMgr.displayAsConversation = NO;
    self.timelineDisplayMgr.setUserToFirstTweeter = NO;
    self.timelineDisplayMgr.currentUsername = nil;
    UIView * headerView =
        [self.savedSearchMgr isSearchSaved:query] ?
        [self removeSearchView] : [self saveSearchView];
    [self.timelineDisplayMgr setTimelineHeaderView:headerView];
    [self.timelineDisplayMgr setCredentials:credentials];
    self.nextWrapperController.navigationItem.rightBarButtonItem = nil;
    
    self.nextWrapperController.delegate = self.timelineDisplayMgr;
    
    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
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
    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

#pragma mark LocationMapViewControllerDelegate implementation

- (void)showLocationInfo:(NSString *)locationString
    coordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"Showing location info for %@", locationString);

    [wrapperController.navigationController
        pushViewController:self.locationInfoViewController animated:YES];

    [self.locationInfoViewController setLocationString:locationString
        coordinate:coordinate];
}

#pragma mark LocationInfoViewControllerDelegate implementation

- (void)showResultsForNearbySearchWithLatitude:(NSNumber *)latitude
    longitude:(NSNumber *)longitude
{
    NSLog(@"Showing results for nearby search");

    self.nextWrapperController =
        [[[NetworkAwareViewController alloc]
        initWithTargetViewController:nil] autorelease];

    NSString * title =
        NSLocalizedString(@"timelinedisplaymgr.nearbysearch", @"");
    self.timelineDisplayMgr =
        [timelineDisplayMgrFactory
        createTimelineDisplayMgrWithWrapperController:self.nextWrapperController
        title:title composeTweetDisplayMgr:composeTweetDisplayMgr];
    self.timelineDisplayMgr.displayAsConversation = NO;
    self.timelineDisplayMgr.setUserToFirstTweeter = NO;
    self.timelineDisplayMgr.currentUsername = nil;

    [self.timelineDisplayMgr setCredentials:credentials];
    self.nextWrapperController.navigationItem.rightBarButtonItem = nil;

    self.nextWrapperController.delegate = self.timelineDisplayMgr;

    TwitterService * twitterService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil context:context]
        autorelease];

    NSNumber * radius =
        [NSNumber numberWithInt:[SettingsReader nearbySearchRadius]];

    NearbySearchDataSource * dataSource =
        [[[NearbySearchDataSource alloc]
        initWithTwitterService:twitterService
        latitude:latitude longitude:longitude radiusInKm:radius]
        autorelease];

    self.credentialsPublisher =
        [[CredentialsActivatedPublisher alloc]
        initWithListener:dataSource action:@selector(setCredentials:)];

    twitterService.delegate = dataSource;
    [self.timelineDisplayMgr setService:dataSource tweets:nil page:1
        forceRefresh:NO allPagesLoaded:NO];
    dataSource.delegate = self.timelineDisplayMgr;

    [dataSource setCredentials:credentials];
    [wrapperController.navigationController
        pushViewController:self.nextWrapperController
        animated:YES];
}

#pragma mark Public interface implementation

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;
}

#pragma mark Private helpers

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

- (SavedSearchMgr *)savedSearchMgr
{
    if (!savedSearchMgr)
        savedSearchMgr =
            [[SavedSearchMgr alloc]
            initWithAccountName:credentials.username context:context];

    return savedSearchMgr;
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

@end
