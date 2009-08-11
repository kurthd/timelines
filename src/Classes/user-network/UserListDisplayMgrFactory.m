//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "UserListDisplayMgrFactory.h"
#import "TwitterService.h"
#import "CredentialsActivatedPublisher.h"

@implementation UserListDisplayMgrFactory

- (void)dealloc
{
    [context release];
    [findPeopleBookmarkMgr release];
    [super dealloc];
}

- (id)initWithContext:(NSManagedObjectContext *)someContext
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr
{
    if (self = [super init]) {
        context = [someContext retain];
        findPeopleBookmarkMgr = [aFindPeopleBookmarkMgr retain];
    }

    return self;
}

- (UserListDisplayMgr *)
    createUserListDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    showFollowing:(BOOL)showFollowing username:(NSString *)username
{
    UserListTableViewController * userListController =
        [[[UserListTableViewController alloc]
        initWithNibName:@"UserListTableView" bundle:nil] autorelease];
    wrapperController.targetViewController = userListController;

    TwitterService * service =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];

    TimelineDisplayMgrFactory * timelineFactory =
        [[[TimelineDisplayMgrFactory alloc]
        initWithContext:context findPeopleBookmarkMgr:findPeopleBookmarkMgr]
        autorelease];

    UserListDisplayMgr * userListDisplayMgr =
        [[[UserListDisplayMgr alloc] initWithWrapperController:wrapperController
        userListController:userListController service:service
        factory:self timelineFactory:timelineFactory
        managedObjectContext:context
        composeTweetDisplayMgr:composeTweetDisplayMgr
        findPeopleBookmarkMgr:findPeopleBookmarkMgr
        showFollowing:showFollowing username:username]
        autorelease];
    userListController.delegate = userListDisplayMgr;
    service.delegate = userListDisplayMgr;
    wrapperController.delegate = userListDisplayMgr;

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:userListDisplayMgr action:@selector(setCredentials:)];

    return userListDisplayMgr;
}
    
@end
