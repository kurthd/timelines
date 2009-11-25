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
    [contactCache release];
    [contactMgr release];
    [super dealloc];
}

- (id)initWithContext:(NSManagedObjectContext *)someContext
    findPeopleBookmarkMgr:(SavedSearchMgr *)aFindPeopleBookmarkMgr
    contactCache:(ContactCache *)aContactCache
    contactMgr:(ContactMgr *)aContactMgr
{
    if (self = [super init]) {
        context = [someContext retain];
        findPeopleBookmarkMgr = [aFindPeopleBookmarkMgr retain];
        contactCache = [aContactCache retain];
        contactMgr = [aContactMgr retain];
    }

    return self;
}

- (UserListDisplayMgr *)
    createUserListDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    navigationController:(UINavigationController *)navigationController
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
        initWithContext:context findPeopleBookmarkMgr:findPeopleBookmarkMgr
        contactCache:contactCache contactMgr:contactMgr]
        autorelease];

    UserListDisplayMgr * userListDisplayMgr =
        [[[UserListDisplayMgr alloc] initWithWrapperController:wrapperController
        navigationController:navigationController
        userListController:userListController service:service
        factory:self timelineFactory:timelineFactory
        managedObjectContext:context
        composeTweetDisplayMgr:composeTweetDisplayMgr
        findPeopleBookmarkMgr:findPeopleBookmarkMgr
        showFollowing:showFollowing username:username
        contactCache:contactCache contactMgr:contactMgr]
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
