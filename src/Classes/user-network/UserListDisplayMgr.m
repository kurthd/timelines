//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserListDisplayMgr.h"
#import "ErrorState.h"
#import "DisplayMgrHelper.h"

@interface UserListDisplayMgr ()

@property (nonatomic, retain) TimelineDisplayMgr * timelineDisplayMgr;
@property (nonatomic, retain) UserListDisplayMgr * nextUserListDisplayMgr;
@property (nonatomic, retain)
    CredentialsActivatedPublisher * credentialsPublisher;

- (void)deallocateNode;
- (void)updateUserListViewWithUsers:(NSArray *)users cursor:(NSString *)cursor;
- (void)sendDirectMessageToCurrentUser;

@end

@implementation UserListDisplayMgr

@synthesize timelineDisplayMgr, nextUserListDisplayMgr, credentialsPublisher;

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

    [displayMgrHelper release];

    [timelineDisplayMgr release];
    [nextUserListDisplayMgr release];
    [credentialsPublisher release];
    [credentials release];
    [cursor release];
    [cache release];

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

        TwitterService * displayHelperService =
            [[[TwitterService alloc]
            initWithTwitterCredentials:service.credentials
            context:managedObjectContext]
            autorelease];

        displayMgrHelper =
            [[DisplayMgrHelper alloc]
            initWithWrapperController:aWrapperController
            userListDisplayMgrFactor:userListFactory
            composeTweetDisplayMgr:composeTweetDisplayMgr
            twitterService:displayHelperService
            timelineFactory:timelineFactory
            managedObjectContext:managedObjectContext
            findPeopleBookmarkMgr:aFindPeopleBookmarkMgr];
        displayHelperService.delegate = displayMgrHelper;

        cursor = @"-1";  // per Twitter's documentation
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
            [service fetchFriendsForUser:username cursor:cursor];
        } else {
            NSLog(@"Querying for followers list");
            [service fetchFollowersForUser:username cursor:cursor];
        }

        [wrapperController setUpdatingState:kConnectedAndUpdating];
        alreadyBeenDisplayed = YES;
    }
}

#pragma mark UserListTableViewControllerDelegate implementation

- (void)showUserInfoForUser:(User *)aUser
{
    [displayMgrHelper showUserInfoForUser:aUser];
}

- (void)loadMoreUsers
{
    // Screw polymorphism -- too much work
    if (showFollowing)
        [service fetchFriendsForUser:username cursor:cursor];
    else
        [service fetchFollowersForUser:username cursor:cursor];

    [wrapperController setUpdatingState:kConnectedAndUpdating];
}

- (void)userListViewWillAppear
{
    [self deallocateNode];
}

- (void)sendDirectMessageToCurrentUser
{
    [displayMgrHelper sendDirectMessageToCurrentUser];
}

#pragma mark TwitterServiceDelegate implementation

- (void)failedToStopFollowingUsername:(NSString *)aUsername
    error:(NSError *)error
{
    NSString * errorMessageFormatString =
        NSLocalizedString(@"timelinedisplaymgr.error.stopfollowing", @"");
    NSString * errorMessage =
        [NSString stringWithFormat:errorMessageFormatString, aUsername];
    [[ErrorState instance] displayErrorWithTitle:errorMessage];
}

- (void)friends:(NSArray *)friends fetchedForUsername:(NSString *)username
    cursor:(NSString *)currentCursor nextCursor:(NSString *)nextCursor
{
    NSLog(@"Received friends list of size %d", [friends count]);

    [cursor release];
    cursor = [nextCursor copy];

    if (showFollowing)
        [self updateUserListViewWithUsers:friends cursor:cursor];
}

- (void)failedToFetchFriendsForUsername:(NSString *)aUsername
    cursor:(NSString *)cursor error:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchfriends", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
    [wrapperController setUpdatingState:kDisconnected];
}

- (void)followers:(NSArray *)friends fetchedForUsername:(NSString *)aUsername
    cursor:(NSString *)currentCursor nextCursor:(NSString *)nextCursor
{
    NSLog(@"Received followers list of size %d", [friends count]);

    [cursor release];
    cursor = [nextCursor copy];

    if (!showFollowing)
        [self updateUserListViewWithUsers:friends cursor:cursor];
}

- (void)failedToFetchFollowersForUsername:(NSString *)aUsername
    cursor:(NSString *)cursor error:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSString * errorMessage =
        NSLocalizedString(@"timelinedisplaymgr.error.fetchfollowers", @"");
    [[ErrorState instance] displayErrorWithTitle:errorMessage error:error];
    [wrapperController setUpdatingState:kDisconnected];
}

#pragma mark UserListDisplayMgr implementation

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    NSLog(@"User list display manager: setting credentials: %@",
        someCredentials.username);

    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;

    [service setCredentials:someCredentials];
    [displayMgrHelper setCredentials:credentials];
}

- (void)refreshWithCurrentPages
{
    NSLog(@"User list display manager: refreshing with current pages...");
    if([service credentials] && username) {
        alreadyBeenDisplayed = YES;
        if (showFollowing)
            [service fetchFriendsForUser:username cursor:cursor];
        else
            [service fetchFollowersForUser:username cursor:cursor];
    } else
        NSLog(@"User list display manager: not updating - nil credentials");
    [wrapperController setUpdatingState:kConnectedAndUpdating];
}

#pragma mark Private helper methods

- (void)deallocateNode
{
    self.timelineDisplayMgr = nil;
    self.nextUserListDisplayMgr = nil;
    self.credentialsPublisher = nil;
}

- (void)updateUserListViewWithUsers:(NSArray *)users cursor:(NSString *)aCursor
{
    NSLog(@"Received user list of size %d", [users count]);
    for (User * friend in users)
        [cache setObject:friend forKey:friend.username];
    BOOL allLoaded = [aCursor isEqualToString:@"0"];
    [userListController setAllPagesLoaded:allLoaded];
    [userListController setUsers:[cache allValues]];
    [wrapperController setUpdatingState:kConnectedAndNotUpdating];
    [wrapperController setCachedDataAvailable:YES];
    failedState = NO;
}

@end
