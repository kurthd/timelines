//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserListDisplayMgr.h"
#import "ArbUserTimelineDataSource.h"
#import "UIAlertView+InstantiationAdditions.h"
#import "FavoritesTimelineDataSource.h"

@interface UserListDisplayMgr ()

@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain) UserListDisplayMgr * nextUserListDisplayMgr;
@property (nonatomic, retain)
    NetworkAwareViewController * nextWrapperController;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * credentialsPublisher;
@property (readonly) UserInfoViewController * userInfoController;
@property (readonly) TwitchBrowserViewController * browserController;
@property (readonly) PhotoBrowser * photoBrowser;
@property (nonatomic, copy) NSString * userInfoUsername;

- (void)deallocateNode;
- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error;
- (void)displayErrorWithTitle:(NSString *)title;
- (void)updateUserListViewWithUsers:(NSArray *)users page:(NSNumber *)page;
- (void)sendDirectMessageToCurrentUser;

@end

@implementation UserListDisplayMgr

@synthesize timelineDisplayMgr, nextUserListDisplayMgr, nextWrapperController,
    credentialsPublisher, userInfoUsername;

- (void)dealloc
{
    [wrapperController release];
    [userListController release];
    [service release];
    [userListDisplayMgrFactory release];
    [timelineDisplayMgrFactory release];
    [context release];
    [composeTweetDisplayMgr release];
    [findPeopleBookmarkMgr release];
    [username release];

    [timelineDisplayMgr release];
    [nextUserListDisplayMgr release];
    [nextWrapperController release];
    [credentialsPublisher release];
    [credentials release];
    [cache release];
    [userInfoController release];

    [super dealloc];
}

- (id)initWithWrapperController:(NetworkAwareViewController *)aWrapperController
    userListController:(UserListTableViewController *)aUserListController
    service:(TwitterService *)aService
    factory:(UserListDisplayMgrFactory *)userListFactory
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    managedObjectContext:(NSManagedObjectContext *)managedObjectContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr
    showFollowing:(BOOL)showFollowingValue username:(NSString *)aUsername
{
    if (self = [super init]) {
        wrapperController = [aWrapperController retain];
        userListController = [aUserListController retain];
        service = [aService retain];

        userListDisplayMgrFactory = [userListFactory retain];
        timelineDisplayMgrFactory = [timelineFactory retain];
        context = [managedObjectContext retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        findPeopleBookmarkMgr = [aFindPeopleBookmarkMgr retain];
        showFollowing = showFollowingValue;
        username = [aUsername retain];

        pagesShown = 1;
        failedState = NO;
        cache = [[NSMutableDictionary dictionary] retain];

        NSString * title =
            showFollowing ? 
            NSLocalizedString(@"userlisttableview.following.title", @"") :
            NSLocalizedString(@"userlisttableview.followers.title", @"");
        wrapperController.navigationItem.title = title;
    }

    return self;
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    if (!alreadyBeenDisplayed) {
        NSLog(@"Showing user list for first time");
        if (showFollowing) {
            NSLog(@"Querying for friends list");
            [service fetchFriendsForUser:username
                page:[NSNumber numberWithInt:pagesShown]];
        } else {
            NSLog(@"Querying for followers list");
            [service fetchFollowersForUser:username
                page:[NSNumber numberWithInt:pagesShown]];
        }

        [wrapperController setUpdatingState:kConnectedAndUpdating];
        alreadyBeenDisplayed = YES;
    }
}

#pragma mark UserListTableViewControllerDelegate implementation

- (void)showUserInfoForUser:(User *)aUser withAvatar:(UIImage *)avatar
{
    self.userInfoUsername = aUser.username;
    [userInfoController release];
    userInfoController = nil; // Forces to scroll to top
    self.userInfoController.navigationItem.title = aUser.name;
    [wrapperController.navigationController
        pushViewController:self.userInfoController animated:YES];
    self.userInfoController.followingEnabled =
        ![credentials.username isEqual:aUser.username];
    [self.userInfoController setUser:aUser avatarImage:avatar];
    if (self.userInfoController.followingEnabled)
        [service isUser:credentials.username following:aUser.username];
}

- (void)loadMoreUsers
{
    // Screw polymorphism -- too much work
    if (showFollowing)
        [service fetchFriendsForUser:username
            page:[NSNumber numberWithInt:++pagesShown]];
    else
        [service fetchFollowersForUser:username
            page:[NSNumber numberWithInt:++pagesShown]];

    [wrapperController setUpdatingState:kConnectedAndUpdating];
}

- (void)userListViewWillAppear
{
    [self deallocateNode];
}

#pragma mark TwitterServiceDelegate implementation

- (void)startedFollowingUsername:(NSString *)aUsername
{
    NSLog(@"Started following %@", aUsername);
}

- (void)failedToStartFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.startfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, aUsername];
    [self displayErrorWithTitle:errorMessage];
}

