//
//  Copyright 2009 High Order Bit, Inc. All rights reserved.
//

#import "TimelineDisplayMgrFactory.h"
#import "TwitterService.h"
#import "CredentialsActivatedPublisher.h"
#import "AllTimelineDataSource.h"
#import "UserListDisplayMgrFactory.h"

@implementation TimelineDisplayMgrFactory

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

- (TimelineDisplayMgr *)
    createTimelineDisplayMgrWithWrapperController:
    (NetworkAwareViewController *)wrapperController
    navigationController:(UINavigationController *)navigationController
    title:(NSString *)title
    composeTweetDisplayMgr:(ComposeTweetDisplayMgr *)composeTweetDisplayMgr
{
    TimelineViewController * timelineController =
        [[[TimelineViewController alloc]
        initWithNibName:@"TimelineView" bundle:nil] autorelease];
    wrapperController.targetViewController = timelineController;

    TwitterService * service =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];
    AllTimelineDataSource * dataSource =
        [[[AllTimelineDataSource alloc] initWithTwitterService:service]
        autorelease];
    service.delegate = dataSource;

    TwitterService * timelineService =
        [[[TwitterService alloc] initWithTwitterCredentials:nil
        context:context]
        autorelease];

    UserListDisplayMgrFactory * userListDisplayMgrFactory =
        [[[UserListDisplayMgrFactory alloc]
        initWithContext:context findPeopleBookmarkMgr:findPeopleBookmarkMgr]
        autorelease];

    TimelineDisplayMgr * timelineDisplayMgr =
        [[[TimelineDisplayMgr alloc]
        initWithWrapperController:wrapperController
        navigationController:navigationController
        timelineController:timelineController timelineSource:dataSource
        service:timelineService title:title factory:self
        managedObjectContext:context
        composeTweetDisplayMgr:composeTweetDisplayMgr
        findPeopleBookmarkMgr:findPeopleBookmarkMgr
        userListDisplayMgrFactory:userListDisplayMgrFactory]
        autorelease];
    dataSource.delegate = timelineDisplayMgr;
    timelineController.delegate = timelineDisplayMgr;
    wrapperController.delegate = timelineDisplayMgr;
    timelineService.delegate = timelineDisplayMgr;

    // Don't autorelease
    [[CredentialsActivatedPublisher alloc]
        initWithListener:timelineDisplayMgr action:@selector(setCredentials:)];

    return timelineDisplayMgr;
}
    
@end
