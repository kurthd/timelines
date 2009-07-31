//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "DirectMessageDisplayMgrFactory.h"
#import "DirectMessageInboxViewController.h"
#import "TwitterService.h"
#import "MessagesTimelineDataSource.h"
#import "CredentialsActivatedPublisher.h"

@implementation DirectMessageDisplayMgrFactory

- (void)dealloc
{
    [context release];
    [super dealloc];
}

- (id)initWithContext:(NSManagedObjectContext *)someContext
{
    if (self = [super init])
        context = [someContext retain];

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

    DirectMessagesDisplayMgr * directMessageDisplayMgr =
        [[[DirectMessagesDisplayMgr alloc]
        initWithWrapperController:wrapperController
        inboxController:inboxController service:service initialCache:nil
        factory:timelineDisplayMgrFactory
        managedObjectContext:context
        composeTweetDisplayMgr:composeTweetDisplayMgr]
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