- (void)stoppedFollowingUsername:(NSString *)aUsername
{
    NSLog(@"Stopped following %@", aUsername);
}

- (void)failedToStopFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.stopfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, aUsername];
    [self displayErrorWithTitle:errorMessage];
}

- (void)friends:(NSArray *)friends fetchedForUsername:(NSString *)username
    page:(NSNumber *)page
{
    NSLog(@"Received friends list of size %d", [friends count]);
    if (showFollowing)
        [self updateUserListViewWithUsers:friends page:page];
}

- (void)failedToFetchFriendsForUsername:(NSString *)aUsername
    page:(NSNumber *)page error:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchfriends", @"");
    [self displayErrorWithTitle:errorMessage error:error];
    [wrapperController setUpdatingState:kDisconnected];
}

- (void)followers:(NSArray *)friends fetchedForUsername:(NSString *)aUsername
    page:(NSNumber *)page
{
    NSLog(@"Received followers list of size %d", [friends count]);
    if (!showFollowing)
        [self updateUserListViewWithUsers:friends page:page];
}

- (void)failedToFetchFollowersForUsername:(NSString *)aUsername
    page:(NSNumber *)page error:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchfollowers", @"");
    [self displayErrorWithTitle:errorMessage error:error];
    [wrapperController setUpdatingState:kDisconnected];
}

- (void)user:(NSString *)aUsername isFollowing:(NSString *)followee
{
    NSLog(@"%@ is following %@", aUsername, followee);
    [self.userInfoController setFollowing:YES];
}

- (void)user:(NSString *)aUsername isNotFollowing:(NSString *)followee
{
    NSLog(@"%@ is not following %@", aUsername, followee);
    [self.userInfoController setFollowing:NO];
}

- (void)failedToQueryIfUser:(NSString *)aUsername
    isFollowing:(NSString *)followee error:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.userquery", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, aUsername];
    [self displayErrorWithTitle:errorMessage];
}

#pragma mark UserInfoViewControllerDelegate implementation

- (void)showTweetsForUser:(NSString *)aUsername
{
    NSLog(@"Timeline display manager: showing tweets for %@", aUsername);

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

- (void)showLocationOnMap:(NSString *)locationString
{
    NSLog(@"User list display manager: showing %@ on map", locationString);
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

- (void)visitWebpage:(NSString *)webpageUrl
{
    NSLog(@"User list display manager: visiting webpage: %@", webpageUrl);
    [wrapperController presentModalViewController:self.browserController
        animated:YES];
    [self.browserController setUrl:webpageUrl];
}

- (void)showPhotoInBrowser:(RemotePhoto *)remotePhoto
{
    NSLog(@"User list display manager: showing photo: %@", remotePhoto);

    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
    [[UIApplication sharedApplication]
        setStatusBarStyle:UIStatusBarStyleBlackTranslucent
        animated:YES];

    [wrapperController presentModalViewController:self.photoBrowser
        animated:YES];
    [self.photoBrowser addRemotePhoto:remotePhoto];
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
}

- (void)displayFollowingForUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: displaying 'following' list for %@",
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

    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)displayFollowersForUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: displaying 'followers' list for %@",
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

    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)displayFavoritesForUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: displaying favorites for user %@",
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
    [wrapperController.navigationController
        pushViewController:self.nextWrapperController animated:YES];
}

- (void)startFollowingUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: sending 'follow user' request for %@",
        aUsername);
    [service followUser:aUsername];
}

- (void)stopFollowingUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: sending 'stop following' request for %@",
        aUsername);
    [service stopFollowingUser:aUsername];
}

