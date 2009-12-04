//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "ProfileDisplayMgr.h"

@implementation ProfileDisplayMgr

- (void)dealloc
{
    [netAwareController release];
    [userInfoController release];
    [service release];
    [userListDisplayMgr release];
    [timelineDisplayMgrFactory release];
    [userListDisplayMgrFactory release];
    [context release];
    [composeTweetDisplayMgr release];
    [navigationController release];
    [super dealloc];
}

- (id)initWithNetAwareController:(NetworkAwareViewController *)navc
    userInfoController:(UserInfoViewController *)aUserInfoController
    service:(TwitterService *)aService
    context:(NSManagedObjectContext *)aContext
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)aComposeTweetDisplayMgr
    timelineFactory:(TimelineDisplayMgrFactory *)timelineFactory
    userListFactory:(UserListDisplayMgrFactory *)aUserListFactory
    navigationController:(UINavigationController *)aNavigationController
{
    if (self = [super init]) {
        netAwareController = [navc retain];
        userInfoController = [aUserInfoController retain];
        service = [aService retain];
        context = [aContext retain];
        composeTweetDisplayMgr = [aComposeTweetDisplayMgr retain];
        timelineDisplayMgrFactory = [timelineFactory retain];
        userListDisplayMgrFactory = [aUserListFactory retain];
        navigationController = [aNavigationController retain];
    }

    return self;
}

#pragma mark NetworkAwareViewControllerDelegate implementation

- (void)networkAwareViewWillAppear
{
    NSLog(@"Profile view will appear");
}

#pragma mark TwitterServiceDelegate implementation

#pragma mark UserInfoViewControllerDelegate implementation

- (void)showLocationOnMap:(NSString *)location
{
    
}

- (void)displayFollowingForUser:(NSString *)username
{
    
}

- (void)displayFollowersForUser:(NSString *)username
{
    
}

- (void)displayFavoritesForUser:(NSString *)username
{
    
}

- (void)showTweetsForUser:(NSString *)username
{
    
}

- (void)startFollowingUser:(NSString *)username
{
    
}

- (void)stopFollowingUser:(NSString *)username
{
    
}

- (void)blockUser:(NSString *)username
{
    
}

- (void)unblockUser:(NSString *)username
{
    
}

- (void)showingUserInfoView
{
    
}

- (void)sendDirectMessageToUser:(NSString *)username
{
    
}

- (void)sendPublicMessageToUser:(NSString *)username
{
    
}

- (void)showResultsForSearch:(NSString *)query
{
    
}

#pragma mark ProfileDisplayMgr implementation

- (void)refreshProfile
{
    
}

- (void)setCredentials:(TwitterCredentials *)someCredentials
{
    [someCredentials retain];
    [credentials release];
    credentials = someCredentials;
}
    
@end
