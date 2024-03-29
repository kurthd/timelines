//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageDisplayMgrFactory.h"
#import "DirectMessageInboxViewController.h"
#import "TwitterService.h"
#import "CredentialsActivatedPublisher.h"
#import "UserListDisplayMgrFactory.h"

@implementation DirectMessageDisplayMgrFactory

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

- (DirectMessagesDisplayMgr *)
    createDirectMessageDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
    timelineDisplayMgrFactory:
    (TimelineDisplayMgrFactory *)timelineDisplayMgrFactory
{
    DirectMessageInboxViewController * inboxController =
        [[[DirectMessageInboxViewController alloc]
        initWithNibName:@"DirectMessageInboxView" bundle:nil] autorelease];
    wrapperController.targetViewController = inboxController;

    TwitterService * service =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];

    UserListDisplayMgrFactory * userListDisplayMgrFactory =
        [[[UserListDisplayMgrFactory alloc]
        initWithContext:context findPeopleBookmarkMgr:findPeopleBookmarkMgr
        contactCache:contactCache contactMgr:contactMgr]
        autorelease];

    DirectMessagesDisplayMgr * directMessageDisplayMgr =
        [[[DirectMessagesDisplayMgr alloc]
        initWithWrapperController:wrapperController
        inboxController:inboxController service:service initialCache:nil
        factory:timelineDisplayMgrFactory
        managedObjectContext:context
        composeTweetDisplayMgr:composeTweetDisplayMgr
        findPeopleBookmarkMgr:findPeopleBookmarkMgr
        userListDisplayMgrFactory:userListDisplayMgrFactory
        contactCache:contactCache contactMgr:contactMgr]
        autorelease];
    service.delegate = directMessageDisplayMgr;
    inboxController.delegate = directMessageDisplayMgr;
    wrapperController.delegate = directMessageDisplayMgr;

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:directMessageDisplayMgr
        action:@selector(setCredentials:)];

    return directMessageDisplayMgr;
}

@end