- (void)showingUserInfoView
{
    // do nothing
}

- (void)sendDirectMessageToUser:(NSString *)aUsername
{
    NSLog(@"User list display manager: sending direct message to %@",
        aUsername);
    [composeTweetDisplayMgr composeDirectMessageTo:aUsername];
}

#pragma mark TwitchBrowserViewControllerDelegate implementation

- (void)composeTweetWithText:(NSString *)text
{
    NSLog(@"Timeline display manager: composing tweet with text'%@'", text);
    [composeTweetDisplayMgr composeTweetWithText:text];
}

#pragma mark UserListDisplayMgr implementation

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"User list display manager: setting credentials: %@",
        someCredentials);

    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:someCredentials];
}

- (void)refreshWithCurrentPages
{
    NSLog(@"User list display manager: refreshing with current pages...");
    if([service credentials] && username) {
        alreadyBeenDisplayed = YES;
        if (showFollowing)
            [service fetchFriendsForUser:username
                page:[NSNumber numberWithInt:pagesShown]];
        else
            [service fetchFollowersForUser:username
                page:[NSNumber numberWithInt:pagesShown]];
    } else
        NSLog(@"User list display manager: not updating - nil credentials");
    [wrapperController setUpdatingState:kConnectedAndUpdating];
}

#pragma mark Private helper methods

- (void)deallocateNode
{
    self.timelineDisplayMgr = nil;
    self.nextUserListDisplayMgr = nil;
    self.nextWrapperController = nil;
    self.credentialsPublisher = nil;
}

- (void)displayErrorWithTitle:(NSString *)title error:(NSError *)error
{
    if (!failedState) {
        NSString * message = error.localizedDescription;
        UIAlertView * alertView =
            [UIAlertView simpleAlertViewWithTitle:title message:message];
        [alertView show];

        failedState = YES;
    }
    [wrapperController setUpdatingState:kDisconnected];
}

- (void)displayErrorWithTitle:(NSString *)title
{
    NSLog(@"User list display manager: displaying error with title: %@", title);

    UIAlertView * alertView =
        [UIAlertView simpleAlertViewWithTitle:title message:nil];
    [alertView show];
}

- (void)updateUserListViewWithUsers:(NSArray *)users page:(NSNumber *)page
{
    NSLog(@"Received user list of size %d", [users count]);
    NSInteger oldCacheSize = [[cache allKeys] count];
    for (User * friend in users)
        [cache setObject:friend forKey:friend.username];
    NSInteger newCacheSize = [[cache allKeys] count];
    BOOL allLoaded = oldCacheSize == newCacheSize;
    [userListController setAllPagesLoaded:allLoaded];
    [userListController setUsers:[cache allValues] page:[page intValue]];
    [wrapperController setCachedDataAvailable:YES];
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    failedState = NO;
}

- (UserInfoViewController *)userInfoController
{
    if (!userInfoController) {
        userInfoController =
            [[UserInfoViewController alloc]
            initWithNibName:@"UserInfoView" bundle:nil];

        userInfoController.findPeopleBookmarkMgr = findPeopleBookmarkMgr;

        UIBarButtonItem * rightBarButton =
            [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self
            action:@selector(sendDirectMessageToCurrentUser)];
        userInfoController.navigationItem.rightBarButtonItem = rightBarButton;

        userInfoController.delegate = self;
    }

    return userInfoController;
}

- (TwitchBrowserViewController *)browserController
{
    if (!browserController) {
        browserController =
            [[TwitchBrowserViewController alloc]
            initWithNibName:@"TwitchBrowserView" bundle:nil];
        browserController.delegate = self;
    }

    return browserController;
}

- (PhotoBrowser *)photoBrowser
{
    if (!photoBrowser) {
        photoBrowser =
            [[PhotoBrowser alloc]
            initWithNibName:@"PhotoBrowserView" bundle:nil];
        photoBrowser.delegate = self;
    }

    return photoBrowser;
}

- (void)sendDirectMessageToCurrentUser
{
    NSLog(@"User list display manager: sending direct message to %@",
        self.userInfoUsername);
    [composeTweetDisplayMgr composeDirectMessageTo:self.userInfoUsername];
}

@end
